-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local beautiful = require("beautiful")
local naughty = require("naughty")
local system_daemon = require("daemons.system.system")

local icons = {"password", "passwords", "preferences-desktop-user-password", "1password", "password-manager",
               "com.bixense.PasswordCalculator", "kali-password-attacks-trans.svg", "dialog-password"}

system_daemon:connect_signal("wrong_password", function(self)
    naughty.notification {
        app_font_icon = beautiful.icons.lock,
        app_icon = icons,
        app_name = "Security",
        font_icon = beautiful.icons.circle_exclamation,
        icon = icons,
        title = "WARNING",
        text = "You have entered a wrong password!",
        ignore_suspend = true
    }
end)
