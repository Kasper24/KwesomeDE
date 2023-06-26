-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("ui.widgets")
local dpi = beautiful.xresources.apply_dpi

local taglist = require("ui.wibar.taglist")

awful.screen.connect_for_each_screen(function(screen)
    screen.left_wibar = widgets.popup {
        ontop = true,
        screen = screen,
        y = dpi(65),
        maximum_width = dpi(65),
        minimum_height = screen.geometry.height,
        maximum_height = screen.geometry.height,
        bg = beautiful.colors.background,
        widget = {
            widget = wibox.container.margin,
            forced_width = dpi(65),
            taglist(screen, "vertical")
        }
    }
    screen.left_wibar:struts{
        left = dpi(65)
    }
end)
