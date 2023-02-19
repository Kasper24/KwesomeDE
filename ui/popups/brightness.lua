-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gtimer = require("gears.timer")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local brightness_daemon = require("daemons.system.brightness")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi

local instance = nil

local function new()
    local icon = wibox.widget {
        widget = widgets.text,
        halign = "center",
        valign = "bottom",
        icon = beautiful.icons.brightness,
        size = 30
    }

    local text = wibox.widget {
        widget = widgets.text,
        halign = "center",
        valign = "bottom",
        size = 15
    }

    local slider = wibox.widget {
        widget = widgets.progressbar,
        forced_width = dpi(150),
        forced_height = dpi(30),
        shape = helpers.ui.rrect(),
        bar_shape = helpers.ui.rrect(),
        value = 0,
        max_value = 100,
        background_color = beautiful.colors.surface,
        color = beautiful.icons.brightness.color
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
                spacing = dpi(15),
                icon,
                text,
                slider
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

    local anim = helpers.animation:new{
        duration = 0.2,
        easing = helpers.animation.easing.linear,
        update = function(self, pos)
            slider.value = pos
        end
    }

    local show = false
    brightness_daemon:connect_signal("update", function(self, brightness)
        if show == true then
            text:set_text(brightness)
            anim:set(brightness)

            if widget.visible == false then
                widget:show()
            end
            hide_timer:again()
        else
            anim:set(brightness)
            show = true
        end
    end)

    return widget
end

if not instance then
    instance = new()
end
return instance
