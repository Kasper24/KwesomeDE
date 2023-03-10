-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gtimer = require("gears.timer")
local ruled = require("ruled")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local naughty = require("naughty")
local notifications_daemon = require("daemons.system.notifications")
local tasklist_daemon = require("daemons.system.tasklist")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local max = math.max
local ipairs = ipairs
local string = string
local table = table
local type = type

local function play_sound(n)
    if n.category == "device.added" or n.category == "network.connected" then
        awful.spawn("canberra-gtk-play -i service-login", false)
    elseif n.category == "device.removed" or n.category == "network.disconnected" then
        awful.spawn("canberra-gtk-play -i service-logout", false)
    elseif n.category == "device.error" or n.category == "im.error" or n.category == "network.error" or n.category ==
        "transfer.error" then
        awful.spawn("canberra-gtk-play -i dialog-warning", false)
    elseif n.category == "email.arrived" then
        awful.spawn("canberra-gtk-play -i message", false)
    else
        awful.spawn("canberra-gtk-play -i bell", false)
    end
end

local function is_suspended(n)
    if notifications_daemon:is_suspended() == true and n.ignore_suspend ~= true then
        return true
    end
    return false
end

local function get_notification_accent_color(n)
    return n.app_font_icon.color or
            n.font_icon.color or
            beautiful.colors.random_accent_color()
end

local function get_notification_position(n, screen)
    local placement = awful.placement.top_right(n.widget, {
        honor_workarea = true,
        honor_padding = true,
        attach = true,
        pretend = true,
        margins = dpi(30)
    })
    local x = placement.x
    local y = placement.y

    if #screen.notifications > 1 then
        local parent = screen.notifications[#screen.notifications - 1]
        y = parent.widget.y + parent.widget.height + 30
    end

    return { x = x, y = y }
end

local function app_icon_widget(n)
    if n.app_font_icon == nil then
        return wibox.widget {
            widget = wibox.container.constraint,
            strategy = "max",
            height = dpi(20),
            width = dpi(20),
            {
                widget = wibox.widget.imagebox,
                halign = "center",
                valign = "center",
                clip_shape = helpers.ui.rrect(),
                image = n.app_icon
            }
        }
    else
        return wibox.widget {
            widget = widgets.text,
            icon = n.app_font_icon,
            size = n.app_font_icon.size
        }
    end
end

local function icon_widget(n)
    if n._private.color then
        return wibox.widget {
            widget = widgets.background,
            forced_width = dpi(40),
            forced_height = dpi(40),
            shape = helpers.ui.rrect(),
            bg = n._private.color,
        }
    elseif n.font_icon == nil then
        return wibox.widget {
            widget = wibox.container.constraint,
            strategy = "max",
            height = dpi(40),
            width = dpi(40),
            {
                widget = wibox.widget.imagebox,
                clip_shape = helpers.ui.rrect(),
                image = n.icon
            }
        }
    else
        return wibox.widget {
            widget = widgets.text,
            size = 30,
            icon = n.font_icon
        }
    end
end

local function actions_widget(n)
    local actions = wibox.widget {
        layout = wibox.layout.flex.horizontal,
        spacing = dpi(15)
    }

    for _, action in ipairs(n.actions) do
        local button = wibox.widget {
            widget = widgets.button.text.normal,
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

    return actions
end

local function destroy_notif(n, screen)
    local min_y = awful.placement.top_right(n.widget, {
        honor_workarea = true,
        honor_padding = true,
        attach = true,
        pretend = true,
        margins = dpi(30)
    }).y

    helpers.table.remove_value(screen.notifications, n)
    n.destroyed = true
    local destroyed_n_height = n.widget.height
    for _, n in ipairs(screen.notifications) do
        if #screen.notifications > 0 and n.widget.y ~= min_y then
            n.anim:set{y = n.widget.y - destroyed_n_height - 30, height = 300}
        end
    end

    n.widget.widget:get_children_by_id("top_row")[1]:set_third(nil)
    n.anim:set{y = n.widget.y, height = 1}
    n:destroy()
end

local function create_notification(n, screen)
    -- Absurdly big number because setting it to 0 doesn't work
    n:set_timeout(4294967)

    local accent_color = get_notification_accent_color(n)

    local app_name = wibox.widget {
        widget = widgets.text,
        size = 12,
        text = n.app_name:gsub("^%l", string.upper)
    }

    local dismiss = wibox.widget {
        widget = widgets.button.text.normal,
        icon = beautiful.icons.xmark,
        text_normal_bg = beautiful.colors.on_background,
        size = 12,
        on_release = function()
            destroy_notif(n, screen)
        end
    }

    local timeout_arc = wibox.widget {
        widget = widgets.arcchart,
        forced_width = dpi(45),
        forced_height = dpi(45),
        max_value = 100,
        min_value = 0,
        value = 0,
        thickness = dpi(6),
        rounded_edge = true,
        bg = beautiful.colors.surface,
        colors = {
            accent_color
        },
        dismiss
    }

    local title = wibox.widget {
        widget = wibox.container.scroll.horizontal,
        step_function = wibox.container.scroll.step_functions.waiting_nonlinear_back_and_forth,
        speed = 50,
        {
            widget = widgets.text,
            size = 15,
            bold = true,
            text = n.title
        }
    }

    local bar = wibox.widget {
        widget = widgets.background,
        forced_height = dpi(10),
        shape = helpers.ui.rrect(),
        bg = accent_color
    }

    local message = wibox.widget {
        widget = wibox.container.constraint,
        strategy = "max",
        height = dpi(60),
        {
            layout = widgets.overflow.vertical,
            scrollbar_widget = widgets.scrollbar,
            scrollbar_width = dpi(10),
            scroll_speed = 3,
            {
                widget = widgets.text,
                size = 15,
                text = n.message
            }
        }
    }

    n.widget = widgets.popup {
        minimum_width = dpi(400),
        minimum_height = dpi(50),
        maximum_width = dpi(400),
        offset = { y = dpi(30) },
        ontop = true,
        shape = helpers.ui.rrect(),
        bg = beautiful.colors.background,
        border_width = 0,
        widget = wibox.widget {
            widget = wibox.container.background,
            {
                widget = wibox.container.margin,
                margins = dpi(25),
                {
                    layout = wibox.layout.fixed.vertical,
                    spacing = dpi(15),
                    {
                        layout = wibox.layout.align.horizontal,
                        id = "top_row",
                        {
                            layout = wibox.layout.fixed.horizontal,
                            spacing = dpi(15),
                            app_icon_widget(n),
                            app_name
                        },
                        nil,
                    },
                    {
                        layout = wibox.layout.fixed.horizontal,
                        spacing = dpi(15),
                        icon_widget(n),
                        title
                    },
                    bar,
                    message,
                    actions_widget(n)
                }
            }
        }
    }

    local timeout_arc_anim = helpers.animation:new{
        duration = 5,
        target = 100,
        easing = helpers.animation.easing.linear,
        reset_on_stop = false,
        update = function(self, pos)
            timeout_arc.value = pos
        end,
        signals = {
            ["ended"] = function()
                destroy_notif(n, screen)
            end
        }
    }

    n.widget:connect_signal("mouse::enter", function()
        timeout_arc_anim:stop()
    end)

    n.widget:connect_signal("mouse::leave", function()
        timeout_arc_anim:set()
    end)

    local pos = get_notification_position(n, screen)
    n.widget.x = pos.x
    n.widget.y = pos.y

    n.anim = helpers.animation:new{
        pos = { y = pos.y, height = 1},
        duration = 0.2,
        easing = helpers.animation.easing.linear,
        update = function(self, pos)
            if pos.y then
                n.widget.y = pos.y
            end
            if pos.height then
                n.widget.maximum_height = dpi(max(1, pos.height))
            end
        end,
        signals = {
            ["ended"] = function()
                if n.destroyed then
                    n.widget.visible = false
                    n.widget = nil
                    collectgarbage("collect")
                    collectgarbage("collect")
                else
                    -- Prevents a crash caused by drawing the arc when the size is to small
                    n.widget.widget:get_children_by_id("top_row")[1]:set_third(timeout_arc)
                    timeout_arc_anim:set()
                end
            end
        }
    }
    n.anim:set{y = pos.y, height = 300}

    play_sound(n)
end

ruled.notification.connect_signal("request::rules", function()
    ruled.notification.append_rule {
        rule = {
            app_name = "networkmanager-dmenu"
        },
        properties = {
            icon = helpers.icon_theme.get_icon_path("networkmanager")
        }
    }
    ruled.notification.append_rule {
        rule = {
            app_name = "blueman"
        },
        properties = {
            icon = helpers.icon_theme.get_icon_path("blueman-device")
        }
    }
end)

naughty.connect_signal("request::action_icon", function(a, context, hints)
    a.icon = helpers.icon_theme.get_icon_path(hints.id)
end)

naughty.connect_signal("added", function(n)
    if n.title == "" or n.title == nil then
        n.title = n.app_name
    end

    if n._private.app_font_icon == nil then
        n.app_font_icon = tasklist_daemon:get_font_icon(n.app_name)
    else
        n.app_font_icon = n._private.app_font_icon
    end
    n.font_icon = n._private.font_icon

    if type(n._private.app_icon) == "table" then
        n.app_icon = helpers.icon_theme.choose_icon(n._private.app_icon)
    else
        n.app_icon = helpers.icon_theme.get_icon_path(n._private.app_icon or n.app_name)
    end

    if type(n.icon) == "table" then
        n.icon = helpers.icon_theme.choose_icon(n.icon)
    end

    if n.app_icon == "" or n.app_icon == nil then
        n.app_icon = helpers.icon_theme.get_icon_path("application-default-icon")
    end

    if (n.icon == "" or n.icon == nil) and n.font_icon == nil then
        n.font_icon = beautiful.icons.message
        n.icon = helpers.icon_theme.get_icon_path("preferences-desktop-notification-bell")
    end
end)

naughty.connect_signal("request::display", function(n)
    if is_suspended(n) then
        return
    end

    gtimer.start_new(0.2, function()
        local screen = awful.screen.focused()

        if screen.notifications then
            local last_notif = screen.notifications[#screen.notifications]
            if last_notif and last_notif.anim and last_notif.anim.state == true then
                return true
            end
        end

        if #screen.notifications > 2 then
            return true
        end

        table.insert(screen.notifications, n)
        create_notification(n, screen)
        return false
    end)
end)

awful.screen.connect_for_each_screen(function(s)
    s.notifications = {}
end)

require(... .. ".bluetooth")
require(... .. ".email")
require(... .. ".error")
require(... .. ".github")
require(... .. ".gitlab")
require(... .. ".lock")
require(... .. ".network")
require(... .. ".pacman")
require(... .. ".picom")
require(... .. ".playerctl")
require(... .. ".record")
require(... .. ".screenshot")
require(... .. ".theme")
require(... .. ".udev")
require(... .. ".upower")
