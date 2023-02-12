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
local favorites_daemon = require("daemons.system.favorites")
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

    local font_icon = beautiful.get_font_icon_for_app_name(class)

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
                favorites_daemon:remove_favorite{class = class}
            end
        }
    }

    local button = wibox.widget {
        widget = wibox.container.margin,
        margins = dpi(5),
        {
            widget = widgets.button.text.state,
            forced_width = dpi(65),
            forced_height = dpi(65),
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

    favorites_daemon:connect_signal(class .. "::removed", function()
        layout:remove_widgets(button)
        menu:hide()
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
            forced_width = dpi(65),
            forced_height = dpi(65),
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
    local favorites = wibox.widget {
        layout = wibox.layout.flex.horizontal,
        spacing = dpi(15)
    }

    local task_list = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15)
    }

    capi.client.connect_signal("manage", function(client)
        if favorites_daemon:is_favorite(client) then
            favorites:remove(client.favorite_widget)
        end
    end)

    capi.client.connect_signal("unmanage", function(client)
        task_list:remove_widgets(client.tasklist_widget)

        for _, c in ipairs(capi.client.get()) do
            if c.class == client.class then
                return
            end
        end

        local command = favorites_daemon:is_favorite(client)
        if command ~= nil and favorites[client.class] == nil then
            favorites:add(favorite_widget(favorites, command, client.class))
        end
    end)

    capi.client.connect_signal("swapped", function(client, other_client, is_source)
        if is_source then
            local client_index = helpers.client.get_client_index(client)
            local other_client_index = helpers.client.get_client_index(other_client)
            task_list:set(client_index, client.tasklist_widget)
            task_list:set(other_client_index, other_client.tasklist_widget)
        end
    end)

    capi.client.connect_signal("scanned", function()
        for _, client in ipairs(helpers.client.get_sorted_clients()) do
            client.tasklist_widget = client_widget(client)
            task_list:add(client.tasklist_widget)
        end

        capi.client.connect_signal("tagged", function(client)
            if client.tasklist_widget then
                task_list:remove_widgets(client.tasklist_widget)
            end
            client.tasklist_widget = client_widget(client)
            local client_index = helpers.client.get_client_index(client)
            if #task_list.children < client_index then
                task_list:add(client.tasklist_widget)
            else
                task_list:insert(client_index, client.tasklist_widget)
            end
        end)
    end)

    for class, command in pairs(favorites_daemon:get_favorites()) do
        favorites:add(favorite_widget(favorites, command, class))
    end

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(20),
        favorites,
        task_list
    }
end

function tasklist.mt:__call(...)
    return new(...)
end

return setmetatable(tasklist, tasklist.mt)