-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local capi = {
    screen = screen
}


local path = ...
local taglist = require(path .. ".taglist")

capi.screen.connect_signal("request::desktop_decoration", function(s)
    s.left_wibar = awful.popup {
        screen = s,
        type = "dock",
        y = dpi(65),
        maximum_width = dpi(65),
        minimum_height = s.geometry.height,
        maximum_height = s.geometry.height,
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
