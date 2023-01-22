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

screenshot_daemon:connect_signal("ended", function(self, screenshot_directory, file_path)
    local view_file = naughty.action { name = "View" }
    local open_dir = naughty.action{ name = "Folder" }
    local copy = naughty.action { name = "Copy" }

    view_file:connect_signal("invoked", function()
        awful.spawn("xdg-open " .. screenshot_directory .. file_path, false)
    end)

    open_dir:connect_signal("invoked", function()
        awful.spawn("xdg-open " .. screenshot_directory, false)
    end)

    copy:connect_signal("invoked", function()
        awful.spawn("xclip -selection clipboard -t image/png -i " .. file_path, false)
    end)

    naughty.notification
    {
        app_font_icon = beautiful.icons.camera_retro,
        app_icon = icons,
        app_name = "Screenshot",
        icon = file_path,
        title = "Screenshot taken",
        message = "Screenshot saved to " .. file_path,
        actions = { view_file, open_dir, copy }
    }
end)