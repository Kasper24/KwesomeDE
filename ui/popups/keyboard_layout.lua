-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gtimer = require("gears.timer")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local keyboard_layout_daemon = require("daemons.system.keyboard_layout")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi

local instance = nil

local function new()
    local icon = wibox.widget {
        widget = widgets.text,
        halign = "center",
        valign = "bottom",
        icon = beautiful.icons.keyboard,
        size = 30
    }

    local text = wibox.widget {
        widget = widgets.text,
        halign = "center",
        valign = "bottom",
        size = 15
    }

    local widget = widgets.animated_popup {
        screen = awful.screen.focused(),
        visible = false,
        ontop = true,
        placement = function(c)
            awful.placement.centered(c, {
                offset = {
                    y = 300
                }
            })
        end,
        minimum_width = dpi(200),
        maximum_width = dpi(200),
        maximum_height = dpi(200),
        shape = helpers.ui.rrect(),
        bg = beautiful.colors.background,
        widget = {
            widget = wibox.container.place,
            halign = "center",
            valign = "center",
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(30),
                icon,
                text
            }
        }
    }

    local hide_timer = gtimer {
        single_shot = true,
        call_now = false,
        autostart = false,
        timeout = 1,
        callback = function()
            widget:hide()
        end
    }

    local show = false
    keyboard_layout_daemon:connect_signal("update", function(self, layout)
        if show == true then
            text:set_text(layout)
            if widget.visible == false then
                widget:show()
            end
            hide_timer:again()
        end
        show = true
    end)

    return widget
end

if not instance then
    instance = new()
end
return instance
