-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local beautiful = require("beautiful")
local naughty = require("naughty")
local theme_daemon = require("daemons.system.theme")

theme_daemon:connect_signal("templates::already_exists", function(self, template)
    naughty.notification {
        app_font_icon = beautiful.icons.spraycan,
        app_name = "Theme",
        font_icon = beautiful.icons.circle_exclamation,
        title = template,
        text = "already exists"
    }
end)

theme_daemon:connect_signal("templates::not_base", function(self, template)
    naughty.notification {
        app_font_icon = beautiful.icons.spraycan,
        app_name = "Theme",
        font_icon = beautiful.icons.circle_exclamation,
        title = template,
        text = "not a .base file"
    }
end)

theme_daemon:connect_signal("wallpapers_paths::already_exists", function(self, wallpaper_path)
    naughty.notification {
        app_font_icon = beautiful.icons.spraycan,
        app_name = "Theme",
        font_icon = beautiful.icons.circle_exclamation,
        title = wallpaper_path,
        text = "already exists"
    }
end)

theme_daemon:connect_signal("colorscheme::generation::error", function(self, wallpaper)
    naughty.notification {
        app_font_icon = beautiful.icons.spraycan,
        app_name = "Theme",
        font_icon = beautiful.icons.circle_exclamation,
        title = wallpaper,
        text = "Failed to generate a colorscheme, using a default colorscheme"
    }
end)

theme_daemon:connect_signal("wallpaper_engine::error", function(self, error, crash)
    naughty.notification {
        app_font_icon = beautiful.icons.spraycan,
        app_name = "Wallpaper Engine",
        font_icon = beautiful.icons.circle_exclamation,
        title = crash and "Crash" or "Error",
        text = error
    }
end)
