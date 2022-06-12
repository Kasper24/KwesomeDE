-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gtimer = require("gears.timer")
local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local beautiful = require("beautiful")
local pactl_daemon = require("daemons.hardware.pactl")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi

local instance = nil

local function new()
    local ret = {}

    local icon = widgets.text
    {
        halign = "center",
        size = 30,
        color = beautiful.random_accent_color(),
        font = beautiful.volume_normal_icon.font,
        text = beautiful.volume_normal_icon.icon,
    }

    local text = widgets.text
    {
        halign = "center",
        valign = "bottom",
        size = 15
    }

    local slider = wibox.widget
    {
        widget = wibox.widget.progressbar,
        forced_width = dpi(150),
        forced_height = dpi(30),
        shape = helpers.ui.rrect(beautiful.border_radius),
        bar_shape = helpers.ui.rrect(beautiful.border_radius),
        value = 0,
        max_value = 100,
        background_color = beautiful.colors.surface,
        color =
        {
            type = "linear",
            from = {0, 0},
            to = {200, 50},
            stops = {{0, beautiful.random_accent_color()}, {0.50, beautiful.random_accent_color()}}
        },
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
                spacing = dpi(15),
                icon,
                text,
                slider
            },
        }
    }

    local show = false
    pactl_daemon:connect_signal("default_sinks_updated", function(self, device)
        if show == true then
            if device.mute or device.volume == 0 then
                icon:set_text(beautiful.volume_off_icon.icon)
            elseif device.volume <= 33 then
                icon:set_text(beautiful.volume_low_icon.icon)
            elseif device.volume <= 66 then
                icon:set_text(beautiful.volume_normal_icon.icon)
            elseif device.volume > 66 then
                icon:set_text(beautiful.volume_high_icon.icon)
            end

            text:set_text(device.volume)
            slider.value = device.volume

            if ret.widget.visible then
                hide_timer:again()
            else
                ret.widget.visible = true
                hide_timer:again()
            end
        else
            slider.value = device.volume
            show = true
        end
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance
