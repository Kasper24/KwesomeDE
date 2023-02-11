-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gshape = require("gears.shape")
local gmath = require("gears.math")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local theme_daemon = require("daemons.system.theme")
local picom_daemon = require("daemons.system.picom")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local settings = {
    mt = {}
}

local function separator()
    return wibox.widget {
        widget = widgets.background,
        forced_height = dpi(1),
        shape = helpers.ui.rrect(beautiful.border_radius),
        bg = beautiful.colors.surface
    }
end

local function command_after_generation()
    local title = wibox.widget {
        widget = widgets.text,
        size = 15,
        text = "Command after generation: "
    }

    local prompt = wibox.widget {
        widget = widgets.prompt,
        forced_width = dpi(600),
        forced_height = dpi(50),
        halign = "left",
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

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        title,
        prompt
    }
end

local function picom_checkbox(key)
    local display_name = key:gsub("(%l)(%w*)", function(a, b)
        return string.upper(a) .. b
    end)
    display_name = display_name:gsub("-", " ") .. ": "

    local name = wibox.widget {
        widget = widgets.text,
        size = 15,
        text = display_name
    }

    local checkbox = wibox.widget {
        widget = widgets.checkbox,
        state = picom_daemon["get_" .. key](picom_daemon),
        active_color = beautiful.icons.spraycan.color,
        on_turn_on = function()
            picom_daemon["set_" .. key](picom_daemon, true)
        end,
        on_turn_off = function()
            picom_daemon["set_" .. key](picom_daemon, false)
        end
    }

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15),
        name,
        checkbox
    }
end

local function picom_slider(key, maximum, round)
    local display_name = key:gsub("(%l)(%w*)", function(a, b)
        return string.upper(a) .. b
    end)
    display_name = display_name:gsub("-", " ") .. ": "

    local name = wibox.widget {
        widget = widgets.text,
        size = 15,
        text = display_name
    }

    local value = picom_daemon["get_" .. key](picom_daemon)
    local slider = widgets.slider {
        forced_width = dpi(420),
        forced_height = dpi(20),
        value = value,
        maximum = maximum,
        bar_active_color = beautiful.icons.spraycan.color,
    }

    value = helpers.misc.round_to_decimal_places(value, 2)
    local value_text = wibox.widget {
        widget = widgets.text,
        size = 15,
        text = value
    }

    slider:connect_signal("property::value", function(self, value, instant)
        if round == true then
            value = gmath.round(value)
        end
        value_text:set_text(helpers.misc.round_to_decimal_places(value, 2))
        picom_daemon["set_" .. key](picom_daemon, value)
    end)

    return wibox.widget {
        layout = wibox.layout.align.horizontal,
        name,
        {
            widget = wibox.container.margin,
            margins = {
                right = dpi(15)
            },
            slider
        },
        value_text
    }
end

local function theme_slider(text, initial_value, maximum, on_changed)
    local name = wibox.widget {
        widget = widgets.text,
        size = 15,
        text = text
    }

    local slider = widgets.slider {
        forced_width = dpi(420),
        forced_height = dpi(20),
        maximum = maximum,
        value = initial_value,
        bar_active_color = beautiful.icons.spraycan.color,
    }

    initial_value = helpers.misc.round_to_decimal_places(initial_value, 2)
    local value_text = wibox.widget {
        widget = widgets.text,
        size = 15,
        text = initial_value
    }

    slider:connect_signal("property::value", function(self, value)
        value_text:set_text(helpers.misc.round_to_decimal_places(value, 2))
        on_changed(value)
    end)

    return wibox.widget {
        layout = wibox.layout.align.horizontal,
        name,
        {
            widget = wibox.container.margin,
            margins = {
                right = dpi(15)
            },
            slider
        },
        value_text
    }
end

local function new(layout)
    local back_button = wibox.widget {
        widget = widgets.button.text.normal,
        forced_width = dpi(50),
        forced_height = dpi(50),
        text_normal_bg = beautiful.icons.spraycan.color,
        icon = beautiful.icons.left,
        on_release = function()
            layout:raise(2)
        end
    }

    local settings_text = wibox.widget {
        widget = widgets.text,
        bold = true,
        size = 15,
        text = "Settings"
    }

    return wibox.widget {
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
            margins = {
                left = dpi(25),
                right = dpi(25)
            },
            {
                layout = widgets.overflow.vertical,
                scrollbar_widget = widgets.scrollbar,
                scrollbar_width = dpi(10),
                step = 50,
                spacing = dpi(15),
                separator(),
                command_after_generation(),
                separator(),
                theme_slider("UI Opacity: ", theme_daemon:get_ui_opacity(), 1, function(value)
                    theme_daemon:set_ui_opacity(value)
                end),
                picom_slider("active-opacity", 1, false),
                picom_slider("inactive-opacity", 1, false),
                separator(),
                theme_slider("UI Border Radius: ", theme_daemon:get_ui_border_radius(), 100, function(value)
                    theme_daemon:set_ui_border_radius(value)
                end),
                picom_slider("corner-radius", 100, true),
                picom_slider("blur-strength", 20, true),
                separator(),
                picom_slider("animation-stiffness", 1000, true),
                picom_slider("animation-dampening", 200, true),
                picom_slider("animation-window-mass", 100, true),
                picom_checkbox("animations"),
                picom_checkbox("animation-clamping"),
                separator(),
                picom_slider("shadow-radius", 100, true),
                picom_slider("shadow-opacity", 1, false),
                picom_slider("shadow-offset-x", 100, true),
                picom_slider("shadow-offset-y", 100, true),
                picom_checkbox("shadow"),
                separator(),
                picom_slider("fade-delta", 100, true),
                picom_slider("fade-in-step", 1, false),
                picom_slider("fade-out-step", 1, false),
                picom_checkbox("fading")
            }
        }
    }
end

function settings.mt:__call(layout)
    return new(layout)
end

return setmetatable(settings, settings.mt)
