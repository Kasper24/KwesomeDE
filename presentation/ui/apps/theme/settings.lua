-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local gshape = require("gears.shape")
local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local beautiful = require("beautiful")
local theme_daemon = require("daemons.system.theme")
local picom_daemon = require("daemons.system.picom")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local settings = { mt = {} }

local function separator()
    return wibox.widget
    {
        widget = wibox.widget.separator,
        forced_width = dpi(1),
        forced_height = dpi(1),
        shape = helpers.ui.rrect(beautiful.border_radius),
        orientation = "horizontal",
        color = beautiful.colors.surface
    }
end

local function command_after_generation()
    local title = wibox.widget
    {
        widget = widgets.text,
        -- size = 15,
        text = "Run after generation: "
    }

    local prompt = widgets.prompt
    {
        forced_width = dpi(600),
        forced_height = dpi(50),
        reset_on_stop = false,
        prompt = "",
        text = theme_daemon:get_command_after_generation(),
        text_color = beautiful.colors.on_background,
        icon_font = beautiful.icons.launcher.font,
        icon = nil,
        changed_callback = function(text)
            theme_daemon:set_command_after_generation(text)
        end
    }

    return wibox.widget
    {
        layout = wibox.layout.fixed.horizontal,
        title,
        prompt.widget
    }
end

local function picom_slider(key, max)
    local display_name = key:gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
    display_name = display_name:gsub("-", " ")  .. ": "

    local name = wibox.widget
    {
        widget = widgets.text,
        text = display_name
    }

    local slider = wibox.widget
    {
        widget = widgets.slider,
        forced_height = dpi(20),
        value = picom_daemon["get_" .. key](picom_daemon),
        maximum = max or 100,
        bar_height = 5,
        bar_shape = helpers.ui.rrect(beautiful.border_radius),
        bar_color = beautiful.colors.surface,
        bar_active_color = beautiful.random_accent_color(),
        handle_width = dpi(15),
        handle_color = beautiful.colors.on_background,
        handle_shape = gshape.circle,
    }

    slider:connect_signal("property::value", function(self, value, instant)
        picom_daemon["set_" .. key](picom_daemon, value)
    end)

    return wibox.widget
    {
        layout = wibox.layout.fixed.horizontal,
        name,
        slider
    }
end

local function new(layout)
    local back_button = wibox.widget
    {
        widget = widgets.button.text.normal,
        forced_width = dpi(50),
        forced_height = dpi(50),
        icon = beautiful.icons.left,
        on_release = function()
            layout:raise(2)
        end
    }

    local settings_text = wibox.widget
    {
        widget = widgets.text,
        bold = true,
        size = 15,
        text = "Settings",
    }

    return wibox.widget
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        {
            layout = wibox.layout.fixed.horizontal,
            spacing = dpi(15),
            back_button,
            settings_text
        },
        {
            widget = wibox.container.margin,
            margins = { left = dpi(25), right = dpi(25) },
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(15),
                separator(),
                command_after_generation(),
                separator(),
                picom_slider("active-opacity", 1),
                picom_slider("inactive-opacity", 1),
                separator(),
                picom_slider("corner-radius"),
                picom_slider("blur-strength", 20),
                separator(),
                picom_slider("shadow-radius", 20),
                picom_slider("shadow-offset-x", 1),
                picom_slider("shadow-offset-y", 1),
                separator(),
                picom_slider("fade-delta", 20),
                picom_slider("fade-in-step", 1),
                picom_slider("fade-out-step", 1),
            }
        }
    }

end

function settings.mt:__call(layout)
    return new(layout)
end

return setmetatable(settings, settings.mt)