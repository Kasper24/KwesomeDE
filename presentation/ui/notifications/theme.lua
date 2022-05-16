local beautiful = require("beautiful")
local naughty = require("naughty")
local theme_daemon = require("daemons.system.theme")
local helpers = require("helpers")

theme_daemon:connect_signal("templates::already_exists", function(self, template)
    naughty.notification
    {
        app_font_icon = beautiful.spraycan_icon,
        app_name = "Theme",
        font_icon = beautiful.circle_exclamation_icon,
        title = template,
        text = "already exists",
    }
end)

theme_daemon:connect_signal("templates::not_base", function(self, template)
    naughty.notification
    {
        app_font_icon = beautiful.spraycan_icon,
        app_name = "Theme",
        font_icon = beautiful.circle_exclamation_icon,
        title = template,
        text = "not a .base file",
    }
end)

theme_daemon:connect_signal("wallpapers_paths::already_exists", function(self, wallpaper_path)
    naughty.notification
    {
        app_font_icon = beautiful.spraycan_icon,
        app_name = "Theme",
        font_icon = beautiful.circle_exclamation_icon,
        title = wallpaper_path,
        text = "already exists",
    }
end)

theme_daemon:connect_signal("colorscheme::failed_to_generate", function(self, wallpaper)
    naughty.notification
    {
        app_font_icon = beautiful.spraycan_icon,
        app_name = "Theme",
        font_icon = beautiful.circle_exclamation_icon,
        title = "Failed to generate colorscheme",
        text = wallpaper,
    }
end)