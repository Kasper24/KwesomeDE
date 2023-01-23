-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local beautiful = require("beautiful")
local naughty = require("naughty")
local screenshot_daemon = require("daemons.system.screenshot")

local icons =
{
    "camera",
    "camera-app",
    "camera-photo",
    "gscreenshot",
    "kscreenshot",
    "accessories-screenshot"
}

local error_icons =
{
    "system-error",
    "dialog-error",
    "aptdaemon-error",
    "arch-error-symbolic",
    "data-error",
    "dialog-error-symbolic",
    "emblem-error",
    "emblem-insync-error",
    "error",
    "gnome-netstatus-error.svg",
    "gtk-dialog-error",
    "itmages-error",
    "mintupdate-error",
    "ownCloud_error",
    "script-error",
    "state-error",
    "stock_dialog-error",
    "SuggestionError",
    "yum-indicator-error"
}

screenshot_daemon:connect_signal("ended", function(self, screenshot_method, screenshot_directory, file_name)
    if screenshot_method == "flameshot" then
        return
    end

    local view_file = naughty.action { name = "View" }
    local open_dir = naughty.action{ name = "Folder" }
    local copy = naughty.action { name = "Copy" }

    view_file:connect_signal("invoked", function()
        awful.spawn("xdg-open " .. screenshot_directory .. file_name, false)
    end)

    open_dir:connect_signal("invoked", function()
        awful.spawn("xdg-open " .. screenshot_directory, false)
    end)

    copy:connect_signal("invoked", function()
        awful.spawn("xclip -selection clipboard -t image/png -i " .. screenshot_directory .. file_name, false)
    end)

    naughty.notification
    {
        app_font_icon = beautiful.camera_retro_icon,
        app_icon = icons,
        app_name = "Screenshot",
        icon = screenshot_directory .. file_name,
        title = "Screenshot taken",
        message = "Screenshot saved to " .. screenshot_directory .. file_name,
        actions = { view_file, open_dir, copy }
    }
end)

screenshot_daemon:connect_signal("error::create_file", function(self, error)
    naughty.notification
    {
        app_font_icon = beautiful.camera_retro_icon,
        app_icon = icons,
        app_name = "Screenshot",
        font_icon = beautiful.circle_exclamation_icon,
        icon = error_icons,
        title = "Error",
        message = error,
        category = "im.error"
    }
end)

screenshot_daemon:connect_signal("error::create_directory", function()
    naughty.notification
    {
        app_font_icon = beautiful.camera_retro_icon,
        app_icon = icons,
        app_name = "Screenshot",
        font_icon = beautiful.circle_exclamation_icon,
        icon = error_icons,
        title = "error",
        message = "Failed to create directory",
        category = "im.error"
    }
end)