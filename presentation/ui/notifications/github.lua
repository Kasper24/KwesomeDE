-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local beautiful = require("beautiful")
local naughty = require("naughty")
local github_daemon = require("daemons.web.github")

local icons =
{
    "github",
    "appimagekit-github-desktop",
    "io.github.shiftey.Desktop",
    "folder-github",
    "folder-Github",
}

github_daemon:connect_signal("new_pr", function(self, pr)
    naughty.notification
    {
        app_font_icon = beautiful.github_icon,
        app_icon = icons,
        app_name = "Github",
        font_icon = beautiful.envelope_icon,
        icon = icons,
        title = "New PR",
        text = pr.title,
        category = "email.arrived"
    }
end)