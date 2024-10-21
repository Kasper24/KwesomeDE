-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local ui_daemon = require("daemons.system.ui")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local capi = {
    screen = screen
}

local instance = nil

local path = ...
local header = require("ui.panels.action.widgets.header")
local dashboard = require("ui.panels.action.widgets.dashboard")
local info = require("ui.panels.action.widgets.info")
local media = require("ui.panels.action.widgets.media")

local function seperator()
    return wibox.widget {
        widget = widgets.background,
        forced_height = dpi(1),
        shape = helpers.ui.rrect(),
        bg = beautiful.colors.surface,
    }
end

local function new()
    local function placement(widget)
        if ui_daemon:get_bars_layout() ~= "vertical" then
            awful.placement.top_right(widget, {
                honor_workarea = true,
                honor_padding = true,
                attach = true
            })
        else
            awful.placement.top_left(widget, {
                honor_workarea = true,
                honor_padding = true,
                attach = true
            })
        end
    end

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
            header,
            seperator(),
            dashboard,
            seperator(),
            info,
            seperator(),
            media
        }
    }

    local panel = widgets.animated_popup {
        visible = false,
        ontop = true,
        maximum_width = dpi(550),
        max_height = true,
        animate_method = "width",
        hide_on_clicked_outside = true,
        placement = placement,
        shape = helpers.ui.rrect(),
        bg = beautiful.colors.background,
        widget = widget
    }

    return panel
end

if not instance then
    instance = new()
end
return instance
