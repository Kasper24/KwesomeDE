-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local inotify = require("services.inotify")
local tonumber = tonumber

local brightness = { }
local instance = nil

function brightness:increase_brightness(step)
    awful.spawn("brightnessctl s +" .. step .. "%", false)
end

function brightness:decrease_brightness(step)
    awful.spawn("brightnessctl s " .. step .. "%-", false)
end

local function get_brightness(self)
    awful.spawn.with_line_callback("brightnessctl g", {stdout = function(value)
        awful.spawn.with_line_callback("brightnessctl m", {stdout = function(max)
            local percentage = tonumber(value) / tonumber(max) * 100
            self:emit_signal("update", percentage)
        end})
    end})
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, brightness, true)

    get_brightness(ret)

    local watcher = inotify:watch("/sys/class/backlight/?**/brightness",
    {
        inotify.Events.modify
    })

    watcher:connect_signal("event", function(_, __, __)
        get_brightness(ret)
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance