-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local awful = require("awful")
local gtimer = require("gears.timer")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local library = require("library")
local dpi = beautiful.xresources.apply_dpi
local math = math
local os = os
local capi = {
    awesome = awesome,
    screen = screen
}

local greeters = {"Authentication success! Logging in!", "Logging in! Biatch",
                  "Splish! Splash! Your password is trash!", "Looking good today~", "What are you doing, stepbro?~",
                  "You are someone\"s reason to smile.", "Finally, someone with a good amount of IQ!"}

awful.screen.connect_for_each_screen(function(s)
    if capi.awesome.startup == false then
        return
    end

    local picture = wibox.widget {
        widget = widgets.profile,
        forced_height = dpi(180),
        forced_width = dpi(180),
    }

    local name = wibox.widget {
        widget = widgets.text,
        halign = "center",
        size = 50,
        text = "Welcome back, " .. os.getenv("USER"):upper() .. "!"
    }

    local user = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        picture,
        name
    }

    local greeter = wibox.widget {
        widget = widgets.text,
        halign = "center",
        text = greeters[math.random(#greeters)]
    }

    local spinning_circle = widgets.spinning_circle {
        forced_width = dpi(200),
        forced_height = dpi(200)
    }

    local loading_popup = widgets.popup {
        screen = s,
        visible = true,
        ontop = true,
        placement = awful.placement.maximize,
        bg = beautiful.colors.background,
        widget = {
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

    gtimer.start_new(5, function()
        spinning_circle:stop()
        spinning_circle = nil
        loading_popup.visible = false
        loading_popup = nil

        return false
    end)
end)
