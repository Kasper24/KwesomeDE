-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local bluetooth_daemon = require("daemons.hardware.bluetooth")
local network_daemon = require("daemons.hardware.network")
local library = require("library")

local radio = {}
local instance = nil

function radio:toggle()
    if self._private.enabled == false or self._private.enabled == nil then
        self:turn_on()
    else
        self:turn_off()
    end
end

function radio:turn_on()
    awful.spawn("rfkill block all", false)

    self._private.enabled = true
    library.settings["airplane.enabled"] =  true
    self:emit_signal("state", true)
end

function radio:turn_off()
    awful.spawn("rfkill unblock all", false)

    self._private.enabled = false
    library.settings["airplane.enabled"] =  false
    self:emit_signal("state", false)
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, radio, true)

    ret._private = {}

    gtimer.delayed_call(function()
        local enabled = library.settings["airplane.enabled"]
        if enabled == true then
            ret:turn_on()
        elseif enabled == false then
            ret:turn_off()
        end
    end)

    network_daemon:connect_signal("wireless_state", function(self, state)
        if state == true and ret._private.enabled == true then
            ret:turn_off()
        end
    end)

    bluetooth_daemon:connect_signal("state", function(self, state)
        if state == true and ret._private.enabled == true then
            ret:turn_off()
        end
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance
