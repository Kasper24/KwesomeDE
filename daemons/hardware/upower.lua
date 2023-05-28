-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local gdebug = require("gears.debug")
local dbus_proxy = require("external.dbus_proxy")
local string = string

local upower = {}
local device = {}
local instance = nil

upower.UPower_States = {
    Unknown = 0,
    Charging = 1,
    Discharging = 2,
    Empty = 3,
    Fully_charged = 4,
    Pending_charge = 5,
    Pending_discharge = 6
}

local function seconds_to_hms(seconds)
	if seconds <= 0 then
		return "00:00:00";
	else
		local hours = string.format("%02.f", math.floor(seconds/3600));
		local mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
		local secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
		return hours..":"..mins..":"..secs
	end
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, upower, true)

    ret._private = {}

    ret._private.display_device_proxy = dbus_proxy.Proxy:new{
        bus = dbus_proxy.Bus.SYSTEM,
        name = "org.freedesktop.UPower",
        interface = "org.freedesktop.UPower.Device",
        path = "/org/freedesktop/UPower/devices/DisplayDevice"
    }
    if ret._private.display_device_proxy then
        ret._private.display_device_proxy_properties = dbus_proxy.Proxy:new{
            bus = dbus_proxy.Bus.SYSTEM,
            name = "org.freedesktop.UPower",
            interface = "org.freedesktop.DBus.Properties",
            path = "/org/freedesktop/UPower/devices/DisplayDevice"
        }
        gtable.crush(ret._private.display_device_proxy, device, true)

        ret._private.display_device_proxy_properties:connect_signal("PropertiesChanged", function(self, interface, data)
            ret:emit_signal("battery::update", ret._private.display_device_proxy, data)
        end)

        gtimer.delayed_call(function()
            ret:emit_signal("battery::init", ret._private.display_device_proxy)
        end)
    else
        gdebug.print_warning(
            "Can't find UPower display device. "..
            "Seems like UPower is not installed or your PC has no battery. "
        )
    end

    return ret
end

function device:get_time_string()
    if self.State == upower.UPower_States.Charging then
        return seconds_to_hms(self.TimeToFull)
    end

    return seconds_to_hms(self.TimeToEmpty)
end

if not instance then
    instance = new()
end
return instance
