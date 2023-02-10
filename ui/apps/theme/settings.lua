-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gshape = require("gears.shape")
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

local accent_color = beautiful.colors.random_accent_color()

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
        prompt.widget
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
        color = accent_color,
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

local function picom_slider(key, max, divide_by, round)
    local display_name = key:gsub("(%l)(%w*)", function(a, b)
        return string.upper(a) .. b
    end)
    display_name = display_name:gsub("-", " ") .. ": "

    local name = wibox.widget {
        widget = widgets.text,
        size = 15,
        text = display_name
    }

    local slider = wibox.widget {
        widget = widgets.slider,
        forced_width = dpi(420),
        forced_height = dpi(20),
        value = picom_daemon["get_" .. key](picom_daemon) * divide_by,
        maximum = max or 100,
        bar_height = 5,
        bar_shape = helpers.ui.rrect(beautiful.border_radius),
        bar_color = beautiful.colors.surface,
        bar_active_color = accent_color,
        handle_width = dpi(15),
        handle_color = beautiful.colors.on_background,
        handle_shape = gshape.circle
    }

    local value_text = wibox.widget {
        widget = widgets.text,
        size = 15,
        text = picom_daemon["get_" .. key](picom_daemon)
    }

    slider:connect_signal("property::value", function(self, value, instant)
        local value = value / (divide_by or 1)
        if round == true then
            value = math.floor(value)
        end
        value_text:set_text(value)
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

local function new(layout)
    local back_button = wibox.widget {
        widget = widgets.button.text.normal,
        forced_width = dpi(50),
        forced_height = dpi(50),
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
                scrollbar_widget = {
                    widget = wibox.widget.separator,
                    shape = helpers.ui.rrect(beautiful.border_radius)
                },
                scrollbar_width = dpi(10),
                step = 50,
                spacing = dpi(15),
                separator(),
                command_after_generation(),
                separator(),
                picom_slider("active-opacity", 100, 100, false),
                picom_slider("inactive-opacity", 100, 100, false),
                separator(),
                picom_slider("corner-radius", 100, 1, true),
                picom_slider("blur-strength", 20, 1, true),
                separator(),
                picom_slider("animation-stiffness", 1000, 1, true),
                picom_slider("animation-dampening", 200, 1, true),
                picom_slider("animation-window-mass", 100, 1, true),
                picom_checkbox("animations"),
                picom_checkbox("animation-clamping"),
                separator(),
                picom_slider("shadow-radius", 100, 1, true),
                picom_slider("shadow-opacity", 100, 100, false),
                picom_slider("shadow-offset-x", 100, 1, true),
                picom_slider("shadow-offset-y", 100, 1, true),
                picom_checkbox("shadow"),
                separator(),
                picom_slider("fade-delta", 100, 1, true),
                picom_slider("fade-in-step", 100, 100, false),
                picom_slider("fade-out-step", 100, 100, false),
                picom_checkbox("fading")
            }
        }
    }
end

function settings.mt:__call(layout)
    return new(layout)
end

return setmetatable(settings, settings.mt)
