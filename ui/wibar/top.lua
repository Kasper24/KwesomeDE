-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local ui_daemon = require("daemons.system.ui")
local dpi = beautiful.xresources.apply_dpi

local start = require("ui.wibar.start")
local taglist = require("ui.wibar.taglist")
local tasklist = require("ui.wibar.tasklist")
local tray = require("ui.wibar.tray")
local time = require("ui.wibar.time")

awful.screen.connect_for_each_screen(function(screen)
    local _taglist = nil
    if ui_daemon:get_double_bars() == false then
        _taglist = taglist(screen, "horizontal")
    end

    local center_tasklist = ui_daemon:get_center_tasklist()

    -- Using popup instead of the wibar widget because it has some edge case bugs with detecting mouse input correctly
    screen.top_wibar = widgets.popup {
        ontop = true,
        screen = screen,
        maximum_height = dpi(65),
        minimum_width = screen.geometry.width,
        maximum_width = screen.geometry.width,
        bg = beautiful.colors.background,
        widget = {
            layout = wibox.layout.align.horizontal,
            expand = "outside",
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(15),
                start(),
                _taglist,
                not center_tasklist and tasklist(screen) or nil
            },
            center_tasklist and tasklist(screen) or time(),
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
                    center_tasklist and time() or nil
                }
            }
        }
    }
    screen.top_wibar:struts{
        top = dpi(65)
    }
end)
