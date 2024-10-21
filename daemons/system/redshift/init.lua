-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local library = require("library")

local redshift = {}
local instance = nil

function redshift:turn_on()
    awful.spawn("redshift -x", false)
    awful.spawn("redshift -O 4500", false)
    self._private.state = true
    library.settings["redshift.enabled"] = true
    self:emit_signal("state", true)
end

function redshift:turn_off()
    awful.spawn("redshift -x", false)
    self._private.state = false
    library.settings["redshift.enabled"]= false
    self:emit_signal("state", false)
end

function redshift:toggle()
    if self._private.state == true then
        self:turn_off()
    else
        self:turn_on()
    end
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, redshift, true)

    ret._private = {}
    ret._private.state = nil

    gtimer.delayed_call(function()
        if library.settings["redshift.enabled"] == true then
            ret:turn_on()
        elseif library.settings["redshift.enabled"] == false then
            ret:turn_off()
        end
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance
