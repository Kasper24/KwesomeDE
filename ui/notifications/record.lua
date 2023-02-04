-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local beautiful = require("beautiful")
local naughty = require("naughty")
local record_daemon = require("daemons.system.record")

local icons = {"screenrecorder", "screen-recorder", "simplescreenrecorder", "deepin-screen-recorder",
               "com.github.mohelm97.screenrecorder", "org.deepin.flatdeb.deepin-screen-recorder", "record-desktop",
               "recordmydesktop", "gtk-recordmydesktop", "kali-recordmydesktop", "kazam-recording",
               "record-desktop-indicator", "record-desktop-indicator-recording", "green-recorder", "record",
               "gtk-media-record", "media-record", "youtube", "gtk-youtube-viewer", "web-google-youtube"}

local error_icons = {"simplescreenrecorder-error", "system-error", "dialog-error", "aptdaemon-error",
                     "arch-error-symbolic", "data-error", "dialog-error-symbolic", "emblem-error",
                     "emblem-insync-error", "error", "gnome-netstatus-error.svg", "gtk-dialog-error", "itmages-error",
                     "mintupdate-error", "ownCloud_error", "script-error", "state-error", "stock_dialog-error",
                     "SuggestionError", "yum-indicator-error"}

record_daemon:connect_signal("started", function()
    local stop = naughty.action {
        name = "Stop"
    }

    stop:connect_signal("invoked", function()
        record_daemon:stop_video()
    end)

    naughty.notification {
        app_font_icon = beautiful.icons.video,
        app_icon = icons,
        app_name = "Recorder",
        font_icon = beautiful.icons.toggle.on,
        icon = icons,
        title = "Video Recording",
        message = "Started",
        actions = {stop}
    }
end)

record_daemon:connect_signal("ended", function(self, folder, file_name)
    local view_file = naughty.action {
        name = "View"
    }
    local open_dir = naughty.action {
        name = "Folder"
    }

    view_file:connect_signal("invoked", function()
        awful.spawn("xdg-open " .. folder .. file_name, false)
    end)

    open_dir:connect_signal("invoked", function()
        awful.spawn("xdg-open " .. folder, false)
    end)

    naughty.notification {
        app_font_icon = beautiful.icons.video,
        app_icon = icons,
        app_name = "Recorder",
        font_icon = beautiful.icons.toggle.off,
        icon = icons,
        title = "Video Recording",
        message = "Video saved to " .. folder .. file_name,
        actions = {view_file, open_dir}
    }
end)

record_daemon:connect_signal("error::create_directory", function()
    naughty.notification {
        app_font_icon = beautiful.icons.video,
        app_icon = icons,
        app_name = "Recorder",
        font_icon = beautiful.icons.circle_exclamation,
        icon = error_icons,
        title = "Error",
        message = "Failed to create directory",
        category = "im.error"
    }
end)
