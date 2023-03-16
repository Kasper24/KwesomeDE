-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local beautiful = require("beautiful")
local naughty = require("naughty")
local system_daemon = require("daemons.system.system")

system_daemon:connect_signal("package_manager::updates", function(self, name, updates_count, updates)
    local title = updates_count .. " Updates availabvle"
    if updates_count == 0 then
        title = "Your system is up to date"
    end

    naughty.notification {
        app_font_icon = beautiful.icons.computer,
        app_name = name,
        font_icon = beautiful.icons.download,
        title = title,
        text = updates
    }
end)
