-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gshape = require("gears.shape")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local gitlab_daemon = require("daemons.web.gitlab")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable
local ipairs = ipairs

local gitlab = {
    mt = {}
}

local function mr_widget(mr)
    local avatar = wibox.widget {
        widget = widgets.button.elevated.normal,
        normal_shape = gshape.circle,
        forced_width = dpi(60),
        forced_height = dpi(60),
        on_release = function()
            awful.spawn("xdg-open " .. mr.author.web_url, false)
        end,
        {
            widget = wibox.widget.imagebox,
            clip_shape = helpers.ui.rrect(),
            image = gitlab_daemon:get_avatars_path() .. mr.author.id
        }
    }

    local title = wibox.widget {
        widget = widgets.text,
        size = 12,
        bold = true,
        text = mr.title
    }

    local from_branch_to_branch = wibox.widget {
        widget = widgets.text,
        size = 12,
        text = mr.source_branch .. " -> " .. mr.target_branch
    }

    local name_time = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(10),
        {
            widget = widgets.text,
            size = 12,
            text = mr.author.name
        },
        {
            widget = widgets.text,
            size = 12,
            text = helpers.string.to_time_ago(mr.created_at)
        }
    }

    local approves = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(10),
        {
            widget = widgets.text,
            icon = beautiful.icons.check,
            size = 15
        },
        {
            widget = widgets.text,
            size = 12,
            text = mr.upvotes
        }
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
            text = mr.user_notes_count
        }
    }

    local button = wibox.widget {
        widget = widgets.button.elevated.normal,
        on_release = function()
            awful.spawn("xdg-open " .. mr.web_url, false)
        end,
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

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_width = dpi(1000),
        spacing = dpi(5),
        avatar,
        button
    }
end

local function new()
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

    local widget = wibox.widget {
        layout = wibox.layout.stack,
        top_only = true,
        spinning_circle,
        missing_credentials_text,
        error_icon,
        scrollbox
    }

    gitlab_daemon:connect_signal("error", function()
        spinning_circle:stop()
        widget:raise_widget(error_icon)
    end)

    gitlab_daemon:connect_signal("missing_credentials", function()
        spinning_circle:stop()
        widget:raise_widget(missing_credentials_text)
    end)

    gitlab_daemon:connect_signal("mrs", function(self, mrs)
        spinning_circle:stop()
        for _, mr in ipairs(mrs) do
            scrollbox:add(mr_widget(mr))
        end
        widget:raise_widget(scrollbox)
    end)

    gitlab_daemon:connect_signal("new_mr", function(self, mr)
        scrollbox:insert(1, mr_widget(mr))
        widget:raise_widget(scrollbox)
        spinning_circle:stop()
    end)

    return widget
end

function gitlab.mt:__call()
    return new()
end

return setmetatable(gitlab, gitlab.mt)
