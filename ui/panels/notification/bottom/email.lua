-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local email_daemon = require("daemons.web.email")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local collectgarbage = collectgarbage
local setmetatable = setmetatable
local tostring = tostring
local ipairs = ipairs

local email = {
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
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(10),
        step = 50
    }

    return spinning_circle, missing_credentials_text, error_icon, scrollbox
end

local function new()
    local spinning_circle, _, error_icon, scrollbox = widget()

    local widget = wibox.widget {
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
            local widget = wibox.widget {
                widget = wibox.container.constraint,
                height = dpi(500),
                {
                    widget = wibox.container.place,
                    halign = "left",
                    {
                        widget = widgets.button.elevated.normal,
                        on_release = function()
                            email_daemon:open(email)
                        end,
                        child = wibox.widget {
                            layout = wibox.layout.fixed.vertical,
                            spacing = dpi(5),
                            {
                                widget = widgets.text,
                                halign = "left",
                                size = 12,
                                text = "From: " .. email.author.name
                            },
                            {
                                widget = widgets.text,
                                halign = "left",
                                size = 12,
                                text = "Date: " .. email.modified
                            },
                            {
                                widget = widgets.text,
                                halign = "left",
                                size = 12,
                                text = "Subject: " .. tostring(email.title)
                            },
                            {
                                widget = widgets.text,
                                halign = "left",
                                size = 12,
                                text = "Summary: " .. tostring(email.summary)
                            }
                        }
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

function email.mt:__call()
    return new()
end

return setmetatable(email, email.mt)
