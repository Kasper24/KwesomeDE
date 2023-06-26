-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("ui.widgets")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi

local instance = nil

local path = ...
local calender = require(path .. ".calendar")
local weather = require(path .. ".weather")
local notifications = require(path .. ".notifications")
local web_notifications = require(path .. ".web_notifications")

local function horizontal_separator()
    return wibox.widget {
        widget = widgets.background,
        forced_width = dpi(1),
        shape = helpers.ui.rrect(),
        bg = beautiful.colors.surface
    }
end

local function vertical_separator()
    return wibox.widget {
        widget = widgets.background,
        forced_height = dpi(1),
        shape = helpers.ui.rrect(),
        bg = beautiful.colors.surface
    }
end

local function new()
    local widget = wibox.widget {
        widget = wibox.container.margin,
        margins = dpi(25),
        {
            layout = wibox.layout.overflow.vertical,
            spacing = dpi(25),
            scrollbar_widget = widgets.scrollbar,
            scrollbar_width = dpi(0),
            scrollbar_spacing = 0,
            step = 300,
            {
                layout = wibox.layout.fixed.horizontal,
                forced_height = dpi(1500),
                spacing = dpi(15),
                {
                    layout = wibox.layout.fixed.vertical,
                    spacing = dpi(15),
                    {
                        widget = wibox.container.margin,
                        forced_width = dpi(400),
                        forced_height = dpi(500),
                        calender
                    },
                    vertical_separator(),
                    {
                        widget = wibox.container.margin,
                        forced_width = dpi(400),
                        notifications
                    },
                },
                horizontal_separator(),
                {
                    layout = wibox.layout.fixed.vertical,
                    spacing = dpi(15),
                    {
                        widget = wibox.container.margin,
                        forced_height = dpi(500),
                        weather
                    },
                    vertical_separator(),
                    {
                        widget = wibox.container.margin,
                        web_notifications
                    },
                }
            }
        }
    }

    INFO_PANEL = widgets.animated_panel {
        visible = false,
        ontop = true,
        minimum_width = dpi(1000),
        maximum_width = dpi(1000),
        max_height = true,
        axis = "y",
        start_pos = -500,
        placement = function(widget)
            awful.placement.top(widget, {
                honor_workarea = true,
                honor_padding = true,
                attach = true
            })
        end,
        shape = helpers.ui.rrect(),
        bg = beautiful.colors.background,
        widget = widget
    }

    return INFO_PANEL
end

if not instance then
    instance = new()
end
return instance
