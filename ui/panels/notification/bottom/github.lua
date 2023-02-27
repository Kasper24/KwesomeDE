-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gshape = require("gears.shape")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local github_daemon = require("daemons.web.github")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable
local string = string
local ipairs = ipairs

local github = {
    mt = {}
}

local function widget()
    local spinning_circle = widgets.spinning_circle {
        forced_width = dpi(150),
        forced_height = dpi(600)
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

local function event_widget(event)
    local action_and_link = github_daemon:get_event_info(event)

    local avatar = wibox.widget {
        widget = widgets.button.elevated.normal,
        normal_shape = gshape.circle,
        {
            widget = wibox.widget.imagebox,
            forced_width = dpi(40),
            forced_height = dpi(40),
            clip_shape = helpers.ui.rrect(),
            image = github_daemon:get_events_avatars_path() .. event.actor.id
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
        text = helpers.string.to_time_ago(event.created_at)
    }

    local info = wibox.widget {
        widget = widgets.button.elevated.normal,
        halign = "right",
        on_release = function()
            awful.spawn("xdg-open " .. action_and_link.link, false)
        end,
        {
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
        spinning_circle:stop()
        widget:raise_widget(error_icon)
    end)

    github_daemon:connect_signal("missing_credentials", function()
        spinning_circle:stop()
        widget:raise_widget(missing_credentials_text)
    end)

    github_daemon:connect_signal("events", function(self, events)
        spinning_circle:stop()
        for _, event in ipairs(events) do
            scrollbox:add(event_widget(event))
        end
        widget:raise_widget(scrollbox)
    end)

    github_daemon:connect_signal("new_event", function(self, event)
        scrollbox:insert(1, event_widget(event))
        widget:raise_widget(scrollbox)
        spinning_circle:stop()
    end)

    return widget
end

local function pr_widget(pr)
    local avatar = wibox.widget {
        widget = widgets.button.elevated.normal,
        normal_shape = gshape.circle,
        on_release = function()
            awful.spawn("xdg-open " .. pr.user.html_url, false)
        end,
        {
            widget = wibox.widget.imagebox,
            forced_width = dpi(40),
            forced_height = dpi(40),
            clip_shape = helpers.ui.rrect(),
            image = github_daemon:get_prs_avatars_path() .. pr.user.id
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
        text = helpers.string .to_time_ago(pr.created_at)
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
        {
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
        spinning_circle:stop()
        widget:raise_widget(error_icon)
    end)

    github_daemon:connect_signal("missing_credentials", function()
        spinning_circle:stop()
        widget:raise_widget(missing_credentials_text)
    end)

    github_daemon:connect_signal("prs", function(self, prs)
        spinning_circle:stop()
        for _, pr in ipairs(prs) do
            scrollbox:add(pr_widget(pr))
        end
        widget:raise_widget(scrollbox)
    end)

    github_daemon:connect_signal("new_pr", function(self, pr)
        scrollbox:insert(1, pr_widget(pr))
        widget:raise_widget(scrollbox)
        spinning_circle:stop()
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
