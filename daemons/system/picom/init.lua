-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local helpers = require("helpers")
local filesystem = require("external.filesystem")
local ipairs = ipairs
local string = string
local capi = {
    awesome = awesome
}

local picom = {}
local instance = nil

local CONFIG_PATH = filesystem.filesystem.get_awesome_config_dir("config") .. "picom/picom.conf"

local properties = {"active-opacity", "inactive-opacity", "fade-delta", "fade-in-step", "fade-out-step",
                    "corner-radius", "blur-strength", "shadow-radius", "shadow-opacity", "shadow-offset-x",
                    "shadow-offset-y"}

local bool_properties = {"shadow", "fading"}

function picom:turn_on(save)
    if DEBUG == true then
        return
    end

    local cmd = "picom "

    awful.spawn.easy_async("picom --help", function(stdout)
        if stdout:find("--experimental-backends", 1, true) then
            cmd = cmd .. "--experimental-backends "
        end

        cmd = cmd .. "--config " .. CONFIG_PATH .. " "
        for _, prop in ipairs(properties) do
            cmd = cmd .. string.format("--%s %s ", prop, self._private[prop])
        end
        for _, prop in ipairs(bool_properties) do
            if self._private[prop] == true then
                cmd = cmd .. string.format("--%s ", prop)
            end
        end

        awful.spawn(cmd, false)
        self._private.refreshing = false
    end)

    if save == true then
        helpers.settings["picom.enabled"] = true
    end
end

function picom:turn_off(save)
    if DEBUG == true then
        return
    end

    awful.spawn("pkill -f picom", false)
    if save == true then
        helpers.settings["picom.enabled"] = false
    end
end

function picom:toggle(save)
    if capi.awesome.composite_manager_running == true then
        self:turn_off(save)
    else
        self:turn_on(save)
    end
end

function picom:get_state()
    return capi.awesome.composite_manager_running
end

local function build_properties(prototype, properties)
    for _, prop in ipairs(properties) do
        if not prototype["set_" .. prop] then
            prototype["set_" .. prop] = function(self, value)
                if self._private[prop] ~= value then
                    if capi.awesome.composite_manager_running == true then
                        self:turn_off(false)
                    end

                    self._private[prop] = value
                    local setting_prop = prop:gsub("-", "_")
                    helpers.settings["picom." .. setting_prop] = value
                    self._private.refreshing = true
                    self._private.refresh_timer:again()
                end
                return self
            end
        end
        if not prototype["get_" .. prop] then
            prototype["get_" .. prop] = function(self)
                return self._private[prop]
            end
        end
    end
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, picom, true)

    ret._private = {}
    ret._private.state = -1

    for _, prop in ipairs(properties) do
        local setting_prop = prop:gsub("-", "_")
        ret._private[prop] = helpers.settings["picom." .. setting_prop]
    end
    for _, prop in ipairs(bool_properties) do
        local setting_prop = prop:gsub("-", "_")
        ret._private[prop] = helpers.settings["picom." .. setting_prop]
    end

    ret._private.refresh_timer = gtimer {
        timeout = 1,
        autostart = false,
        calL_now = false,
        single_shot = true,
        callback = function()
            ret:turn_on(false)
        end
    }

    if helpers.settings["picom.enabled"] == true and capi.awesome.composite_manager_running == false then
        ret:turn_on()
    elseif helpers.settings["picom.enabled"] == false then
        ret:turn_off()
    end

    gtimer.delayed_call(function()
        gtimer.poller {
            timeout =  2,
            callback = function()
                if ret._private.state ~= capi.awesome.composite_manager_running and not ret._private.refreshing then
                    ret:emit_signal("state", capi.awesome.composite_manager_running)
                    ret._private.state = capi.awesome.composite_manager_running
                end
            end
        }
    end)

    return ret
end

build_properties(picom, properties)
build_properties(picom, bool_properties)

if not instance then
    instance = new()
end
return instance
