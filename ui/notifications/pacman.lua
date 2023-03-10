-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local beautiful = require("beautiful")
local naughty = require("naughty")
local system_daemon = require("daemons.system.system")

system_daemon:connect_signal("pacman::updates_available", function(self, updates_count, updates)
    naughty.notification {
        app_font_icon = beautiful.icons.computer,
        app_name = "Pacman",
        font_icon = beautiful.icons.download,
        title = updates_count .. " Updates availabvle",
        text = updates
    }
end)
