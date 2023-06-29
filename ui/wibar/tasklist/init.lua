-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local task_preview = require("ui.popups.task_preview")
local beautiful = require("beautiful")
local tasklist_daemon = require("daemons.system.tasklist")
local ui_daemon = require("daemons.system.ui")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local ipairs = ipairs
local capi = {
    client = client
}

local tasklist = {
    mt = {}
}

local function get_widget_size()
    return dpi(65)
end

local function get_widget_spacing()
    return dpi(65)
end

local function animate_layout(tasklist_layout_animation)
    tasklist_layout_animation:set(#tasklist_daemon:get_clients() * get_widget_spacing())
end

local function pinned_app_menu(pinned_app)
    local menu = widgets.menu {
        widgets.menu.button {
            icon = pinned_app.icon,
            text = pinned_app.class,
            on_release = function()
                pinned_app:run()
            end
        },
        widgets.menu.button {
            text = "Run as Root",
            on_release = function()
                pinned_app:run_as_root()
            end
        },
        widgets.menu.separator(),
        widgets.menu.button {
            text = "Unpin App",
            on_release = function()
                tasklist_daemon:remove_pinned_app(pinned_app.class)
            end
        }
    }

    for index, action in ipairs(pinned_app.actions) do
        if index == 1 then
            menu:add(widgets.menu.separator())
        end

        menu:add(widgets.menu.button {
            text = action.name,
            on_release = function()
                action.launch()
            end
        })
    end

    return menu
end

local function pinned_app_widget(pinned_app)
    local menu = pinned_app_menu(pinned_app)

    local widget = wibox.widget {
        widget = wibox.container.margin,
        forced_width = get_widget_size(),
        forced_height = get_widget_size(),
        margins = dpi(5),
        {
            widget = widgets.button.state,
            on_release = function()
                menu:hide()
                pinned_app:run()
            end,
            on_secondary_release = function(self)
                local coords = nil
                if ui_daemon:get_bars_layout() == "vertical" then
                    coords = helpers.ui.get_widget_geometry_in_device_space({wibox = awful.screen.focused().vertical_wibar}, self)
                    coords.x = coords.x + dpi(65)
                else
                    coords = helpers.ui.get_widget_geometry_in_device_space({wibox = awful.screen.focused().horizontal_wibar}, self)
                    coords.y = coords.y + awful.screen.focused().horizontal_wibar.y
                    if ui_daemon:get_horizontal_bar_position() == "top" then
                        coords.y = coords.y + dpi(65)
                    else
                        coords.y = coords.y + -dpi(190)
                    end
                end

                menu:toggle{coords = coords}
            end,
            {
                widget = widgets.icon,
                halign = "center",
                valign = "center",
                icon = pinned_app.icon,
            }
        }
    }

    function widget:hide_menu()
        menu:hide()
    end

    return widget
end

local function client_widget(client)
    client.menu = widgets.client_menu(client)

    local button = wibox.widget {
        widget = wibox.container.margin,
        margins = { top = dpi(5), bottom = dpi(10), left = dpi(10), right = dpi(10)},
        forced_width = get_widget_size(),
        forced_height = get_widget_size(),
        {
            widget = widgets.button.state,
            id = "button",
            on_by_default = capi.client.focus == client,
            on_color =  client._icon.color,
            on_hover = function(self)
                local coords = nil
                if ui_daemon:get_bars_layout() == "vertical" then
                    coords = helpers.ui.get_widget_geometry_in_device_space({wibox = awful.screen.focused().vertical_wibar}, self)
                    coords.x = coords.x + dpi(65)
                else
                    coords = helpers.ui.get_widget_geometry_in_device_space({wibox = awful.screen.focused().horizontal_wibar}, self)
                    coords.y = coords.y + awful.screen.focused().horizontal_wibar.y
                    if ui_daemon:get_horizontal_bar_position() == "top" then
                        coords.y = coords.y + dpi(65)
                    else
                        coords.y = coords.y + -dpi(190)
                    end
                end

                task_preview:show(client, {coords = coords})
            end,
            on_leave = function()
                task_preview:hide()
            end,
            on_release = function()
                task_preview:hide()
                client.menu:hide()

                if client.minimized == false then
                    if capi.client.focus == client then
                        client.minimized = true
                    else
                        capi.client.focus = client
                        client:raise()
                    end
                else
                    client.minimized = false
                end
                if client:tags() and client:tags()[1] then
                    client:tags()[1]:view_only()
                else
                    client:tags({awful.screen.focused().selected_tag})
                end
            end,
            on_secondary_release = function(self)
                task_preview:hide()

                local coords = nil
                if ui_daemon:get_bars_layout() == "vertical" then
                    coords = helpers.ui.get_widget_geometry_in_device_space({wibox = awful.screen.focused().vertical_wibar}, self)
                    coords.x = coords.x + dpi(65)
                else
                    coords = helpers.ui.get_widget_geometry_in_device_space({wibox = awful.screen.focused().horizontal_wibar}, self)
                    coords.y = coords.y + awful.screen.focused().horizontal_wibar.y
                    if ui_daemon:get_horizontal_bar_position() == "top" then
                        coords.y = coords.y + dpi(65)
                    else
                        coords.y = coords.y + -dpi(190)
                    end
                end

                client.menu:toggle{coords = coords}
            end,
            {
                widget = widgets.icon,
                halign = "center",
                valign = "center",
                color = client._icon.color,
                on_color = beautiful.colors.icon_transparent,
                icon = client._icon,
            }
        }
    }

    local indicator = wibox.widget {
        widget = wibox.container.place,
        {
            widget = widgets.background,
            id = "background",
            shape = helpers.ui.rrect(),
            bg = client._icon.color
        }
    }

    if ui_daemon:get_bars_layout() == "vertical" then
        indicator.halign = "right"
        indicator.valign = "center"
        indicator.children[1].forced_width = dpi(5)
        indicator.children[1].forced_height = capi.client.focus == client and dpi(50) or dpi(20)
    else
        indicator.halign = "center"
        indicator.valign = "bottom"
        indicator.children[1].forced_width = capi.client.focus == client and dpi(50) or dpi(20)
        indicator.children[1].forced_height = dpi(5)
    end

    local indicator_animation = helpers.animation:new{
        pos = capi.client.focus == client and dpi(50) or dpi(20),
        duration = 0.2,
        easing = helpers.animation.easing.linear,
        update = function(self, pos)
            if ui_daemon:get_bars_layout() == "vertical" then
                indicator.children[1].forced_height = pos
            else
                indicator.children[1].forced_width = pos
            end
        end
    }

    local widget = wibox.widget {
        widget = wibox.layout.stack,
        id = client.pid,
        button,
        indicator
    }

    client:connect_signal("focus", function()
        button:get_children_by_id("button")[1]:turn_on()
        indicator_animation:set(dpi(50))
    end)

    client:connect_signal("unfocus", function()
        button:get_children_by_id("button")[1]:turn_off()
        indicator_animation:set(dpi(20))
    end)

    client:connect_signal("unmanage", function()
        client.menu:hide()
    end)

    return widget
end

local function new()
    local tasklist_layout = wibox.widget {
        layout = wibox.layout.manual,
    }

    if ui_daemon:get_bars_layout() == "vertical" then
        tasklist_layout.forced_height = 0
    else
        tasklist_layout.forced_width = 0
    end

    local tasklist_layout_animation = helpers.animation:new {
        pos = 0,
        duration = 0.2,
        easing = helpers.animation.easing.linear,
        update = function(self, pos)
            if ui_daemon:get_bars_layout() == "vertical" then
                tasklist_layout.forced_height = pos
            else
                tasklist_layout.forced_width = pos
            end
        end
    }

    tasklist_daemon:connect_signal("client::pos", function(self, client, pos)
        if client.tasklist_widget == nil then
            local widget = client_widget(client)
            client.tasklist_widget = widget
            widget.move_animation = helpers.animation:new {
                pos = pos * get_widget_spacing(),
                duration = 0.2,
                easing = helpers.animation.easing.linear,
                update = function(self, pos)
                    if ui_daemon:get_bars_layout() == "vertical" then
                        tasklist_layout:move_widget(widget, { x = 0, y = pos})
                    else
                        tasklist_layout:move_widget(widget, { x = pos, y = 0})
                    end
                end
            }
            widget.size_animation = helpers.animation:new {
                pos = 1,
                duration = 0.2,
                easing = helpers.animation.easing.linear,
                update = function(self, pos)
                    if ui_daemon:get_bars_layout() == "vertical" then
                        widget.forced_height = pos
                    else
                        widget.forced_width = pos
                    end
                end,
                signals = {
                    ["ended"] = function()
                        if widget.pending_remove then
                            tasklist_layout:remove_widgets(widget)
                            widget = nil
                        end
                    end
                }
            }
            widget.size_animation:set(get_widget_size())

            if ui_daemon:get_bars_layout() == "vertical" then
                tasklist_layout:add_at(widget, { x =  0, y = pos * get_widget_spacing()})
            else
                tasklist_layout:add_at(widget, { x =  pos * get_widget_spacing(), y = 0})
            end
        else
            client.tasklist_widget.move_animation:set(pos * get_widget_spacing())
        end

        animate_layout(tasklist_layout_animation)
    end)

    tasklist_daemon:connect_signal("client::removed", function(self, client)
        client.tasklist_widget.pending_remove = true
        client.tasklist_widget.size_animation:set(1)

        animate_layout(tasklist_layout_animation)
    end)

    tasklist_daemon:connect_signal("pinned_app::pos", function(self, pinned_app, pos)
        if pinned_app.widget == nil then
            pinned_app.widget = pinned_app_widget(pinned_app)
            if ui_daemon:get_bars_layout() == "vertical" then
                tasklist_layout:add_at(pinned_app.widget, { x =  0, y = pos * get_widget_spacing()})
            else
                tasklist_layout:add_at(pinned_app.widget, { x =  pos * get_widget_spacing(), y = 0})
            end
        else
            if ui_daemon:get_bars_layout() == "vertical" then
                tasklist_layout:move_widget(pinned_app.widget, { x = 0, y = pos * get_widget_spacing()})
            else
                tasklist_layout:move_widget(pinned_app.widget, { x = pos * get_widget_spacing(), y = 0})
            end
        end

        animate_layout(tasklist_layout_animation)
    end)

    tasklist_daemon:connect_signal("pinned_app::removed", function(self, pinned_app)
        tasklist_layout:remove_widgets(pinned_app.widget)
        pinned_app.widget = nil

        animate_layout(tasklist_layout_animation)
    end)

    return tasklist_layout
end

function tasklist.mt:__call(...)
    return new()
end

return setmetatable(tasklist, tasklist.mt)
