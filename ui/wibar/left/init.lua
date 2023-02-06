-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("ui.widgets")
local dpi = beautiful.xresources.apply_dpi
local capi = {
    awesome = awesome,
    screen = screen
}

local path = ...
local taglist = require(path .. ".taglist")

awful.screen.connect_for_each_screen(function(s)
    s.left_wibar = widgets.popup {
        screen = s,
        type = "dock",
        y = dpi(65),
        maximum_width = dpi(65),
        minimum_height = s.geometry.height,
        maximum_height = s.geometry.height,
        bg = beautiful.colors.background,
        widget = {
            widget = wibox.container.margin,
            forced_width = dpi(65),
            taglist(s)
        }
    }
    s.left_wibar:struts{
        left = dpi(65)
    }
end)
