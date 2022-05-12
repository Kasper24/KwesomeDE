local naughty = require("naughty")
local system_daemon = require("daemons.system.system")

local icons =
{
    "password",
    "passwords",
    "preferences-desktop-user-password",
    "1password",
    "password-manager",
    "com.bixense.PasswordCalculator",
    "kali-password-attacks-trans.svg",
    "dialog-password"
}

system_daemon:connect_signal("wrong_password", function(self)
    naughty.notification
    {
        app_icon = icons,
        app_name = "Security",
        icon = icons,
        title = "WARNING",
        text = "You have entered a wrong password!",
        ignore_suspend = true
    }
end)