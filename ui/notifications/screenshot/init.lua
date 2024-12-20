-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local naughty = require("naughty")
local screenshot_daemon = require("daemons.system.screenshot")
local library = require("library")
local dpi = beautiful.xresources.apply_dpi

local icons = {"camera", "camera-app", "camera-photo", "gscreenshot", "kscreenshot", "accessories-screenshot"}

local error_icons = {"system-error", "dialog-error", "aptdaemon-error", "arch-error-symbolic", "data-error",
                     "dialog-error-symbolic", "emblem-error", "emblem-insync-error", "error",
                     "gnome-netstatus-error.svg", "gtk-dialog-error", "itmages-error", "mintupdate-error",
                     "ownCloud_error", "script-error", "state-error", "stock_dialog-error", "SuggestionError",
                     "yum-indicator-error"}

screenshot_daemon:connect_signal("ended", function(self, folder, file_name)
    local view_file = naughty.action {
        name = "View"
    }
    local open_dir = naughty.action {
        name = "Folder"
    }
    local copy = naughty.action {
        name = "Copy"
    }

    view_file:connect_signal("invoked", function()
        awful.spawn("xdg-open " .. folder .. file_name, false)
    end)

    open_dir:connect_signal("invoked", function()
        awful.spawn("xdg-open " .. folder, false)
    end)

    copy:connect_signal("invoked", function()
        screenshot_daemon:copy_screenshot(folder .. file_name)
    end)

    naughty.notification {
        app_font_icon = beautiful.icons.camera_retro,
        app_icon = icons,
        app_name = "Screenshot",
        icon = folder .. file_name,
        title = "Screenshot taken",
        message = "Screenshot saved to " .. folder .. file_name,
        actions = {view_file, open_dir, copy}
    }
end)

screenshot_daemon:connect_signal("color::picked", function(self, color)
    local copy = naughty.action {
        name = "Copy"
    }

    copy:connect_signal("invoked", function()
        screenshot_daemon:copy_color(color)
    end)

    local icon = wibox.widget.draw_to_image_surface(wibox.widget {
        widget = widgets.background,
        forced_width = dpi(40),
        forced_height = dpi(40),
        shape = library.ui.rrect(),
        bg = color,
    }, dpi(40), dpi(40))

    naughty.notification {
        app_font_icon = beautiful.icons.camera_retro,
        app_icon = icons,
        app_name = "Screenshot",
        icon = icon,
        title = "Color picked",
        message = color,
        actions = { copy }
    }
end)

screenshot_daemon:connect_signal("error::create_file", function(self, error)
    naughty.notification {
        app_font_icon = beautiful.icons.camera_retro,
        app_icon = icons,
        app_name = "Screenshot",
        font_icon = beautiful.icons.circle_exclamation,
        icon = error_icons,
        title = "Error",
        message = error,
        category = "im.error"
    }
end)

screenshot_daemon:connect_signal("error::create_directory", function()
    naughty.notification {
        app_font_icon = beautiful.icons.camera_retro,
        app_icon = icons,
        app_name = "Screenshot",
        font_icon = beautiful.icons.circle_exclamation,
        icon = error_icons,
        title = "error",
        message = "Failed to create directory",
        category = "im.error"
    }
end)
