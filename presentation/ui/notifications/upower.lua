-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local beautiful = require("beautiful")
local naughty = require("naughty")
local upower_daemon = require("daemons.hardware.upower")

local UPower_States = {
    Unknown = 0,
    Charging = 1,
    Discharging = 2,
    Empty = 3,
    Fully_charged = 4,
    Pending_charge = 5,
    Pending_discharge = 6
}

local Battery_States = {
    Low = 0,
    Medium = 1,
    High = 2,
    Full = 3,
    Charging = 4
}
local battery_state = -1

local function notification(title, device, device_state)
    if device.state == UPower_States.Discharging then
        if device.percentage < 25 and device_state ~= Battery_States.Low then
            naughty.notification {
                app_font_icon = beautiful.icons.car_battery,
                app_icon = "battery",
                app_name = "UPower",
                font_icon = beautiful.icons.battery.quarter,
                title = title,
                text = "Running low at " .. device.percentage .. "%"
            }
            device_state = Battery_States.Low
        end

        if device.percentage > 50 and device_state ~= Battery_States.Medium then
            naughty.notification {
                app_font_icon = beautiful.icons.car_battery,
                app_icon = "battery",
                app_name = "UPower",
                font_icon = beautiful.icons.battery.half,
                title = title,
                text = "Battery is at " .. device.percentage .. "%"
            }
            device_state = Battery_States.Medium
        end

        if device.percentage > 75 and device_state ~= Battery_States.High then
            naughty.notification {
                app_font_icon = beautiful.icons.car_battery,
                app_icon = "battery",
                app_name = "UPower",
                font_icon = beautiful.icons.battery.three_quarter,
                title = title,
                text = "Battery is at " .. device.percentage .. "%"
            }
            device_state = Battery_States.High
        end
    elseif device.state == UPower_States.Fully_charged and device.percentage > 90 and device_state ~=
        Battery_States.Full then
        naughty.notification {
            app_font_icon = beautiful.icons.car_battery,
            app_icon = "battery",
            app_name = "UPower",
            font_icon = beautiful.icons.battery.full,
            title = title,
            text = "Fully charged!"
        }
        device_state = Battery_States.Full
    elseif device.state == UPower_States.Charging and device_state ~= Battery_States.Charging then
        naughty.notification {
            app_font_icon = beautiful.icons.car_battery,
            app_icon = "battery",
            app_name = "UPower",
            font_icon = beautiful.icons.battery.bolt,
            title = title,
            text = "Charging"
        }
        device_state = Battery_States.Charging
    end
end

upower_daemon:connect_signal("battery::update", function(self, device)
    notification("Battery Status", device, battery_state)
end)

local device_states = {}
upower_daemon:connect_signal("device::update", function(self, device)
    if device_states[device.model] == nil then
        device_states[device.model] = -1
    end
    notification(device.Model, device, device_states[device.model])
end)
