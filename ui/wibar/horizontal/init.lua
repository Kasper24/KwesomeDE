-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
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

awful.screen.connect_for_each_screen(function(screen)
    local widget_at_center = ui_daemon:get_widget_at_center()
    local y_pos = ui_daemon:get_horizontal_bar_position() == "top" and 0 or screen.geometry.height - dpi(65)

    -- Using popup instead of the wibar widget because it has some edge case bugs with detecting mouse input correctly
    screen.horizontal_wibar = widgets.popup {
        ontop = false,
        screen = screen,
        maximum_height = dpi(65),
        minimum_width = screen.geometry.width,
        maximum_width = screen.geometry.width,
        y = y_pos,
        bg = beautiful.colors.background,
        widget = {
            layout = wibox.layout.align.horizontal,
            expand = "outside",
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(15),
                start(),
                ui_daemon:get_bars_layout() == "horizontal" and taglist(screen) or nil,
                widget_at_center == "clock" and tasklist(screen) or nil
            },
            widget_at_center == "tasklist" and tasklist(screen) or time(),
            {
                widget = wibox.container.place,
                halign = "right",
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = dpi(5),
                    tray(),
                    {
                        widget = wibox.container.margin,
                    },
                    widget_at_center == "tasklist" and time() or nil
                }
            }
        }
    }
    screen.horizontal_wibar:struts{
        top = ui_daemon:get_horizontal_bar_position() == "top" and dpi(65) or 0,
        bottom = ui_daemon:get_horizontal_bar_position() == "bottom" and dpi(65) or 0
    }

    capi.screen.connect_signal("request::wallpaper", function()
        screen.horizontal_wibar.minimum_width = screen.geometry.width
        screen.horizontal_wibar.maximum_width = screen.geometry.width
    end)
end)
