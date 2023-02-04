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
local capi = {
    awesome = awesome
}

local system = {}
local instance = nil

local UPDATE_INTERVAL = 60

local LUA_PAM_PATH = helpers.filesystem.get_awesome_config_dir("external/liblua_pam") .. "?.so;"
package.cpath = package.cpath .. ';' .. LUA_PAM_PATH

function system:set_password(password)
    self._private.password = password
    helpers.settings:set_value("password", self._private.password)
end

function system:get_password()
    return self._private.password
end

function system:get_is_pam_installed()
    return self._private.is_pam_installed
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
    if self._private.is_pam_installed == true then
        local pam = require(LUA_PAM_PATH)
        local result
        pam.auth_current_user(password)
        if result == true then
            notification_daemon:unblock_on_unlocked()
            self:emit_signal("unlock")
        else
            self:emit_signal("wrong_password")
        end
    else
        if self._private.password == nil then
            notification_daemon:unblock_on_unlocked()
            self:emit_signal("unlock")
        else
            local result = password == self._private.password
            if result == true then
                notification_daemon:unblock_on_unlocked()
                self:emit_signal("unlock")
            else
                self:emit_signal("wrong_password")
            end
        end
    end
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, system, true)

    ret._private = {}
    ret._private.password = helpers.settings:get_value("password")

    if package.loaded["liblua_pam"] then
        ret._private.is_pam_installed = true
    else
        ret._private.is_pam_installed = false
    end

    gtimer {
        timeout = UPDATE_INTERVAL,
        autostart = true,
        call_now = true,
        callback = function()
            awful.spawn.easy_async("neofetch packages", function(packages_count)
                packages_count = helpers.string.trim(packages_count:gsub("packages", ""))

                awful.spawn.easy_async("neofetch uptime", function(uptime)
                    uptime = uptime:gsub("time", "")
                    ret:emit_signal("update", packages_count, uptime)
                end)
            end)
        end
    }

    return ret
end

if not instance then
    instance = new()
end
return instance
