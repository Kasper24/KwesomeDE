-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local beautiful = require("beautiful")
local naughty = require("naughty")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local upower_daemon = require("daemons.hardware.upower")
local dpi = beautiful.xresources.apply_dpi

local function battery_icon(device)
    return wibox.widget.draw_to_image_surface(wibox.widget {
        widget = widgets.background,
        forced_width = dpi(40),
        forced_height = dpi(40),
        widgets.battery_icon(device, {
            forced_height = dpi(10)
        }),
    }, dpi(40), dpi(40))
end

local function notification(title, device)
    naughty.notification {
        app_font_icon = beautiful.icons.car_battery,
        app_icon = "battery",
        app_name = "UPower",
        icon = battery_icon(device),
        title = title,
        text = "Battery is at " .. device.Percentage .. "% " .. device:get_time_string()
    }
end

upower_daemon:connect_signal("battery::update", function(self, device, data)
    if data.State then
        if data.State == upower_daemon.UPower_States.Charging then
            local text = "Battery is at " .. device.Percentage .. "%"
            -- Only show the time string if TimeToFull was updated in this signal
            -- sometimes ther's a bug that data will have TimeToFull
            -- but show the same value as TimeToEmpty
            if data.TimeToFull and data.TimeToFull ~= 0 and data.TimeToFull ~= device.TimeToEmpty then
                text = text .. ". " .. device:get_time_string()
            end
            naughty.notification {
                app_font_icon = beautiful.icons.car_battery,
                app_icon = "battery",
                app_name = "UPower",
                icon = battery_icon(device),
                title = "Battery is charging",
                text = text
            }
        elseif data.State == upower_daemon.UPower_States.Discharging then
            local text = "Battery is at " .. device.Percentage .. "%"
            -- Only show the time string if TimeToEmpty was updated in this signal
            -- sometimes ther's a bug that data will have TimeToEmpty
            --but show the same value as TimeToFull
            if data.TimeToEmpty and data.TimeToEmpty ~= 0 and data.TimeToEmpty ~= device.TimeToFull then
                text = text .. ". " .. device:get_time_string()
            end
            naughty.notification {
                app_font_icon = beautiful.icons.car_battery,
                app_icon = "battery",
                app_name = "UPower",
                icon = battery_icon(device),
                title = "Battery is discharging",
                text = "Battery is at " .. device.Percentage .. "%"
            }
        elseif data.State == upower_daemon.UPower_States.Empty then
            naughty.notification {
                app_font_icon = beautiful.icons.car_battery,
                app_icon = "battery",
                app_name = "UPower",
                icon = battery_icon(device),
                title = "Battery is empty",
                text = "Please recharge now"
            }
        elseif data.State == upower_daemon.UPower_States.Fully_charged then
            naughty.notification {
                app_font_icon = beautiful.icons.car_battery,
                app_icon = "battery",
                app_name = "UPower",
                icon = battery_icon(device),
                title = "Battery is fully charged",
                text = "Please disconnect the charger now"
            }
        end
    elseif device.State == upower_daemon.UPower_States.Discharging and data.Percentage then
        if data.Percentage == 5 then
            notification("Living on the edge", device)
        elseif data.Percentage == 10 then
            notification("Low! Low!", device)
        elseif data.Percentage == 25 then
            notification("I still got a little left on me", device)
        elseif data.Percentage == 50 then
            notification("It's getting low!", device)
        elseif data.Percentage == 75 then
            notification("I'm fine.", device)
        end
    end
end)
