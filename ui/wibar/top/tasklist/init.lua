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
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local capi = {
    client = client
}

local tasklist = {
    mt = {}
}

local function pinned_app_widget(pinned_app)
    local menu = widgets.menu {
        widgets.menu.button {
            icon = pinned_app.font_icon,
            text = pinned_app.class,
            on_press = function()
                awful.spawn(pinned_app.exec, false)
            end
        },
        widgets.menu.button {
            text = "Unpin App",
            on_press = function()
                tasklist_daemon:remove_pinned_app{id = pinned_app.desktop_app_info_id, class = pinned_app.class}
            end
        }
    }

    for index, action in ipairs(pinned_app.actions) do
        if index == 1 then
            menu:add(widgets.menu.separator())
        end

        menu:add(widgets.menu.button {
            text = action.name,
            on_press = function()
                action.launch()
            end
        })
    end

    local widget = wibox.widget {
        widget = wibox.container.margin,
        forced_width = dpi(70),
        forced_height = dpi(70),
        margins = dpi(5),
        {
            widget = widgets.button.text.state,
            icon = pinned_app.font_icon,
            on_release = function()
                menu:hide()
                awful.spawn(pinned_app.exec, false)
            end,
            on_secondary_press = function(self)
                menu:toggle{
                    wibox = awful.screen.focused().top_wibar,
                    widget = self,
                    offset = {
                        y = dpi(70)
                    }
                }
            end
        }
    }

    function widget:hide_menu()
        menu:hide()
    end

    return widget
end

local function client_widget(client)
    local menu = widgets.client_menu(client)

    local button = wibox.widget {
        widget = wibox.container.margin,
        margins = dpi(5),
        forced_width = dpi(70),
        forced_height = dpi(70),
        {
            widget = widgets.button.text.state,
            id = "button",
            on_by_default = capi.client.focus == client,
            icon = client.font_icon,
            on_hover = function(self)
                task_preview:show(client, {
                    wibox = awful.screen.focused().top_wibar,
                    widget = self,
                    offset = {
                        y = dpi(70)
                    }
                })
            end,
            on_leave = function()
                task_preview:hide()
            end,
            on_release = function()
                task_preview:hide()
                menu:hide()

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
            on_secondary_press = function(self)
                task_preview:hide()
                menu:toggle{
                    wibox = awful.screen.focused().top_wibar,
                    widget = self,
                    offset = {
                        y = dpi(70)
                    }
                }
            end
        }
    }

    local indicator = wibox.widget {
        widget = wibox.container.place,
        valign = "bottom",
        {
            widget = widgets.background,
            id = "background",
            forced_width = capi.client.focus == client and dpi(50) or dpi(20),
            forced_height = dpi(5),
            shape = helpers.ui.rrect(),
            bg = client.font_icon.color
        }
    }

    local indicator_animation = helpers.animation:new{
        pos = capi.client.focus == client and dpi(50) or dpi(20),
        duration = 0.2,
        easing = helpers.animation.easing.linear,
        update = function(self, pos)
            indicator.children[1].forced_width = pos
        end
    }

    local widget = wibox.widget {
        widget = wibox.layout.stack,
        button,
        indicator
    }

    client:connect_signal("property::font_icon", function(client)
        button:get_children_by_id("button")[1]:set_icon(client.font_icon)
        indicator:get_children_by_id("background")[1]:set_bg(client.font_icon.color)
    end)

    client:connect_signal("focus", function()
        button:get_children_by_id("button")[1]:turn_on()
        indicator_animation:set(dpi(50))
    end)

    client:connect_signal("unfocus", function()
        button:get_children_by_id("button")[1]:turn_off()
        indicator_animation:set(dpi(20))
    end)

    client:connect_signal("unmanage", function()
        menu:hide()
    end)

    return widget
end

local function new()
    local tasklist_layout = wibox.widget {
        layout = wibox.layout.manual
    }

    tasklist_daemon:connect_signal("client::pos", function(self, client, pos)
        if client.tasklist_widget == nil then
            client.tasklist_widget = client_widget(client)
            tasklist_layout:add_at(client.tasklist_widget, { x =  pos * 80, y = 0})
        else
            tasklist_layout:move_widget(client.tasklist_widget, { x = pos * 80, y = 0})
        end
    end)

    tasklist_daemon:connect_signal("client::removed", function(self, client)
        tasklist_layout:remove_widgets(client.tasklist_widget)
        client.tasklist_widget = nil
    end)

    tasklist_daemon:connect_signal("pinned_app::pos", function(self, pinned_app, pos)
        if pinned_app.widget == nil then
            pinned_app.widget = pinned_app_widget(pinned_app)
            tasklist_layout:add_at(pinned_app.widget, { x =  pos * 80, y = 0})
        else
            tasklist_layout:move_widget(pinned_app.widget, { x = pos * 80, y = 0})
        end
    end)

    tasklist_daemon:connect_signal("pinned_app::removed", function(self, pinned_app)
        tasklist_layout:remove_widgets(pinned_app.widget)
        pinned_app.widget = nil
    end)

    return tasklist_layout
end

function tasklist.mt:__call(...)
    return new(...)
end

return setmetatable(tasklist, tasklist.mt)