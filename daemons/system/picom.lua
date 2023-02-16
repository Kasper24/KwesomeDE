-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local helpers = require("helpers")
local table = table
local capi = {
    awesome = awesome
}

local picom = {}
local instance = nil

local CONFIG_PATH = helpers.filesystem.get_awesome_config_dir("config") .. "picom.conf"

local properties = {"active-opacity", "inactive-opacity", "fade-delta", "fade-in-step", "fade-out-step",
                    "corner-radius", "blur-strength", "shadow-radius", "shadow-opacity", "shadow-offset-x",
                    "shadow-offset-y", "animation-stiffness", "animation-dampening", "animation-window-mass"}

local bool_properties = {"shadow", "fading", "animation-clamping", "animations"}

function picom:turn_on(save)
    if DEBUG == true then
        return
    end

    local cmd = "picom "

    awful.spawn.easy_async("picom --help", function(stdout)
        if stdout:find("--experimental-backends", 1, true) then
            cmd = cmd .. "--experimental-backends "
        end
        if stdout:find("--animations", 1, true) == nil then
            helpers.table.remove_value(properties, "animation-stiffness")
            helpers.table.remove_value(properties, "animation-dampening")
            helpers.table.remove_value(properties, "animation-window-mass")
            helpers.table.remove_value("animations")
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

        awful.spawn.easy_async(cmd, function()
            self._private.refreshing = false
        end)
    end)

    if save == true then
        helpers.settings:set_value("picom", true)
    end
end

function picom:turn_off(save)
    if DEBUG == true then
        return
    end

    awful.spawn("pkill -f picom", false)
    if save == true then
        helpers.settings:set_value("picom", false)
    end
end

function picom:toggle(save)
    if capi.awesome.composite_manager_running == true then
        self:turn_off(save, true)
    else
        self:turn_on(save, true)
    end
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
                    helpers.settings:set_value("picom-" .. prop, value)
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
        ret._private[prop] = helpers.settings:get_value("picom-" .. prop)
    end
    for _, prop in ipairs(bool_properties) do
        ret._private[prop] = helpers.settings:get_value("picom-" .. prop)
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

    gtimer.delayed_call(function()
        if helpers.settings:get_value("picom") == true then
            ret:turn_on()
        elseif helpers.settings:get_value("picom") == false then
            ret:turn_off()
        end

        gtimer.poller {
            timeout =  2,
            callback = function()
                if ret._private.state ~= capi.awesome.composite_manager_running and not ret._private.refreshing then
                    ret:emit_signal("state", capi.awesome.composite_manager_running)
                    ret._private.state = capi.awesome.composite_manager_running
                end
            end
        }

        awful.spawn.easy_async("picom --help", function(stdout)
            if stdout:find("--animations", 1, true) ~= nil then
                ret:emit_signal("animations::support")
            end
        end)
    end)

    return ret
end

build_properties(picom, properties)
build_properties(picom, bool_properties)

if not instance then
    instance = new()
end
return instance
