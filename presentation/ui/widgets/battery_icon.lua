-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local twidget = require("presentation.ui.widgets.text")
local beautiful = require("beautiful")
local upower_daemon = require("daemons.hardware.upower")
local setmetatable = setmetatable

local battery_icon = { mt = {} }

local UPower_States =
{
    Unknown = 0,
    Charging = 1,
    Discharging = 2,
    Empty = 3,
    Fully_charged = 4,
    Pending_charge = 5,
    Pending_discharge = 6,
}

local Battery_States =
{
    Low = 0,
    Medium = 1,
    High = 2,
    Full = 3,
    Charging = 4
}

local battery_state = nil

local function new()
    local widget = twidget
    {
        halign = "center",
        size = 17,
        color = beautiful.random_accent_color(),
        font = beautiful.battery_full_icon.font,
        text = beautiful.battery_full_icon.icon,
    }

    upower_daemon:connect_signal("battery::update", function(self, device)
        if device.state == UPower_States.Discharging then
            if device.percentage < 25 and battery_state ~= Battery_States.Low then
                widget:set_text(beautiful.battery_quarter_icon)
                battery_state = Battery_States.Low
            end

            if device.percentage > 50 and battery_state ~= Battery_States.Medium then
                widget:set_text(beautiful.battery_half_icon)
                battery_state = Battery_States.Medium
            end

            if device.percentage > 75 and battery_state ~= Battery_States.High then
                widget:set_text(beautiful.battery_three_quarter_icon)
                battery_state = Battery_States.High
            end
        elseif device.state == UPower_States.Fully_charged and device.percentage > 90 and battery_state ~= Battery_States.Full then
            widget:set_text(beautiful.battery_full_icon)
            battery_state = Battery_States.Full
        elseif device.state == UPower_States.Charging and battery_state ~= Battery_States.Charging then
            widget:set_text(beautiful.battery_bolt_icon)
            battery_state = Battery_States.Charging
        end
    end)

	return widget
end

function battery_icon.mt:__call(...)
    return new(...)
end

return setmetatable(battery_icon, battery_icon.mt)