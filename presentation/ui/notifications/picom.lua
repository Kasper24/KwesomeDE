local naughty = require("naughty")
local picom_daemon = require("daemons.system.picom")
local helpers = require("helpers")

local icons =
{
    "picom",
    "accessories-painting",
    "applications-painting",
    "azpainter",
    "com.github.wjaguar.mtpaint",
    "gnome-paint",
    "gpaint",
    "kolourpaint",
    "lazpaint",
    "mtpaint",
    "mypaint",
    "org.mypaint.MyPaint",
    "org.tuxpaint.Tuxpaint",
    "tuxpaint"
}

picom_daemon:connect_signal("state", function(self, state)
    if helpers.misc.should_show_notification() == true then
        local text = state == true and "Enabled" or "Disabled"

        naughty.notification
        {
            app_icon = icons,
            app_name = "Picom",
            icon = icons,
            title = "Picom",
            text = text
        }
    end
end)