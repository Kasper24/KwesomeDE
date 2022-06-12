-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gtimer = require("gears.timer")
local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local math = math
local os = os
local capi = { awesome = awesome, screen = screen }

local greeters =
{
    "Authentication success! Logging in!",
    "Logging in! Biatch",
    "Splish! Splash! Your password is trash!",
    "Looking good today~",
    "What are you doing, stepbro?~",
    "You are someone\"s reason to smile.",
    "Finally, someone with a good amount of IQ!",
}

capi.screen.connect_signal("request::desktop_decoration", function(s)
    if capi.awesome.startup == false then
        return
    end

    local picture = wibox.widget
    {
        widget = wibox.widget.imagebox,
        halign = "center",
        clip_shape = helpers.ui.rrect(beautiful.border_radius),
        forced_height = dpi(180),
        forced_width = dpi(180),
        image = beautiful.profile_icon,
    }

    local name = widgets.text
    {
        halign = "center",
        size = 50,
        text = "Welcome back, " .. os.getenv("USER"):upper() .. "!"
    }

    local user = wibox.widget
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        picture,
        name
    }

    local greeter = widgets.text
    {
        halign = "center",
        text = greeters[math.random(#greeters)]
    }

    local spinning_circle = widgets.spinning_circle
    {
        forced_width = dpi(200),
        forced_height = dpi(200)
    }

    local loading_popup = awful.popup
    {
        type = "splash",
        ontop = true,
        placement = awful.placement.maximize,
        bg = beautiful.colors.background .. "28",
        widget =
        {
            widget = wibox.container.place,
            halign = "center",
            valign = "center",
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(15),
                user,
                greeter,
                spinning_circle
            }
        }
    }

    for s in capi.screen do
        if s == capi.screen.primary then
            s.loading_popup = loading_popup
        else
            s.loading_popup = widgets.screen_mask(s)
        end

        gtimer { timeout = 5, autostart = true, call_now = false, single_shot = true, callback = function()
            s.loading_popup.visible = false
            spinning_circle:abort()
            s.loading_popup = nil
        end }
    end
end)