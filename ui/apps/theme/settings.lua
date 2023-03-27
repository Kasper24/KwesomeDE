-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local theme_daemon = require("daemons.system.theme")
local picom_daemon = require("daemons.system.picom")
local helpers = require("helpers")
local filesystem = require("external.filesystem")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local settings = {
    mt = {}
}

local FOLDER_PICKER_SCRIPT_PATH = filesystem.filesystem.get_awesome_config_dir("scripts") .. "folder-picker.lua"

local function separator()
    return wibox.widget {
        widget = widgets.background,
        forced_height = dpi(1),
        shape = helpers.ui.rrect(),
        bg = beautiful.colors.surface
    }
end

local function command_after_generation()
    local title = wibox.widget {
        widget = widgets.text,
        size = 15,
        text = "Command after generation: "
    }

    local text_input = wibox.widget {
        widget = widgets.text_input,
        forced_width = dpi(600),
        unfocus_on_client_clicked = false,
        initial = theme_daemon:get_command_after_generation(),
        selection_bg = beautiful.icons.spraycan.color,
        widget_template = wibox.widget {
			widget = widgets.background,
			shape = helpers.ui.rrect(),
			bg = beautiful.colors.surface,
			{
				widget = wibox.container.margin,
				margins = dpi(10),
				{
					widget = wibox.widget.textbox,
					id = "text_role"
				}
			}
		}
    }

    text_input:connect_signal("property::text", function(self, text)
        theme_daemon:set_command_after_generation(text)
    end)

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_height = dpi(40),
        title,
        text_input
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
        handle_active_color = beautiful.icons.spraycan.color,
        on_turn_on = function()
            picom_daemon["set_" .. key](picom_daemon, true)
        end,
        on_turn_off = function()
            picom_daemon["set_" .. key](picom_daemon, false)
        end
    }

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_height = dpi(40),
        spacing = dpi(15),
        name,
        checkbox
    }
end

local function picom_slider(key, maximum, round, minimum)
    local display_name = key:gsub("(%l)(%w*)", function(a, b)
        return string.upper(a) .. b
    end)
    display_name = display_name:gsub("-", " ") .. ":"

    local name = wibox.widget {
        widget = widgets.text,
        forced_width = dpi(190),
        size = 15,
        text = display_name
    }

    local slider_text_input = widgets.slider_text_input {
        slider_width = dpi(410),
        round = round,
        minimum = minimum or 0,
        maximum = maximum,
        value = picom_daemon["get_" .. key](picom_daemon),
        bar_active_color = beautiful.icons.spraycan.color,
        selection_bg = beautiful.icons.spraycan.color
    }

    slider_text_input:connect_signal("property::value", function(self, value, instant)
        picom_daemon["set_" .. key](picom_daemon, value)
    end)

    return wibox.widget {
        layout = wibox.layout.align.horizontal,
        forced_height = dpi(40),
        name,
        slider_text_input
    }
end

local function profile_image()
    local title = wibox.widget {
        widget = widgets.text,
        forced_width = dpi(190),
        size = 15,
        text = "Profile image:"
    }

    local folder_text_input = wibox.widget {
        widget = widgets.text_input,
        forced_width = dpi(410),
        unfocus_on_client_clicked = false,
        initial = theme_daemon:get_profile_image(),
        selection_bg = beautiful.icons.spraycan.color,
        widget_template = wibox.widget {
			widget = widgets.background,
			shape = helpers.ui.rrect(),
			bg = beautiful.colors.surface,
			{
				widget = wibox.container.margin,
				margins = dpi(10),
				{
					widget = wibox.widget.textbox,
					id = "text_role"
				}
			}
		}
    }

    local text_changed = false

    folder_text_input:connect_signal("property::text", function(self, text)
        text_changed = true
    end)

    folder_text_input:connect_signal("unfocus", function(self, context, text)
        if text_changed then
            theme_daemon:set_profile_image(text)
            text_changed = false
        end
    end)

    local set_folder_button = wibox.widget {
        widget = widgets.button.text.normal,
        size = 15,
        text_normal_bg = beautiful.colors.on_background,
        text = "...",
        on_release = function()
            theme_daemon:set_profile_image_with_file_picker()
        end
    }

    theme_daemon:connect_signal("profile_image", function(self, profile_image)
        folder_text_input:set_text(profile_image)
    end)

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_height = dpi(35),
        spacing = dpi(15),
        title,
        folder_text_input,
        set_folder_button
    }
end

local function folder_picker(text, initial_value, on_changed)
    local title = wibox.widget {
        widget = widgets.text,
        forced_width = dpi(190),
        size = 15,
        text = text
    }

    local folder_text_input = wibox.widget {
        widget = widgets.text_input,
        forced_width = dpi(410),
        unfocus_on_client_clicked = false,
        initial = initial_value,
        selection_bg = beautiful.icons.spraycan.color,
        widget_template = wibox.widget {
            widget = widgets.background,
            shape = helpers.ui.rrect(),
            bg = beautiful.colors.surface,
            {
                widget = wibox.container.margin,
                margins = dpi(10),
                {
                    widget = wibox.widget.textbox,
                    id = "text_role"
                }
            }
		}
    }

    local text_changed = false

    folder_text_input:connect_signal("property::text", function(self, text)
        text_changed = true
    end)

    folder_text_input:connect_signal("unfocus", function(self, context, text)
        if text_changed then
            on_changed(text)
            text_changed = false
        end
    end)

    local set_folder_button = wibox.widget {
        widget = widgets.button.text.normal,
        size = 15,
        text_normal_bg = beautiful.colors.on_background,
        text = "...",
        on_release = function()
            awful.spawn.easy_async(FOLDER_PICKER_SCRIPT_PATH .. " '" .. text .. "'", function(stdout)
                stdout = helpers.string.trim(stdout)
                if stdout ~= "" and stdout ~= nil then
                    on_changed(stdout)
                    folder_text_input:set_text(stdout)
                end
            end)
        end
    }

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_height = dpi(35),
        spacing = dpi(15),
        title,
        folder_text_input,
        set_folder_button
    }
end

local function theme_checkbox(key)
    local name = wibox.widget {
        widget = widgets.text,
        size = 15,
        text = "UI " .. key:sub(1, 1):upper() .. key:sub(2):gsub("_", " ") .. ":"
    }

    local checkbox = wibox.widget {
        widget = widgets.checkbox,
        state = theme_daemon["get_ui_" .. key](theme_daemon),
        handle_active_color = beautiful.icons.spraycan.color,
        on_turn_on = function()
            theme_daemon["set_ui_" .. key](theme_daemon, true)
        end,
        on_turn_off = function()
            theme_daemon["set_ui_" .. key](theme_daemon, false)
        end
    }

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_height = dpi(40),
        spacing = dpi(15),
        name,
        checkbox
    }
end

local function theme_slider(text, initial_value, maximum, round, on_changed, minimum, signal)
    local name = wibox.widget {
        widget = widgets.text,
        forced_width = dpi(190),
        size = 15,
        text = text
    }

    local slider_text_input = widgets.slider_text_input {
        slider_width = dpi(410),
        round = round,
        value = initial_value,
        minimum = minimum or 0,
        maximum = maximum,
        bar_active_color = beautiful.icons.spraycan.color,
        selection_bg = beautiful.icons.spraycan.color
    }

    slider_text_input:connect_signal("property::value", function(self, value)
        on_changed(value)
    end)

    if signal then
        theme_daemon:connect_signal(signal, function(self, value)
            slider_text_input:set_value(tostring(value))
        end)
    end

    return wibox.widget {
        layout = wibox.layout.align.horizontal,
        forced_height = dpi(40),
        name,
        slider_text_input
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

    local layout = wibox.widget {
        layout = wibox.layout.overflow.vertical,
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(10),
        step = 50,
        spacing = dpi(15),
        separator(),
        command_after_generation(),
        separator(),
        profile_image(),
        {
            layout = wibox.layout.fixed.vertical,
            forced_height = dpi(60),
            spacing = dpi(5),
            theme_slider("DPI: ", theme_daemon:get_dpi(), 250, true, function(value)
                theme_daemon:set_dpi(value)
            end),
            {
                widget = widgets.text,
                italic = true,
                size = 10,
                text = "* Restart AwesomeWM for this to take effect"
            }
        },
        theme_slider("Useless gap: ", theme_daemon:get_useless_gap(), 250, true, function(value)
            theme_daemon:set_useless_gap(value)
        end, 0, "useless_gap"),
        theme_slider("Client gap: ", theme_daemon:get_client_gap(), 250, true, function(value)
            theme_daemon:set_client_gap(value)
        end, 0, "client_gap"),
        theme_slider("UI Opacity: ", theme_daemon:get_ui_opacity(), 1, false, function(value)
            theme_daemon:set_ui_opacity(value)
        end),
        theme_slider("UI Corner Radius: ", theme_daemon:get_ui_border_radius(), 100, true, function(value)
            theme_daemon:set_ui_border_radius(value)
        end),
        theme_slider("UI Animations FPS: ", theme_daemon:get_ui_animations_framerate(), 360, true, function(value)
            theme_daemon:set_ui_animations_framerate(value)
        end, 1),
        theme_checkbox("animations"),
        theme_checkbox("show_lockscreen_on_login"),
        separator(),
        folder_picker("WP Engine Assets Folder: ", theme_daemon:get_wallpaper_engine_assets_folder(), function(folder)
            theme_daemon:set_wallpaper_engine_assets_folder(folder)
        end),
        folder_picker("WP Engine Workshop Folder: ", theme_daemon:get_wallpaper_engine_workshop_folder(), function(folder)
            theme_daemon:set_wallpaper_engine_workshop_folder(folder)
        end),
        theme_slider("WP Engine FPS: ", theme_daemon:get_wallpaper_engine_fps(),360, true, function(value)
            theme_daemon:set_wallpaper_engine_fps(value)
        end, 1),
        separator(),
        picom_slider("active-opacity", 1, false, 0.1),
        picom_slider("inactive-opacity", 1, false, 0.1),
        separator(),
        picom_slider("corner-radius", 100, true),
        picom_slider("blur-strength", 20, true),
        separator(),
        picom_slider("shadow-radius", 100, true),
        picom_slider("shadow-opacity", 1, false),
        picom_slider("shadow-offset-x", 500, true, -500),
        picom_slider("shadow-offset-y", 500, true, -500),
        picom_checkbox("shadow"),
        separator(),
        picom_slider("fade-delta", 100, true),
        picom_slider("fade-in-step", 1, false),
        picom_slider("fade-out-step", 1, false),
        picom_checkbox("fading")
    }

    picom_daemon:connect_signal("animations::support", function()
        layout:add(separator())
        layout:add(picom_slider("animation-stiffness", 1000, true))
        layout:add(picom_slider("animation-dampening", 200, true))
        layout:add(picom_slider("animation-window-mass", 100, true))
        layout:add(picom_checkbox("animations"))
        layout:add(picom_checkbox("animation-clamping"))
    end)

    if picom_daemon:has_animation_support() then
        layout:add(separator())
        layout:add(picom_slider("animation-stiffness", 1000, true))
        layout:add(picom_slider("animation-dampening", 200, true))
        layout:add(picom_slider("animation-window-mass", 100, true))
        layout:add(picom_checkbox("animations"))
        layout:add(picom_checkbox("animation-clamping"))
    end

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
            layout
        }
    }
end

function settings.mt:__call(layout)
    return new(layout)
end

return setmetatable(settings, settings.mt)
