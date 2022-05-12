local naughty = require("naughty")
local gitlab_daemon = require("daemons.web.gitlab")

local icons =
{
    "gitlab",
    "com.github.zren.gitlabissues",
    "gitlab-tray",
    "folder-gitlab",
    "io.gitlab.osslugaru.Lugaru",
    "com.gitlab.davem.ClamTk",
    "mailer",
    "preferences-mail.svg",
    "kmail"
}

gitlab_daemon:connect_signal("new_pr", function(self, pr)
    naughty.notification
    {
        app_icon = icons,
        app_name = "Gitlab",
        icon = icons,
        title = "New PR",
        text = pr.title,
        category = "email.arrived"
    }
end)