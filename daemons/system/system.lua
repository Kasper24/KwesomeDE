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

local UPDATE_INTERVAL = 600
local VERSION = 0

function system:set_need_setup_off()
    return helpers.settings:set_value("need-setup", false)
end

function system:does_need_setup()
    return helpers.settings:get_value("need-setup", VERSION)
end

function system:is_new_version()
    local version = tonumber(helpers.settings:get_value("version", VERSION))
    if version ~= VERSION then
        helpers.settings:set_value("version", VERSION)
        return true
    end

    return false
end

function system:set_password(password)
    self._private.password = password
    helpers.settings:set_value("password", self._private.password)
end

function system:get_password()
    return self._private.password
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

local function new()
    local ret = gobject {}
    gtable.crush(ret, system, true)

    ret._private = {}
    ret._private.password = helpers.settings:get_value("password")

    gtimer.poller {
        timeout = UPDATE_INTERVAL,
        callback = function()
            awful.spawn.easy_async("neofetch packages", function(packages_count)
                packages_count = helpers.string.trim(packages_count:gsub("packages", ""))

                awful.spawn.easy_async("neofetch uptime", function(uptime)
                    uptime = helpers.string.trim(uptime:gsub("time", ""):gsub("up  ", ""))
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
