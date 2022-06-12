-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local gstring = require("gears.string")
local gtimer = require("gears.timer")
local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local beautiful = require("beautiful")
local notifications_daemon = require("daemons.system.notifications")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local collectgarbage = collectgarbage
local setmetatable = setmetatable
local ipairs = ipairs
local os = os

local notifications = { mt = {} }

local accent_color = beautiful.random_accent_color()

local function notification_widget(notification, on_removed)
    local icon = nil
    if notification.font_icon == nil then
        icon = wibox.widget
        {
            widget = wibox.widget.imagebox,
            forced_width = dpi(40),
            forced_height = dpi(40),
            halign = "left",
            valign = "top",
            clip_shape = helpers.ui.rrect(beautiful.border_radius),
            image = notification.icon,
        }
    else
        icon = widgets.text
        {
            halign = "left",
            valign = "top",
            size = 30,
            color = beautiful.random_accent_color(),
            font = notification.font_icon.font,
            text = notification.font_icon.icon
        }
    end

    local title = wibox.widget
    {
        widget = wibox.container.place,
        halign = "left",
        widgets.text
        {
            halign = helpers.string.contain_right_to_left_characters(notification.title) and "right" or "left",
            valign = "top",
            size = 15,
            bold = true,
            text = notification.title
        }
    }

    local message = wibox.widget
    {
        widget = wibox.container.place,
        halign = "left",
        {
            layout = widgets.overflow.vertical,
            forced_width = dpi(1000),
            spacing = dpi(10),
            scrollbar_widget =
            {
                widget = wibox.widget.separator,
                shape = helpers.ui.rrect(beautiful.border_radius),
            },
            scrollbar_width = dpi(10),
            step = 50,
            {
                widget = wibox.widget.textbox,
                text = gstring.xml_unescape(notification.message)
            }
        }
    }

    local time = widgets.text
    {
        halign = "left",
        valign = "top",
        size = 12,
        text = helpers.string.to_time_ago(os.difftime(os.time(os.date("*t")), helpers.string.parse_date(notification.time)))
    }

    local actions = wibox.widget
    {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15)
    }

    if notification.actions ~= nil then
        for _, action in ipairs(notification.actions) do
            local button = widgets.button.text.normal
            {
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
    local dismiss = wibox.widget
    {
        widget = wibox.container.place,
        valign = "top",
        widgets.button.text.normal
        {
            forced_width = dpi(40),
            forced_height = dpi(40),
            margins = { left = dpi(10), bottom = dpi(10) },
            hover_bg = beautiful.colors.surface,
            text_normal_bg = accent_color,
            text = beautiful.xmark_icon.icon,
            on_release = function()
                on_removed(widget)
                notifications_daemon:remove_notification(notification)
            end
        }
    }

    widget = wibox.widget
    {
        widget = wibox.container.margin,
        margins = dpi(10),
        {
            layout = wibox.layout.align.horizontal,
            icon,
            {
                widget = wibox.container.margin,
                margins = { left = dpi(15) },
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

    function widget.update_time_ago()
        time.markup = helpers.string.to_time_ago(os.difftime(os.time(os.date("*t")), helpers.string.parse_date(notification.time)))
    end

    return widget
end

local function notification_group(notification)
    local icon = nil
    if notification.app_font_icon == nil then
        icon = wibox.widget
        {
            widget = wibox.widget.imagebox,
            forced_width = dpi(40),
            forced_height = dpi(40),
            halign = "left",
            valign = "top",
            clip_shape = helpers.ui.rrect(beautiful.border_radius),
            image = notification.app_icon,
        }
    else
        icon = widgets.text
        {
            size = 30,
            color = beautiful.random_accent_color(),
            font = notification.app_font_icon.font,
            text = notification.app_font_icon.icon
        }
    end

    local title = widgets.text
    {
        text = notification.app_name:gsub("^%l", string.upper)
    }

    local widget = nil
    local button = widgets.button.elevated.state
    {
        halign = "left",
        on_turn_on = function()
            widget.height = dpi(500000000)
        end,
        on_turn_off = function()
            widget.height = dpi(70)
        end,
        child =
        {
            layout = wibox.layout.fixed.horizontal,
            spacing = dpi(15),
            icon,
            title,
        }
    }

    local seperator = wibox.widget
    {
        widget = wibox.widget.separator,
        forced_width = dpi(1),
        forced_height = dpi(1),
        shape = helpers.ui.rrect(beautiful.border_radius),
        orientation = "horizontal",
        color = beautiful.colors.surface
    }

    local layout = wibox.widget
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(20)
    }

    widget = wibox.widget
    {
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

    return { widget = widget, layout = layout }
end

local function new()
    local header = widgets.text
    {
        bold = true,
        text = "Notifications"
    }

    local clear_notifications = widgets.button.text.normal
    {
        forced_width = dpi(50),
        forced_height = dpi(50),
        font = beautiful.trash_icon.font,
        text = beautiful.trash_icon.icon,
        on_release = function()
            notifications_daemon:remove_all_notifications()
        end
    }

    local empty_notifications = wibox.widget
    {
        widget = wibox.container.margin,
        margins = { top = dpi(250) },
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            widgets.text
            {
                halign = "center",
                size = 50,
                color = beautiful.random_accent_color(),
                font = beautiful.bell_icon.font,
                text = beautiful.bell_icon.icon
            },
            widgets.text
            {
                halign = "center",
                size = 15,
                text = "No Notifications"
            },
        }
    }

    local scrollbox = wibox.widget
    {
        layout = widgets.overflow.vertical,
        spacing = dpi(20),
        scrollbar_widget =
        {
            widget = wibox.widget.separator,
            shape = helpers.ui.rrect(beautiful.border_radius),
        },
        scrollbar_width = dpi(10),
        step = 50,
    }

    local spinning_circle = wibox.widget
    {
        widget = wibox.container.margin,
        margins = { top = dpi(250)},
        widgets.spinning_circle
        {
            forced_width = dpi(50),
            forced_height = dpi(50)
        }
    }

    local stack = wibox.widget
    {
        layout = wibox.layout.stack,
        top_only = true,
        spinning_circle,
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
            notification_groups[notification.app_name].layout:insert(1, notification_widget(notification, function(widget)
                notification_groups[notification.app_name].layout:remove_widgets(widget)

                if #notification_groups[notification.app_name].layout.children == 0 then
                    scrollbox:remove_widgets(notification_groups[notification.app_name].widget)
                    notification_groups[notification.app_name] = nil
                end
            end))

            scrollbox:remove_widgets(notification_groups[notification.app_name].widget)
            scrollbox:insert(1, notification_groups[notification.app_name].widget)
        end

        spinning_circle.children[1]:abort()
        stack:remove_widgets(spinning_circle)
        stack:raise_widget(scrollbox)
    end)

    notifications_daemon:connect_signal("empty", function(self)
        notification_groups = {}
        spinning_circle.children[1]:abort()
        scrollbox:reset()
        stack:remove_widgets(spinning_circle)
        stack:raise_widget(empty_notifications)
        collectgarbage("collect")
    end)

    gtimer { timeout = 60, call_now = false, autostart = true, callback = function()
        for _, widget in ipairs(scrollbox.all_children) do
            if widget.update_time_ago then
                widget:update_time_ago()
            end
        end
    end }

    return wibox.widget
    {
        layout = wibox.layout.fixed.vertical,
        forced_height = dpi(600),
        spacing = dpi(10),
        {
            layout = wibox.layout.align.horizontal,
            expand = "none",
            header,
            nil,
            clear_notifications,
        },
        stack
    }
end

function notifications.mt:__call()
    return new()
end

return setmetatable(notifications, notifications.mt)