-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gtimer = require("gears.timer")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local task_preview = require("ui.popups.task_preview")
local beautiful = require("beautiful")
local tasklist_daemon = require("daemons.system.tasklist")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local ipairs = ipairs
local pairs = pairs
local capi = {
    client = client
}

local tasklist = {
    mt = {}
}

local favorites = {}

local function favorite_widget(layout, command, class)
    favorites[class] = true

    local font_icon = helpers.client.get_font_icon(class)

    local menu = widgets.menu {
        widgets.menu.button {
            icon = font_icon,
            text = class,
            on_press = function()
                awful.spawn(command, false)
            end
        },
        widgets.menu.button {
            text = "Unpin from Taskbar",
            on_press = function()
                tasklist_daemon:remove_favorite{class = class}
            end
        }
    }

    local button = wibox.widget {
        widget = wibox.container.margin,
        forced_width = dpi(80),
        margins = dpi(5),
        {
            widget = widgets.button.text.state,
            icon = font_icon,
            on_release = function()
                menu:hide()
                awful.spawn(command, false)
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

    tasklist_daemon:dynamic_connect_signal(class .. "::removed", function()
        layout:remove_widgets(button)
        menu:hide()
        tasklist_daemon:dynamic_disconnect_signals(class .. "::removed")
    end)

    capi.client.connect_signal("manage", function(c)
        if c.class == class then
            layout:remove_widgets(button)
            menu:hide()
            favorites[class] = nil
        end
    end)

    return button
end

local function client_widget(client)
    local menu = widgets.client_menu(client)

    local button = wibox.widget {
        widget = wibox.container.margin,
        margins = dpi(5),
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
        forced_width = dpi(80),
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
    local favorites = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15)
    }

    local task_list = wibox.widget {
        layout = wibox.layout.manual
    }

    capi.client.connect_signal("manage", function(client)
        if tasklist_daemon:is_favorite(client) then
            task_list:remove_widgets(client.favorite_widget)
        end
    end)

    capi.client.connect_signal("unmanage", function(client)
        task_list:remove_widgets(client.tasklist_widget)

        -- if #helpers.client.find({class = client.class}) == 0 then
        --     if tasklist_daemon:is_favorite(client) and favorites[client.class] == nil then
        --         favorites:add(favorite_widget(favorites, command, client.class))
        --     end
        -- end
    end)

    capi.client.connect_signal("property::index", function(client)
        local pos = (client.index - 1) * 80
        if client.tasklist_widget then
            task_list:move_widget(client.tasklist_widget, { x = pos, y = 0})
        else
            client.tasklist_widget = client_widget(client)
            task_list:add_at(client.tasklist_widget, { x = pos, y = 0})
        end
    end)

    -- for _, favorite in ipairs(tasklist_daemon:get_favorites()) do
        -- favorites:add(favorite_widget(favorites, command, class))
    -- end

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(5),
        -- favorites,
        task_list
    }
end

function tasklist.mt:__call(...)
    return new(...)
end

return setmetatable(tasklist, tasklist.mt)