local wibox = require("wibox")
local widgets = require("ui.widgets")
local slider_text_input = require("ui.apps.settings.slider_text_input")
local picker = require("ui.apps.settings.picker")
local separator = require("ui.apps.settings.separator")
local beautiful = require("beautiful")
local theme_daemon = require("daemons.system.theme")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local ui = {
    mt = {}
}

local function new()
    return wibox.widget {
        layout = wibox.layout.overflow.vertical,
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(10),
        step = 50,
        spacing = dpi(15),
        picker.folder {
            title = "Wallpaper Engine Command/Path:",
            initial_value = theme_daemon:get_wallpaper_engine_command(),
            on_changed = function(text)
                theme_daemon:set_wallpaper_engine_command(text)
            end
        },
        picker.folder {
            title = "Assets Folder:",
            initial_value = theme_daemon:get_wallpaper_engine_assets_folder(),
            on_changed = function(text)
                theme_daemon:set_wallpaper_engine_assets_folder(text)
            end
        },
        picker.folder {
            title = "Workshop Folder",
            initial_value = theme_daemon:get_wallpaper_engine_workshop_folder(),
            on_changed = function(text)
                theme_daemon:set_wallpaper_engine_workshop_folder(text)
            end
        },
        separator(),
        slider_text_input {
            title = "Framerate:",
            value = theme_daemon:get_wallpaper_engine_fps(),
            minimum = 1,
            maximum = 360,
            round = true,
            on_changed = function(value)
                theme_daemon:set_wallpaper_engine_fps(value)
            end,
        }
    }
end

function ui.mt:__call()
    return new()
end

return setmetatable(ui, ui.mt)
