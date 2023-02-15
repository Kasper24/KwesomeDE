-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local beautiful = require("beautiful")
local naughty = require("naughty")
local github_daemon = require("daemons.web.github")

local icons = {"github", "appimagekit-github-desktop", "io.github.shiftey.Desktop", "folder-github", "folder-Github"}

local function generate_action_string(event)
    local action_string = event.type
    local icon = "repo.svg"
    local link = "http://github.com/" .. event.repo.name

    if (event.type == "PullRequestEvent") then
        action_string = event.payload.action .. " a pull request in"
        link = event.payload.pull_request.html_url
        icon = beautiful.icons.code_pull_request
    elseif (event.type == "PullRequestReviewCommentEvent") then
        action_string = event.payload.action == "created" and "commented in pull request" or event.payload.action ..
                            " a comment in"
        link = event.payload.pull_request.html_url
        icon = beautiful.icons.message
    elseif (event.type == "IssuesEvent") then
        action_string = event.payload.action .. " an issue in"
        link = event.payload.issue.html_url
        icon = beautiful.icons.circle_exclamation
    elseif (event.type == "IssueCommentEvent") then
        action_string = event.payload.action == "created" and "commented in issue" or event.payload.action ..
                            " a comment in"
        link = event.payload.issue.html_url
        icon = beautiful.icons.message
    elseif (event.type == "WatchEvent") then
        action_string = "starred"
        icon = beautiful.icons.star
    elseif (event.type == "PushEvent") then
        action_string = "pushed to"
        icon = beautiful.icons.commit
    elseif (event.type == "ForkEvent") then
        action_string = "forked"
        icon = beautiful.icons.code_branch
    elseif (event.type == "CreateEvent") then
        action_string = "created"
        icon = beautiful.icons.code_branch
    end

    return {
        action_string = action_string,
        link = link,
        icon = icon
    }
end

github_daemon:connect_signal("new_event", function(self, event, avatar_path)
    local action_and_link = generate_action_string(event)

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
        icon = avatar_path,
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
        font_icon = beautiful.icons.envelope,
        icon = icons,
        title = pr.title,
        text = pr.body,
        category = "email.arrived",
        actions = { open }
    }
end)
