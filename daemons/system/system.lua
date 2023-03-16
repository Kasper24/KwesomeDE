-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local notification_daemon = require("daemons.system.notifications")
local helpers = require("helpers")
local filesystem = require("external.filesystem")
local capi = {
    awesome = awesome
}

local PATH = filesystem.filesystem.get_awesome_config_dir("external/pam")
package.cpath = package.cpath .. ";" .. PATH  .. "?.so;"
local pam = require('liblua_pam')

local system = {}
local instance = nil

local VERSION = 0

function system:set_need_setup_off()
    helpers.settings["need-setup"] = false
end

function system:does_need_setup()
    return helpers.settings["need-setup"]
end

function system:is_new_version()
    local version = helpers.settings["version"]
    if version < VERSION then
        helpers.settings["version"] = VERSION
        return true
    end

    return false
end

function system:shutdown()
    awful.spawn("systemctl poweroff", false)
end

function system:reboot()
    awful.spawn("systemctl reboot", false)
end

function system:suspend()
    self:lock()
    awful.spawn("systemctl suspend", false)
end

function system:exit()
    capi.awesome.quit()
end

function system:lock()
    notification_daemon:block_on_locked()
    self:emit_signal("lock")
end

function system:unlock(password)
    local pam_auth = pam:auth_current_user(password)
    if pam_auth then
        notification_daemon:unblock_on_unlocked()
        self:emit_signal("unlock")
    else
        self:emit_signal("wrong_password")
    end
end

local function system_info(self)
    gtimer.poller {
        timeout = 60,
        callback = function()
            awful.spawn.easy_async("neofetch packages", function(packages_count)
                packages_count = helpers.string.trim(packages_count:gsub("packages", ""))

                awful.spawn.easy_async("neofetch uptime", function(uptime)
                    uptime = helpers.string.trim(uptime:gsub("time", ""):gsub("up  ", ""))
                    self:emit_signal("info", packages_count, uptime)
                end)
            end)
        end
    }
end

local function updates_info(self)
    local function pacman()
        awful.spawn.easy_async("checkupdates", function(stdout)
            local updates_count = 0
            for line in stdout:gmatch("[^\r\n]+") do
                updates_count = updates_count + 1
            end
            self:emit_signal("package_manager::updates_available", "Pacman", updates_count, stdout)
        end)
    end

    gtimer.poller {
        timeout = 60 * 60 * 24,
        callback = function()
            awful.spawn.easy_async("neofetch distro", function(distro)
                distro = helpers.string.trim(distro:gsub("distro ", ""))
                if distro == "Arch Linux" or distro == "EndeavourOS" or distro == "Manjaro Linux" then
                    pacman()
                end
            end)
        end
    }
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, system, true)

    system_info(ret)
    updates_info(ret)

    return ret
end

if not instance then
    instance = new()
end
return instance
