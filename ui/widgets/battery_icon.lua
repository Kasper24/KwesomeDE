-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gshape = require("gears.shape")
local wibox = require("wibox")
local twidget = require("ui.widgets.text")
local pbwidget = require("ui.widgets.progressbar")
local bwidget = require("ui.widgets.background")
local beautiful = require("beautiful")
local upower_daemon = require("daemons.hardware.upower")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local battery_icon = {
    mt = {}
}

local function new(device, args)
    args = args or {}
    args.forced_width = args.forced_width or dpi(35)
    args.forced_height = args.forced_height or nil
    args.margins_vertical = args.margins_vertical or nil
    args.color = args.color or beautiful.icons.bolt.color

    local progress_bar = wibox.widget  {
        widget = pbwidget,
        shape = function(cr, width, height)
            gshape.rounded_rect(cr, width, height, dpi(3))
        end,
        max_value = 100,
        value = device.Percentage,
        bar_shape = helpers.ui.rrect(),
        background_color = beautiful.colors.transparent,
        color = args.color
    }

    local charging_icon = wibox.widget {
        widget = twidget,
        forced_width = args.forced_width,
        forced_height = args.forced_height,
        halign = "center",
        icon = beautiful.icons.bolt,
        color = args.color,
        size = 12
    }

    local widget = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_height = args.forced_height,
        {
            widget = wibox.container.margin,
            margins = { top = args.margins_vertical, bottom = args.margins_vertical },
            {
                widget = bwidget,
                id = "border",
                forced_width = args.forced_width,
                shape = function(cr, width, height)
                    gshape.rounded_rect(cr, width, height, dpi(3))
                end,
                border_width = dpi(4),
                border_color = args.color,
                {
                    widget = wibox.container.margin,
                    margins = dpi(7),
                    progress_bar
                }
            }
        }
    }

    if device.State == upower_daemon.UPower_States.Charging then
        widget:add(charging_icon)
    end

    -- update_icon(device, progress_bar)
    upower_daemon:connect_signal("battery::update", function(self, device, data)
        if data.State then
            if data.State == upower_daemon.UPower_States.Charging then
                widget:add(charging_icon)
            elseif data.State == upower_daemon.UPower_States.Discharging then
                widget:remove_widgets(charging_icon)
            end
        end
        -- update_icon(device, widget)
        progress_bar.value = device.Percentage
    end)

    function widget:set_color(color)
        widget:get_children_by_id("border")[1].border_color = color
        progress_bar.color = color
        charging_icon:set_color(color)
    end

    return widget
end

function battery_icon.mt:__call(...)
    return new(...)
end

return setmetatable(battery_icon, battery_icon.mt)
