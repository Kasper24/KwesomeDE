-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local gitlab_daemon = require("daemons.web.gitlab")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local collectgarbage = collectgarbage
local setmetatable = setmetatable
local ipairs = ipairs
local os = os

local gitlab = {
    mt = {}
}

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

    local error_icon
    wibox.widget {
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
        scrollbar_widget = {
            widget = wibox.widget.separator,
            shape = helpers.ui.rrect(beautiful.border_radius)
        },
        scrollbar_width = dpi(10),
        step = 50
    }

    return spinning_circle, missing_credentials_text, error_icon, scrollbox
end

local function new()
    local spinning_circle, missing_credentials_text, error_icon, scrollbox = widget()

    local widget = wibox.widget {
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
            local avatar = wibox.widget {
                widget = widgets.button.elevated.normal,
                forced_width = dpi(60),
                forced_height = dpi(60),
                on_release = function()
                    awful.spawn("xdg-open " .. pr.author.web_url, false)
                end,
                child = wibox.widget {
                    widget = wibox.widget.imagebox,
                    clip_shape = helpers.ui.rrect(beautiful.border_radius),
                    image = path_to_avatars .. pr.author.id
                }
            }

            local title = wibox.widget {
                widget = widgets.text,
                size = 12,
                bold = true,
                text = pr.title
            }

            local from_branch_to_branch = wibox.widget {
                widget = widgets.text,
                size = 12,
                text = pr.source_branch .. " -> " .. pr.target_branch
            }

            local name_time = wibox.widget {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(10),
                {
                    widget = widgets.text,
                    size = 12,
                    text = pr.author.name
                },
                {
                    widget = widgets.text,
                    size = 12,
                    text = helpers.string.to_time_ago(os.difftime(os.time(os.date("!*t")),
                        helpers.string.parse_date(pr.created_at)))
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
                    text = pr.upvotes
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
                    text = pr.user_notes_count
                }
            }

            local button = wibox.widget {
                widget = widgets.button.elevated.normal,
                on_release = function()
                    awful.spawn("xdg-open " .. pr.web_url, false)
                end,
                child = wibox.widget {
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

            local widget = wibox.widget {
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

function gitlab.mt:__call()
    return new()
end

return setmetatable(gitlab, gitlab.mt)