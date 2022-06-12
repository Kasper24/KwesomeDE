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

local function generate_action_string(event)
    if (event.type == "PullRequestEvent") then
        return event.payload.action .. " a pull request in"
    elseif (event.type == "PullRequestReviewCommentEvent") then
        return event.payload.action == "created" and "commented in pull request" or event.payload.action .. " a comment in"
    elseif (event.type == "IssuesEvent") then
        return event.payload.action .. " an issue in"
    elseif (event.type == "IssueCommentEvent") then
        return event.payload.action == "created" and "commented in issue" or event.payload.action .. " a comment in"
    elseif (event.type == "WatchEvent") then
        return "starred"
    elseif (event.type == "PushEvent") then
        return "pushed to"
    elseif (event.type == "ForkEvent") then
        return "forked"
    elseif (event.type == "CreateEvent") then
        return "created"
    end
end

github_daemon:connect_signal("new_event", function(self, event, avatar_path)
    naughty.notification
    {
        app_font_icon = beautiful.github_icon,
        app_icon = icons,
        app_name = "Github",
        icon = avatar_path,
        title = "New Event",
        text = event.actor.display_login  .. generate_action_string(event) .. event.repo.name,
        category = "email.arrived"
    }
end)

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