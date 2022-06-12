-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gtimer = require("gears.timer")
local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local beautiful = require("beautiful")
local keyboard_layout_daemon = require("daemons.system.keyboard_layout")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi

local instance = nil

local function new()
    local ret = {}

    local icon = widgets.text
    {
        halign = "center",
        valign = "bottom",
        font = beautiful.keyboard_icon.font,
        size = 30,
        color = beautiful.random_accent_color(),
        text = beautiful.keyboard_icon.icon,
    }

    local text = widgets.text
    {
        halign = "center",
        valign = "bottom",
        size = 15
    }

    local hide_timer = gtimer
    {
        timeout = 1,
        callback = function()
            ret.widget.visible = false
        end
    }

    ret.widget = awful.popup
    {
        type = "notification",
        screen = awful.screen.focused(),
        visible = false,
        ontop = true,
        placement = function(c)
            awful.placement.centered(c,
            {
                offset =
                {
                    y = 300
                }
            })
        end,
        minimum_width = dpi(200),
        minimum_height = dpi(200),
        shape = helpers.ui.rrect(beautiful.border_radius),
        bg = beautiful.colors.background,
        border_width = 0,
        border_color = beautiful.border_color_active,
        widget =
        {
            widget = wibox.container.place,
            halign = "center",
            valign = "center",
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(30),
                icon,
                text
            },
        }
    }

    local show = false
    keyboard_layout_daemon:connect_signal("update", function(self, layout)
        if show == true then
            text:set_text(layout)
            if ret.widget.visible then
                hide_timer:again()
            else
                ret.widget.visible = true
                hide_timer:again()
            end
        end
        show = true
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance