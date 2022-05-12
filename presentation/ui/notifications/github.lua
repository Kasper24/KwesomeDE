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
        app_icon = icons,
        app_name = "Github",
        icon = icons,
        title = "New PR",
        text = pr.title,
        category = "email.arrived"
    }
end)