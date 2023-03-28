local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local theme_daemon = require("daemons.system.theme")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local ui = {
    mt = {}
}

local function slider(text, initial_value, maximum, round, on_changed, minimum, signal)
    local name = wibox.widget {
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

    SETTINGS_APP:connect_signal("visibility", function(self, visible)
        if visible == false then
            slider_text_input:get_text_input():unfocus()
        end
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
        name,
        slider_text_input
    }
end

local function folder_picker(title, initial_value, on_changed)
    return wibox.widget {
        layout = wibox.layout.align.horizontal,
        {
            widget = widgets.text,
            forced_width = dpi(200),
            size = 15,
            text = title,
        },
        {
            widget = widgets.picker,
            type = "folder",
            initial_value = initial_value,
            on_changed = function(text)
                on_changed(text)
            end
        }
    }
end

local function new()
    return wibox.widget {
        layout = wibox.layout.overflow.vertical,
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(10),
        step = 50,
        spacing = dpi(15),
        folder_picker("Assets Folder:", theme_daemon:get_wallpaper_engine_assets_folder(), function(text)
            theme_daemon:set_wallpaper_engine_assets_folder(text)
        end),
        folder_picker("Workshop Folder:", theme_daemon:get_wallpaper_engine_workshop_folder(), function(text)
            theme_daemon:set_wallpaper_engine_workshop_folder(text)
        end),
        slider("Framerate:", theme_daemon:get_wallpaper_engine_fps(), 360, true, function(value)
            theme_daemon:set_wallpaper_engine_fps(value)
        end, 1),
    }
end

function ui.mt:__call()
    return new()
end

return setmetatable(ui, ui.mt)