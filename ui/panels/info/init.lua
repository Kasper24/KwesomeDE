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
    local left = wibox.widget {
        layout = wibox.layout.ratio.vertical,
        spacing = dpi(15),
        calender,
        vertical_separator(),
        notifications
    }
    left:adjust_ratio(2, 0.4, 0.003, 0.6)

    local right = wibox.widget {
        layout = wibox.layout.ratio.vertical,
        spacing = dpi(15),
        weather,
        vertical_separator(),
        web_notifications
    }
    right:adjust_ratio(2, 0.4, 0.003, 0.6)

    local left_right = wibox.widget {
        widget = wibox.container.margin,
        margins = { right = dpi(25) },
        {
            layout = wibox.layout.ratio.horizontal,
            spacing = dpi(15),
            left,
            horizontal_separator(),
            right
        }
    }
    left_right.children[1]:adjust_ratio(2, 0.45, 0.003, 0.55)

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
        widget = wibox.widget {
            widget = wibox.container.margin,
            margins = dpi(25),
            left_right
        }
    }

    return INFO_PANEL
end

if not instance then
    instance = new()
end
return instance
