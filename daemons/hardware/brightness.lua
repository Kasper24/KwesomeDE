-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local helpers = require("helpers")
local tonumber = tonumber

local brightness = {}
local instance = nil

function brightness:increase_brightness(step)
    awful.spawn("brightnessctl s +" .. step .. "%", false)
end

function brightness:decrease_brightness(step)
    awful.spawn("brightnessctl s " .. step .. "%-", false)
end

function brightness:set_brightness(brightness)
    awful.spawn("brightnessctl s " .. brightness .. "%", false)
end

local function get_brightness(self)
    awful.spawn.easy_async("brightnessctl info", function(stdout)
        local brightness = stdout:match("%((%d+)%%%)")
        if brightness ~= self._private.brightness then
            self._private.brightness = brightness
            self:emit_signal("update", self._private.brightness)
        end
    end)
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, brightness, true)

    ret._private = {}
    ret._private.brightness = nil

    get_brightness(ret)

    gtimer.poller {
        timeout = 5,
        callback = function()
            get_brightness(ret)
        end
    }

    return ret
end

if not instance then
    instance = new()
end
return instance
