-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("ui.widgets")
local ui_daemon = require("daemons.system.ui")
local dpi = beautiful.xresources.apply_dpi

local taglist = require("ui.wibar.taglist")

awful.screen.connect_for_each_screen(function(screen)
    local vertical_bar_position = ui_daemon:get_vertical_bar_position()

    local widget = vertical_bar_position == "top" and wibox.widget {
        widget = wibox.container.margin,
        forced_width = dpi(65),
        taglist(screen, "vertical")
    } or wibox.widget {
        layout = wibox.layout.align.vertical,
        nil,
        nil,
        {
            widget = wibox.container.margin,
            forced_width = dpi(65),
            taglist(screen, "vertical")
        }
    }

    screen.left_wibar = widgets.popup {
        ontop = true,
        screen = screen,
        y = vertical_bar_position == "top" and dpi(65) or 0,
        maximum_width = dpi(65),
        minimum_height = vertical_bar_position == "top" and screen.geometry.height or screen.geometry.height - dpi(65),
        maximum_height = vertical_bar_position == "top" and screen.geometry.height or screen.geometry.height - dpi(65),
        bg = beautiful.colors.background,
        widget = widget
    }
    screen.left_wibar:struts{
        left = dpi(65)
    }
end)
