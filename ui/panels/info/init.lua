-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gshape = require("gears.shape")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("ui.widgets")
local dpi = beautiful.xresources.apply_dpi

local instance = nil

local path = ...
local calender = require(path .. ".calendar")
local weather = require(path .. ".weather")

local function widget()
    return wibox.widget {
        widget = wibox.container.margin,
        margins = dpi(25),
        {
            layout = wibox.layout.flex.horizontal,
            spacing = dpi(15),
            calender,
            weather
        }
    }
end

local function new()
    return widgets.animated_popup {
        type = "dock",
        visible = false,
        ontop = true,
        axis = "y",
        start_pos = -500,
        minimum_width = dpi(800),
        maximum_width = dpi(800),
        minimum_height = dpi(600),
        maximum_height = dpi(600),
        placement = function(widget)
            awful.placement.top(widget, {
                honor_workarea = true,
                honor_padding = true,
                attach = true
            })
        end,
        shape = function(cr, width, height)
            gshape.infobubble(cr, width, dpi(600), nil, nil, dpi(360))
        end,
        bg = beautiful.colors.background,
        widget = wibox.widget {
            widget = wibox.container.margin,
            margins = dpi(25),
            {
                layout = wibox.layout.flex.horizontal,
                spacing = dpi(15),
                calender,
                weather
            }
        }
    }
end

if not instance then
    instance = new()
end
return instance
