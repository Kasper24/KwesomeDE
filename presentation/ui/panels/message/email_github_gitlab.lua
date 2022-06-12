-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local beautiful = require("beautiful")
local email_daemon = require("daemons.web.email")
local github_daemon = require("daemons.web.github")
local gitlab_daemon = require("daemons.web.gitlab")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local collectgarbage = collectgarbage
local setmetatable = setmetatable
local tostring = tostring
local string = string
local ipairs = ipairs
local os = os

local email_github_gitlab = { mt = {} }

local function generate_action_string(event)
    local action_string = event.type
    local icon = "repo.svg"
    local link = "http://github.com/" .. event.repo.name

    if (event.type == "PullRequestEvent") then
        action_string = event.payload.action .. " a pull request in"
        link = event.pr_url
        icon = beautiful.code_pull_request_icon
    elseif (event.type == "PullRequestReviewCommentEvent") then
        action_string = event.payload.action == "created" and "commented in pull request" or event.payload.action .. " a comment in"
        link = event.pr_url
        icon = beautiful.message_icon
    elseif (event.type == "IssuesEvent") then
        action_string = event.payload.action .. " an issue in"
        link = event.issue_url
        icon = beautiful.circle_exclamation_icon
    elseif (event.type == "IssueCommentEvent") then
        action_string = event.payload.action == "created" and "commented in issue" or event.payload.action .. " a comment in"
        link = event.issue_url
        icon = beautiful.message_icon
    elseif (event.type == "WatchEvent") then
        action_string = "starred"
        icon = beautiful.star_icon
    elseif (event.type == "PushEvent") then
        action_string = "pushed to"
        icon = beautiful.commit_icon
    elseif (event.type == "ForkEvent") then
        action_string = "forked"
        icon = beautiful.code_branch_icon
    elseif (event.type == "CreateEvent") then
        action_string = "created"
        icon = beautiful.code_branch_icon
    end

    return { action_string = action_string, link = link, icon = icon }
end

local function widget()
    local spinning_circle = wibox.widget
    {
        widget = wibox.container.place,
        halign = "center",
        valign = "center",
        widgets.spinning_circle
        {
            forced_width = dpi(150),
            forced_height = dpi(150),
        }
    }

    local missing_credentials_text = wibox.widget
    {
        widget = wibox.container.place,
        halign = "center",
        valign = "center",
        widgets.text
        {
            halign = "center",
            size = 25,
            color = beautiful.colors.on_background,
            text = "Missing Credentials"
        }
    }

    local error_icon  wibox.widget
    {
        widget = wibox.container.place,
        halign = "center",
        valign = "center",
        widgets.text
        {
            halign = "center",
            size = 120,
            color = beautiful.random_accent_color(),
            font = beautiful.circle_exclamation_icon.font,
            text = beautiful.circle_exclamation_icon.icon
        }
    }

    local scrollbox = wibox.widget
    {
        layout = widgets.overflow.vertical,
        spacing = dpi(10),
        scrollbar_widget =
        {
            widget = wibox.widget.separator,
            shape = helpers.ui.rrect(beautiful.border_radius),
        },
        scrollbar_width = dpi(10),
        step = 50
    }

    return spinning_circle, missing_credentials_text, error_icon, scrollbox
end

local function email()
    local spinning_circle, _, error_icon, scrollbox = widget()

    local widget = wibox.widget
    {
        layout = wibox.layout.stack,
        top_only = true,
        spinning_circle,
        error_icon,
        scrollbox
    }

    email_daemon:connect_signal("error", function()
        spinning_circle.children[1]:abort()
        widget:raise_widget(error_icon)
    end)

    email_daemon:connect_signal("emails", function(self, emails)
        spinning_circle.children[1]:abort()
        scrollbox:reset()
        collectgarbage("collect")
        widget:raise_widget(scrollbox)

        for index, email in ipairs(emails) do
            local widget =  widgets.button.elevated.normal
            {
                constraint_height = dpi(500),
                halign = "left",
                on_release = function()
                    email_daemon:open(email)
                end,
                child = wibox.widget
                {
                    layout = wibox.layout.fixed.vertical,
                    spacing = dpi(5),
                    widgets.text
                    {
                        halign = "left",
                        size = 12,
                        text = "From: " .. email.author.name
                    },
                    widgets.text
                    {
                        halign = "left",
                        size = 12,
                        text = "Date: " .. email.modified
                    },
                    widgets.text
                    {
                        halign = "left",
                        size = 12,
                        text = "Subject: " .. tostring(email.title)
                    },
                    widgets.text
                    {
                        halign = "left",
                        size = 12,
                        text = "Summary: " .. tostring(email.summary)
                    }
                }
            }
            scrollbox:add(widget)

            -- Make it scroll all the way down
            if index == #emails then
                scrollbox:add(widgets.spacer.vertical(20))
            end
        end
    end)

    return widget
end

local function github_activity()
    local spinning_circle, missing_credentials_text, error_icon, scrollbox = widget()

    local widget = wibox.widget
    {
        layout = wibox.layout.stack,
        top_only = true,
        spinning_circle,
        missing_credentials_text,
        error_icon,
        scrollbox
    }

    github_daemon:connect_signal("events::error", function()
        spinning_circle.children[1]:abort()
        widget:raise_widget(error_icon)
    end)

    github_daemon:connect_signal("missing_credentials", function()
        spinning_circle.children[1]:abort()
        widget:raise_widget(missing_credentials_text)
    end)

    github_daemon:connect_signal("events", function(self, events, path_to_avatars)
        spinning_circle.children[1]:abort()
        scrollbox:reset()
        collectgarbage("collect")
        widget:raise_widget(scrollbox)

        for index, event in ipairs(events) do
            local action_and_link = generate_action_string(event)

            local avatar = widgets.button.elevated.normal
            {
                child =
                {
                    widget = wibox.widget.imagebox,
                    forced_width = dpi(40),
                    forced_height = dpi(40),
                    clip_shape = helpers.ui.rrect(beautiful.border_radius),
                    image = path_to_avatars .. event.actor.id,
                },
                on_release = function()
                    awful.spawn("xdg-open http://github.com/" .. event.actor.login, false)
                end
            }

            local user_action_repo = wibox.widget
            {
                widget = wibox.widget.textbox,
                align = "left",
                markup = "<b>" .. event.actor.display_login .. "</b> " ..
                    action_and_link.action_string ..
                    " <b>" .. event.repo.name .. "</b>"
            }

            local icon = widgets.text
            {
                font = action_and_link.icon.font,
                size = 15,
                color = beautiful.random_accent_color(),
                text = action_and_link.icon.icon
            }

            local time = widgets.text
            {
                size = 12,
                text = helpers.string.to_time_ago(os.difftime(os.time(os.date("!*t")), helpers.string.parse_date(event.created_at))),
            }

            local info = widgets.button.elevated.normal
            {
                halign = "left",
                on_release = function()
                    awful.spawn("xdg-open " .. action_and_link.link, false)
                end,
                child =
                {
                    layout = wibox.layout.fixed.vertical,
                    forced_width = dpi(1000),
                    user_action_repo,
                    {
                        layout = wibox.layout.fixed.horizontal,
                        spacing = dpi(10),
                        icon,
                        time
                    },
                },
            }

            local widget = wibox.widget
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(5),
                avatar,
                info
            }

            scrollbox:add(widget)

            -- Make it scroll all the way down
            if index == #events then
                scrollbox:add(widgets.spacer.vertical(20))
            end

        end
    end)

    return widget
end

local function github_pr()
    local spinning_circle, missing_credentials_text, error_icon, scrollbox = widget()

    local widget = wibox.widget
    {
        layout = wibox.layout.stack,
        top_only = true,
        spinning_circle,
        missing_credentials_text,
        error_icon,
        scrollbox
    }

    github_daemon:connect_signal("prs::error", function()
        spinning_circle.children[1]:abort()
        widget:raise_widget(error_icon)
    end)

    github_daemon:connect_signal("missing_credentials", function()
        spinning_circle.children[1]:abort()
        widget:raise_widget(missing_credentials_text)
    end)

    github_daemon:connect_signal("prs", function(self, prs, path_to_avatars)
        spinning_circle.children[1]:abort()
        scrollbox:reset()
        collectgarbage("collect")
        widget:raise_widget(scrollbox)

        for index, pr in ipairs(prs) do
            local avatar = widgets.button.elevated.normal
            {
                on_release = function()
                    awful.spawn("xdg-open " .. pr.user.html_url, false)
                end,
                child =
                {
                    widget = wibox.widget.imagebox,
                    forced_width = dpi(50),
                    forced_height = dpi(50),
                    clip_shape = helpers.ui.rrect(beautiful.border_radius),
                    image = path_to_avatars .. pr.user.id,
                }
            }

            local button = widgets.button.elevated.normal
            {
                on_release = function()
                    awful.spawn("xdg-open " .. pr.html_url, false)
                end,
                child = wibox.widget
                {
                    layout = wibox.layout.fixed.horizontal,
                    {
                        layout = wibox.layout.fixed.vertical,
                        spacing = dpi(3),
                        forced_width = dpi(1000),
                        forced_height = dpi(65),
                        {
                            layout = wibox.layout.fixed.horizontal,
                            spacing = dpi(10),
                            widgets.text
                            {
                                size = 12,
                                bold = true,
                                text = string.sub(pr.repository_url, string.find(pr.repository_url, "/[^/]*$") + 1) .. " |",
                            },
                            widgets.text
                            {
                                size = 12,
                                text = pr.title,
                            },
                        },
                        widgets.text
                        {
                            size = 12,
                            text =  "#" .. pr.number .. " opened " ..
                                    helpers.string.to_time_ago(os.difftime(os.time(os.date("!*t")), helpers.string.parse_date(pr.created_at))) ..
                                    " by " .. pr.user.login,
                        },
                        {
                            layout = wibox.layout.fixed.horizontal,
                            spacing = dpi(10),
                            widgets.text
                            {
                                font = beautiful.message_icon.font,
                                size = 15,
                                color = beautiful.random_accent_color(),
                                text = beautiful.message_icon.icon
                            },
                            widgets.text
                            {
                                size = 12,
                                text = pr.comments,
                            }
                        }
                    }
                }
            }

            local widget = wibox.widget
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(5),
                avatar,
                button
            }

            scrollbox:add(widget)

            -- Make it scroll all the way down
            if index == #prs then
                scrollbox:add(widgets.spacer.vertical(20))
            end
        end
    end)

    return widget
end

local function github()
    local accent_color = beautiful.random_accent_color()

    local activity = github_activity()
    local pr = github_pr()

    local content = wibox.widget
    {
        layout = wibox.layout.stack,
        top_only = true,
        activity,
        pr
    }

    local activity_button = nil
    local pr_button = nil

    activity_button = widgets.button.text.state
    {
        on_by_default = true,
        size = 15,
        on_normal_bg = accent_color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        text = "Activity",
        animate_size = false,
        on_release = function()
            activity_button:turn_on()
            pr_button:turn_off()
            content:raise_widget(activity)
        end
    }

    pr_button = widgets.button.text.state
    {
        size = 15,
        on_normal_bg = accent_color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        text = "PR",
        animate_size = false,
        on_release = function()
            activity_button:turn_off()
            pr_button:turn_on()
            content:raise_widget(pr)
        end
    }

    return wibox.widget
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(10),
        {
            layout = wibox.layout.flex.horizontal,
            spacing = dpi(10),
            activity_button,
            pr_button
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

local function gitlab()
    local spinning_circle, missing_credentials_text, error_icon, scrollbox = widget()

    local widget = wibox.widget
    {
        layout = wibox.layout.stack,
        top_only = true,
        spinning_circle,
        missing_credentials_text,
        error_icon,
        scrollbox
    }

    gitlab_daemon:connect_signal("error", function()
        spinning_circle.children[1]:abort()
        widget:raise_widget(error_icon)
    end)

    gitlab_daemon:connect_signal("missing_credentials", function()
        spinning_circle.children[1]:abort()
        widget:raise_widget(missing_credentials_text)
    end)

    gitlab_daemon:connect_signal("update", function(self, prs, path_to_avatars)
        spinning_circle.children[1]:abort()
        scrollbox:reset()
        collectgarbage("collect")
        widget:raise_widget(scrollbox)

        for index, pr in ipairs(prs) do
            local avatar = widgets.button.elevated.normal
            {
                forced_width = dpi(60),
                forced_height = dpi(60),
                on_release = function()
                    awful.spawn("xdg-open " .. pr.author.web_url, false)
                end,
                child = wibox.widget
                {
                    widget = wibox.widget.imagebox,
                    clip_shape = helpers.ui.rrect(beautiful.border_radius),
                    image = path_to_avatars .. pr.author.id,
                },
            }

            local title = widgets.text
            {
                size = 12,
                bold = true,
                text = pr.title,
            }

            local from_branch_to_branch = widgets.text
            {
                size = 12,
                text = pr.source_branch .. " -> " .. pr.target_branch
            }

            local name_time = wibox.widget
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(10),
                widgets.text
                {
                    size = 12,
                    text = pr.author.name
                },
                widgets.text
                {
                    size = 12,
                    text = helpers.string.to_time_ago(os.difftime(os.time(os.date("!*t")), helpers.string.parse_date(pr.created_at)))
                }
            }

            local approves = wibox.widget
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(10),
                widgets.text
                {
                    font = beautiful.check_icon.font,
                    size = 15,
                    color = beautiful.random_accent_color(),
                    text = beautiful.check_icon.icon
                },
                widgets.text
                {
                    size = 12,
                    text = pr.upvotes,
                }
            }

            local comments = wibox.widget
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(10),
                widgets.text
                {
                    font = beautiful.message_icon.font,
                    size = 15,
                    color = beautiful.random_accent_color(),
                    text = beautiful.message_icon.icon
                },
                widgets.text
                {
                    size = 12,
                    text = pr.user_notes_count
                }
            }

            local button = widgets.button.elevated.normal
            {
                on_release = function()
                    awful.spawn("xdg-open " .. pr.web_url, false)
                end,
                child = wibox.widget
                {
                    layout = wibox.layout.fixed.horizontal,
                    {
                        layout = wibox.layout.flex.vertical,
                        forced_width = dpi(360),
                        title,
                        from_branch_to_branch,
                        name_time
                    },
                    {
                        layout = wibox.layout.flex.vertical,
                        approves,
                        comments
                    }
                }
            }

            local widget = wibox.widget
            {
                layout = wibox.layout.fixed.horizontal,
                forced_width = dpi(1000),
                spacing = dpi(5),
                avatar,
                button
            }

            scrollbox:add(widget)

            -- Make it scroll all the way down
            if index == #prs then
                scrollbox:add(widgets.spacer.vertical(20))
            end
        end
    end)

    return widget
end

local function new()
    local accent_color = beautiful.random_accent_color()

    local email = email()
    local github = github()
    local gitlab = gitlab()

    local content = wibox.widget
    {
        layout = wibox.layout.stack,
        top_only = true,
        email,
        github,
        gitlab
    }

    local email_button = nil
    local github_button = nil
    local gitlab_button = nil

    email_button = widgets.button.text.state
    {
        on_by_default = true,
        size = 15,
        on_normal_bg = accent_color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        text = "Email",
        animate_size = false,
        on_release = function()
            email_button:turn_on()
            github_button:turn_off()
            gitlab_button:turn_off()
            content:raise_widget(email)
        end
    }

    github_button = widgets.button.text.state
    {
        size = 15,
        on_normal_bg = accent_color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        text = "Github",
        animate_size = false,
        on_release = function()
            email_button:turn_off()
            github_button:turn_on()
            gitlab_button:turn_off()
            content:raise_widget(github)
        end
    }

    gitlab_button = widgets.button.text.state
    {
        size = 15,
        on_normal_bg = accent_color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        text = "Gitlab",
        animate_size = false,
        on_release = function()
            email_button:turn_off()
            github_button:turn_off()
            gitlab_button:turn_on()
            content:raise_widget(gitlab)
        end
    }

    return wibox.widget
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(10),
        {
            layout = wibox.layout.flex.horizontal,
            spacing = dpi(10),
            email_button,
            github_button,
            gitlab_button
        },
        content
    }
end

function email_github_gitlab.mt:__call()
    return new()
end

return setmetatable(email_github_gitlab, email_github_gitlab.mt)