-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

local path = ...
local start = require(path .. ".start")
local tasklist = require(path .. ".tasklist")
local tray = require(path .. ".tray")
local time = require(path .. ".time")
local notification = require(path .. ".notification")

awful.screen.connect_for_each_screen(function(s)
    -- Using popup instead of the wibar widget because it has some edge case bugs with detecting mouse input correctly
    s.top_wibar = widgets.popup {
        ontop = true,
        screen = s,
        maximum_height = dpi(65),
        minimum_width = s.geometry.width,
        maximum_width = s.geometry.width,
        bg = beautiful.colors.background,
        widget = {
            layout = wibox.layout.align.horizontal,
            expand = "outside",
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(15),
                start(),
                tasklist(s)
            },
            time(),
            {
                widget = wibox.container.place,
                halign = "right",
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = dpi(20),
                    tray(),
                    notification(),
                }
            }
        }
    }
    s.top_wibar:struts{
        top = dpi(65)
    }
end)
