-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local beautiful = require("beautiful")
local naughty = require("naughty")
local email_daemon = require("daemons.web.email")
local type = type

local icons = {"mail-notification", "email", "e-mail", "mail-generic", "mailer", "preferences-mail", "kmail",
               "redhat-email", "email-client", "applications-email-panel", "package_internet_email",
               "ximian-evolution-email", "redhat-email", "bubblemail", "bubblmail", "bluemail"}

email_daemon:connect_signal("new_email", function(self, email)
    local title = ""
    local text = ""
    if type(email.summary) == "string" then
        title = email.title
        text = email.summary
    else
        title = "New Email"
        text = email.title
    end

    naughty.notification
    {
        app_font_icon = beautiful.icons.envelope,
        app_icon = icons,
        app_name = "Email",
        font_icon = beautiful.icons.envelope,
        icon = icons,
        title = title,
        text = text,
        category = "email.arrived"
    }
end)
