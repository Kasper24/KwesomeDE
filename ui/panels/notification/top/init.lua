-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gstring = require("gears.string")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local notifications_daemon = require("daemons.system.notifications")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local collectgarbage = collectgarbage
local setmetatable = setmetatable
local ipairs = ipairs
local string = string
local top = {
    mt = {}
}

local function notification_widget(notification, on_removed)
    local icon = nil
    if notification.font_icon == nil then
        icon = wibox.widget {
            widget = wibox.widget.imagebox,
            forced_width = dpi(40),
            forced_height = dpi(40),
            halign = "left",
            valign = "top",
            clip_shape = helpers.ui.rrect(),
            image = notification.icon
        }
    else
        icon = wibox.widget {
            widget = widgets.text,
            halign = "left",
            valign = "top",
            icon = notification.font_icon,
            size = 30
        }
    end

    local title = wibox.widget {
        widget = wibox.container.place,
        halign = "left",
        {
            widget = widgets.text,
            halign = helpers.string.contain_right_to_left_characters(notification.title) and "right" or "left",
            valign = "top",
            size = 15,
            bold = true,
            text = notification.title
        }
    }

    local message = wibox.widget {
        widget = wibox.container.place,
        halign = "left",
        {
            layout = widgets.overflow.vertical,
            forced_width = dpi(1000),
            spacing = dpi(10),
            scrollbar_widget = widgets.scrollbar,
            scrollbar_width = dpi(10),
            step = 50,
            {
                widget = widgets.text,
                size = 15,
                text = gstring.xml_unescape(notification.message)
            }
        }
    }

    local time = wibox.widget {
        widget = widgets.text,
        id = "time",
        halign = "left",
        valign = "top",
        size = 12,
    }

    local actions = wibox.widget {
        layout = wibox.layout.flex.horizontal,
        spacing = dpi(15)
    }

    if notification.actions ~= nil then
        for _, action in ipairs(notification.actions) do
            local button = wibox.widget {
                widget = widgets.button.text.normal,
                -- forced_height = dpi(40),
                size = 12,
                normal_bg = beautiful.colors.surface,
                text_normal_bg = beautiful.colors.on_surface,
                text = action.name,
                on_release = function()
                    action:invoke()
                end
            }
            actions:add(button)
        end
    end

    local widget = nil
    local dismiss = wibox.widget {
        widget = wibox.container.place,
        valign = "top",
        {
            widget = wibox.container.margin,
            margins = {
                left = dpi(10),
                bottom = dpi(10)
            },
            {
                widget = widgets.button.text.normal,
                forced_width = dpi(40),
                forced_height = dpi(40),
                icon = beautiful.icons.xmark,
                on_release = function()
                    on_removed(widget)
                    notifications_daemon:remove_notification(notification)
                    notification_panel:dynamic_disconnect_signals("visibility")
                end
            }
        }
    }

    widget = wibox.widget {
        widget = wibox.container.margin,
        margins = dpi(10),
        {
            layout = wibox.layout.align.horizontal,
            icon,
            {
                widget = wibox.container.margin,
                margins = {
                    left = dpi(15)
                },
                {
                    layout = wibox.layout.fixed.vertical,
                    spacing = dpi(5),
                    title,
                    time,
                    message,
                    actions
                }
            },
            dismiss
        }
    }

    notification_panel:dynamic_connect_signal("visibility", function(self, visible)
        if visible then
            time:set_text(helpers.string.to_time_ago(notification.time))
        end
    end)

    return widget
end

local function notification_group(notification)
    local icon = nil
    if notification.app_font_icon == nil then
        icon = wibox.widget {
            widget = wibox.widget.imagebox,
            forced_width = dpi(40),
            forced_height = dpi(40),
            halign = "left",
            valign = "top",
            clip_shape = helpers.ui.rrect(),
            image = notification.app_icon
        }
    else
        icon = wibox.widget {
            widget = widgets.text,
            halign = "left",
            icon = notification.app_font_icon,
            size = 30
        }
    end

    local title = wibox.widget {
        widget = widgets.text,
        halign = "left",
        text = notification.app_name:gsub("^%l", string.upper)
    }

    local widget = nil
    local button = wibox.widget {
        widget = widgets.button.elevated.state,
        forced_width = dpi(600),
        halign = "left",
        on_turn_on = function()
            widget.height = dpi(500000000)
        end,
        on_turn_off = function()
            widget.height = dpi(70)
        end,
        {
            layout = wibox.layout.fixed.horizontal,
            spacing = dpi(15),
            icon,
            title
        }
    }

    local seperator = wibox.widget {
        widget = widgets.background,
        forced_height = dpi(1),
        shape = helpers.ui.rrect(),
        bg = beautiful.colors.surface
    }

    local layout = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(20)
    }

    widget = wibox.widget {
        widget = wibox.container.constraint,
        strategy = "max",
        height = dpi(70),
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            -- seperator,
            button,
            seperator,
            layout
        }
    }

    return {
        widget = widget,
        layout = layout
    }
end

local function new()
    local header = wibox.widget {
        widget = widgets.text,
        bold = true,
        text = "Notifications"
    }

    local clear_notifications = wibox.widget {
        widget = widgets.button.text.normal,
        forced_width = dpi(50),
        forced_height = dpi(50),
        icon = beautiful.icons.trash,
        on_release = function()
            notifications_daemon:remove_all_notifications()
            notification_panel:dynamic_disconnect_signals("visibility")
        end
    }

    local empty_notifications = wibox.widget {
        widget = wibox.container.margin,
        margins = {
            top = dpi(250)
        },
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            {
                widget = widgets.text,
                halign = "center",
                icon = beautiful.icons.bell,
                size = 50
            },
            {
                widget = widgets.text,
                halign = "center",
                size = 15,
                text = "No Notifications"
            }
        }
    }

    local scrollbox = wibox.widget {
        layout = widgets.overflow.vertical,
        spacing = dpi(20),
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(10),
        step = 50
    }

    local stack = wibox.widget {
        layout = wibox.layout.stack,
        top_only = true,
        empty_notifications,
        scrollbox
    }

    local notification_groups = {}

    notifications_daemon:connect_signal("new", function(self, notification)
        if notification.app_name ~= nil then
            if notification_groups[notification.app_name] == nil then
                notification_groups[notification.app_name] = notification_group(notification)
                scrollbox:insert(1, notification_groups[notification.app_name].widget)
            end
            notification_groups[notification.app_name].layout:insert(1,
                notification_widget(notification, function(widget)
                    notification_groups[notification.app_name].layout:remove_widgets(widget)

                    if #notification_groups[notification.app_name].layout.children == 0 then
                        scrollbox:remove_widgets(notification_groups[notification.app_name].widget)
                        notification_groups[notification.app_name] = nil
                    end
                end))

            scrollbox:remove_widgets(notification_groups[notification.app_name].widget)
            scrollbox:insert(1, notification_groups[notification.app_name].widget)
        end

        stack:raise_widget(scrollbox)
    end)

    notifications_daemon:connect_signal("empty", function(self)
        notification_groups = {}
        scrollbox:reset()
        collectgarbage("collect")
        stack:raise_widget(empty_notifications)
    end)

    return wibox.widget {
        layout = wibox.layout.fixed.vertical,
        forced_height = dpi(500),
        spacing = dpi(10),
        {
            layout = wibox.layout.align.horizontal,
            expand = "none",
            header,
            nil,
            clear_notifications
        },
        stack
    }
end

function top.mt:__call()
    return new()
end

return setmetatable(top, top.mt)
