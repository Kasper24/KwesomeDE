local wibox = require("wibox")
local widgets = require("ui.widgets")
local slider_text_input = require("ui.apps.settings.slider_text_input")
local checkbox = require("ui.apps.settings.checkbox")
local picker = require("ui.apps.settings.picker")
local separator = require("ui.apps.settings.separator")
local beautiful = require("beautiful")
local theme_daemon = require("daemons.system.theme")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local ui = {
    mt = {}
}

local function slider(text, initial_value, maximum, round, on_changed, minimum, signal)
    local title = wibox.widget {
        widget = widgets.text,
        forced_width = dpi(200),
        size = 15,
        text = text
    }

    local slider_text_input = widgets.slider_text_input {
        slider_width = dpi(400),
        round = round,
        value = initial_value,
        minimum = minimum or 0,
        maximum = maximum,
        bar_active_color = beautiful.icons.computer.color,
        selection_bg = beautiful.icons.computer.color
    }

    SETTINGS_APP:connect_signal("tab::select", function()
        slider_text_input:get_text_input():unfocus()
    end)

    SETTINGS_APP:get_client():connect_signal("request::unmanage", function()
        slider_text_input:get_text_input():unfocus()
    end)

    SETTINGS_APP:get_client():connect_signal("unfocus", function()
        slider_text_input:get_text_input():unfocus()
    end)

    SETTINGS_APP:get_client():connect_signal("mouse::leave", function()
        slider_text_input:get_text_input():unfocus()
    end)

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
        title,
        slider_text_input
    }
end

local function new()
    return wibox.widget {
        layout = wibox.layout.overflow.vertical,
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(10),
        step = 50,
        spacing = dpi(15),
        picker {
            title = "Assets Folder:",
            initial_value = theme_daemon:get_wallpaper_engine_assets_folder(),
            on_changed = function(text)
                theme_daemon:set_wallpaper_engine_assets_folder(text)
            end
        },
        picker {
            title = "Workshop Folder",
            initial_value = theme_daemon:get_wallpaper_engine_workshop_folder(),
            on_changed = function(text)
                theme_daemon:set_wallpaper_engine_workshop_folder(text)
            end
        },
        separator(),
        slider("Framerate:", theme_daemon:get_wallpaper_engine_fps(), 360, true, function(value)
            theme_daemon:set_wallpaper_engine_fps(value)
        end, 1),
    }
end

function ui.mt:__call()
    return new()
end

return setmetatable(ui, ui.mt)