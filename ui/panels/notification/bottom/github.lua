-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local github_daemon = require("daemons.web.github")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local collectgarbage = collectgarbage
local setmetatable = setmetatable
local string = string
local ipairs = ipairs
local os = os

local github = {
    mt = {}
}

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

local function widget()
    local spinning_circle = wibox.widget {
        widget = wibox.container.place,
        halign = "center",
        valign = "center",
        widgets.spinning_circle {
            forced_width = dpi(150),
            forced_height = dpi(150)
        }
    }

    local missing_credentials_text = wibox.widget {
        widget = wibox.container.place,
        halign = "center",
        valign = "center",
        {
            widget = widgets.text,
            halign = "center",
            size = 25,
            color = beautiful.colors.on_background,
            text = "Missing Credentials"
        }
    }

    local error_icon = wibox.widget {
        widget = wibox.container.place,
        halign = "center",
        valign = "center",
        {
            widget = widgets.text,
            halign = "center",
            icon = beautiful.icons.circle_exclamation,
            size = 120
        }
    }

    local scrollbox = wibox.widget {
        layout = widgets.overflow.vertical,
        spacing = dpi(10),
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(10),
        step = 50
    }

    return spinning_circle, missing_credentials_text, error_icon, scrollbox
end

local function event_widget(event, path_to_avatars)
    local action_and_link = generate_action_string(event)

    local avatar = wibox.widget {
        widget = widgets.button.elevated.normal,
        child = {
            widget = wibox.widget.imagebox,
            forced_width = dpi(40),
            forced_height = dpi(40),
            clip_shape = helpers.ui.rrect(),
            image = path_to_avatars .. event.actor.id
        },
        on_release = function()
            awful.spawn("xdg-open http://github.com/" .. event.actor.login, false)
        end
    }

    local user = wibox.widget {
        widget = widgets.text,
        halign = "left",
        bold = true,
        size = 12,
        text = event.actor.display_login .. " "
    }

    local action = wibox.widget {
        widget = widgets.text,
        halign = "left",
        size = 12,
        text =  action_and_link.action_string .. " "
    }

    local repo = wibox.widget {
        widget = widgets.text,
        halign = "left",
        bold = true,
        size = 12,
        text = event.repo.name .. " "
    }

    local icon = wibox.widget {
        widget = widgets.text,
        icon = action_and_link.icon,
        size = 15
    }

    local time = wibox.widget {
        widget = widgets.text,
        size = 12,
        text = helpers.string.to_time_ago(os.difftime(os.time(os.date("!*t")),
            helpers.string.parse_date(event.created_at)))
    }

    local info = wibox.widget {
        widget = widgets.button.elevated.normal,
        halign = "right",
        on_release = function()
            awful.spawn("xdg-open " .. action_and_link.link, false)
        end,
        child = {
            layout = wibox.layout.fixed.vertical,
            {
                layout = wibox.layout.fixed.horizontal,
                user,
                action,
                repo
            },
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(10),
                icon,
                time
            }
        }
    }

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_width = dpi(600),
        spacing = dpi(5),
        avatar,
        info
    }
end

local function events()
    local spinning_circle, missing_credentials_text, error_icon, scrollbox = widget()

    local widget = wibox.widget {
        layout = wibox.layout.stack,
        top_only = true,
        spinning_circle,
        missing_credentials_text,
        error_icon,
        scrollbox
    }

    github_daemon:connect_signal("events::error", function()
        spinning_circle.children[1]:stop()
        widget:raise_widget(error_icon)
    end)

    github_daemon:connect_signal("missing_credentials", function()
        spinning_circle.children[1]:stop()
        widget:raise_widget(missing_credentials_text)
    end)

    github_daemon:connect_signal("events", function(self, events, path_to_avatars)
        spinning_circle.children[1]:stop()
        scrollbox:reset()
        collectgarbage("collect")
        widget:raise_widget(scrollbox)

        for _, event in ipairs(events) do
            scrollbox:add(event_widget(event, path_to_avatars))
        end
    end)

    return widget
end

local function pr_widget(pr, path_to_avatars)
    local avatar = wibox.widget {
        widget = widgets.button.elevated.normal,
        on_release = function()
            awful.spawn("xdg-open " .. pr.user.html_url, false)
        end,
        child = {
            widget = wibox.widget.imagebox,
            forced_width = dpi(40),
            forced_height = dpi(40),
            clip_shape = helpers.ui.rrect(),
            image = path_to_avatars .. pr.user.id
        }
    }

    local repo = string.sub(pr.repository_url, string.find(pr.repository_url, "/[^/]*$") + 1)
    local title = " - #" .. pr.number .. " " .. pr.title
    local repo_and_title = wibox.widget {
        widget = widgets.text,
        forced_width = dpi(600),
        forced_height = dpi(15),
        size = 12,
        bold = true,
        text = repo .. title
    }

    local time = wibox.widget {
        widget = widgets.text,
        size = 12,
        text = helpers.string .to_time_ago(os.difftime(os.time(os.date("!*t")),
                helpers.string.parse_date(pr.created_at)))
    }

    local comments = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(10),
        {
            widget = widgets.text,
            icon = beautiful.icons.message,
            size = 15
        },
        {
            widget = widgets.text,
            size = 12,
            text = pr.comments
        }
    }

    local button = wibox.widget {
        widget = widgets.button.elevated.normal,
        haling = "left",
        on_release = function()
            awful.spawn("xdg-open " .. pr.html_url, false)
        end,
        child = wibox.widget {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(5),
            repo_and_title,
            time,
            comments
        }
    }

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_height = dpi(90),
        spacing = dpi(3),
        avatar,
        button
    }
end

local function prs()
    local spinning_circle, missing_credentials_text, error_icon, scrollbox = widget()

    local widget = wibox.widget {
        layout = wibox.layout.stack,
        top_only = true,
        spinning_circle,
        missing_credentials_text,
        error_icon,
        scrollbox
    }

    github_daemon:connect_signal("prs::error", function()
        spinning_circle.children[1]:stop()
        widget:raise_widget(error_icon)
    end)

    github_daemon:connect_signal("missing_credentials", function()
        spinning_circle.children[1]:stop()
        widget:raise_widget(missing_credentials_text)
    end)

    github_daemon:connect_signal("prs", function(self, prs, path_to_avatars)
        spinning_circle.children[1]:stop()
        scrollbox:reset()
        collectgarbage("collect")
        widget:raise_widget(scrollbox)

        for _, pr in ipairs(prs) do
            scrollbox:add(pr_widget(pr, path_to_avatars))
        end
    end)

    return widget
end

local function new()
    local accent_color = beautiful.colors.random_accent_color()

    local events = events()
    local prs = prs()

    local content = wibox.widget {
        layout = wibox.layout.stack,
        top_only = true,
        events,
        prs
    }

    local events_button = nil
    local prs_button = nil

    events_button = wibox.widget {
        widget = widgets.button.text.state,
        on_by_default = true,
        size = 15,
        on_normal_bg = accent_color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        text = "Activity",
        on_release = function()
            events_button:turn_on()
            prs_button:turn_off()
            content:raise_widget(events)
        end
    }

    prs_button = wibox.widget {
        widget = widgets.button.text.state,
        size = 15,
        on_normal_bg = accent_color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        text = "PR",
        on_release = function()
            events_button:turn_off()
            prs_button:turn_on()
            content:raise_widget(prs)
        end
    }

    return wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(10),
        {
            layout = wibox.layout.flex.horizontal,
            spacing = dpi(10),
            events_button,
            prs_button
        },
        {
            widget = wibox.container.place,
            forced_height = dpi(700),
            halign = "center",
            valign = "center",
            content
        }
    }
end

function github.mt:__call()
    return new()
end

return setmetatable(github, github.mt)
