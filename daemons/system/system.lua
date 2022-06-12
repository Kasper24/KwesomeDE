-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local notification_daemon = require("daemons.system.notifications")
local settings = require("services.settings")
local helpers = require("helpers")
local ipairs = ipairs
local type = type
local capi = { awesome = awesome }

local system = { }
local instance = nil

local UPTIME_UPDATE_INTERVAL = 60

local LUA_PAM_PATH = helpers.filesystem.get_awesome_config_dir("services") .. "?.so"
package.cpath = package.cpath .. ';' .. LUA_PAM_PATH

function system:set_password(password)
    self._private.password = password
    settings:set_value("system.password", self._private.password)
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
        local result pam.auth_current_user(password)
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
    local ret = gobject{}
    gtable.crush(ret, system, true)

    ret._private = {}
    ret._private.password = settings:get_value("system.password")

    if package.loaded["liblua_pam"] then
        ret._private.is_pam_installed = true
    else
        for _, searcher in ipairs(package.searchers or package.loaders) do
            local loader = searcher("liblua_pam")
            if type(loader) == 'function' then
                package.preload["liblua_pam"] = loader
                ret._private.is_pam_installed = true
            end
        end
        ret._private.is_pam_installed = false
    end

    -- awful.spawn.easy_async_with_shell("stat "..LUA_PAM_PATH.." >/dev/null 2>&1", function (_, __, ___, exitcode)
    --     if exitcode == 0 then
    --         local pam = require("liblua_pam")
    --         ret._private.is_pam_installed = true
    --     else
    --         ret._private.is_pam_installed = false
    --     end
    -- end)

    gtimer { timeout = UPTIME_UPDATE_INTERVAL, autostart = true, call_now = true, callback = function()
        awful.spawn.easy_async("uptime -p", function(stdout)
            stdout = stdout:gsub('^%s*(.-)%s*$', '%1')
            ret:emit_signal("uptime", stdout)
        end)
    end}

    return ret
end

if not instance then
    instance = new()
end
return instance