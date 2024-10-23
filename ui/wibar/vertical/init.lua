-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("ui.widgets")
local ui_daemon = require("daemons.system.ui")
local dpi = beautiful.xresources.apply_dpi

local capi = {
    screen = screen
}

local start = require("ui.wibar.widgets.start")
local taglist = require("ui.wibar.widgets.taglist")
local tasklist = require("ui.wibar.widgets.tasklist")
local tray = require("ui.wibar.widgets.tray")
local time = require("ui.wibar.widgets.time")

local function calc_height(screen, bars_layout)
    return (bars_layout == "vertical_horizontal") and
    screen.geometry.height - dpi(65) or screen.geometry.height
end

awful.screen.connect_for_each_screen(function(screen)
    local horizontal_bar_position = ui_daemon:get_horizontal_bar_position()
    local bars_layout = ui_daemon:get_bars_layout()
    local widget_at_center = ui_daemon:get_widget_at_center()
    local place_taglist_at_bottom = (horizontal_bar_position == "bottom" and bars_layout == "vertical_horizontal")

    local widget = place_taglist_at_bottom and wibox.widget {
        layout = wibox.layout.align.vertical,
        nil,
        nil,
        {
            widget = wibox.container.margin,
            forced_width = dpi(65),
            margins = { bottom = dpi(15) },
            taglist(screen)
        }
    } or bars_layout == "vertical" and
        wibox.widget {
            layout = wibox.layout.align.vertical,
            expand = "outside",
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(0),
                start(),
                taglist(screen),
                widget_at_center == "clock" and tasklist(screen) or nil
            },
            widget_at_center == "clock" and time() or tasklist(screen),
            {
                widget = wibox.container.place,
                valign = "bottom",
                {
                    layout = wibox.layout.fixed.vertical,
                    spacing = dpi(5),
                    tray(),
                    {
                        widget = wibox.container.margin,
                    },
                    widget_at_center == "tasklist" and time() or nil
                }
            }
        } or
        wibox.widget {
            widget = wibox.container.margin,
            forced_width = dpi(65),
            taglist(screen)
        }

    screen.vertical_wibar = widgets.popup {
        ontop = false,
        screen = screen,
        y = (horizontal_bar_position == "top" and bars_layout == "vertical_horizontal") and dpi(65) or 0,
        maximum_width = dpi(65),
        minimum_height = calc_height(screen, bars_layout),
        maximum_height = calc_height(screen, bars_layout),
        bg = beautiful.colors.background,
        widget = widget
    }
    screen.vertical_wibar:struts{
        left = dpi(65)
    }

    capi.screen.connect_signal("request::wallpaper", function()
        screen.vertical_wibar.minimum_height = calc_height(screen, bars_layout)
        screen.vertical_wibar.maximum_height = calc_height(screen, bars_layout)
    end)
end)
