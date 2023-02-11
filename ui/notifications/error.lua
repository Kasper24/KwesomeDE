-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local beautiful = require("beautiful")
local naughty = require("naughty")

local icons = {"system-error", "dialog-error", "aptdaemon-error", "arch-error-symbolic", "data-error",
               "dialog-error-symbolic", "emblem-error", "emblem-insync-error", "error", "gnome-netstatus-error.svg",
               "gtk-dialog-error", "itmages-error", "mintupdate-error", "ownCloud_error", "script-error", "state-error",
               "stock_dialog-error", "SuggestionError", "yum-indicator-error"}

naughty.connect_signal("request::display_error", function(message, startup)
    naughty.notification {
        app_font_icon = beautiful.icons.computer,
        app_icon = icons,
        app_name = "Awesome",
        font_icon = beautiful.icons.circle_exclamation,
        icon = icons,
        title = "Error" .. (startup and " during startup" or ""),
        message = message,
        urgency = "critical"
    }
end)
