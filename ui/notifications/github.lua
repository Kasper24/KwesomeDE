-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local beautiful = require("beautiful")
local naughty = require("naughty")
local github_daemon = require("daemons.web.github")

local icons = {"github", "appimagekit-github-desktop", "io.github.shiftey.Desktop", "folder-github", "folder-Github"}

github_daemon:connect_signal("new_event", function(self, event)
    local action_and_link = github_daemon:get_event_info(event)

    local open = naughty.action {
        name = "Open"
    }

    open:connect_signal("invoked", function()
        awful.spawn("xdg-open " .. action_and_link.link, false)
    end)

    naughty.notification {
        app_font_icon = beautiful.icons.github,
        app_icon = icons,
        app_name = "Github",
        icon = github_daemon:get_events_avatars_path() .. event.actor.id,
        title = action_and_link.icon,
        text = event.actor.display_login .. " " .. action_and_link.action_string .. " " .. event.repo.name,
        category = "email.arrived",
        actions = { open }
    }
end)

github_daemon:connect_signal("new_pr", function(self, pr)
    local open = naughty.action {
        name = "Open"
    }

    open:connect_signal("invoked", function()
        awful.spawn("xdg-open " .. pr.html_url, false)
    end)

    naughty.notification {
        app_font_icon = beautiful.icons.github,
        app_icon = icons,
        app_name = "Github",
        font_icon = beautiful.icons.code_branch,
        icon = icons,
        title = pr.title,
        text = pr.body,
        category = "email.arrived",
        actions = { open }
    }
end)
