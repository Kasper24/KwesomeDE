-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local beautiful = require("beautiful")
local naughty = require("naughty")
local gitlab_daemon = require("daemons.web.gitlab")

local icons = {"gitlab", "com.github.zren.gitlabissues", "gitlab-tray", "folder-gitlab", "io.gitlab.osslugaru.Lugaru",
               "com.gitlab.davem.ClamTk", "mailer", "preferences-mail.svg", "kmail"}

gitlab_daemon:connect_signal("new_mr", function(self, mr)
    local open = naughty.action {
        name = "Open"
    }

    open:connect_signal("invoked", function()
        awful.spawn("xdg-open " .. mr.web_url, false)
    end)

    naughty.notification {
        app_font_icon = beautiful.icons.gitlab,
        app_icon = icons,
        app_name = "Gitlab",
        font_icon = beautiful.icons.code_branch,
        icon = icons,
        title = mr.title,
        text = mr.description,
        category = "email.arrived",
        actions = { open }
    }
end)
