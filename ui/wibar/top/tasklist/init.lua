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
local capi = {
    awesome = awesome,
    client = client
}

local tasklist = {
    mt = {}
}

-- =============================================================================
--  Task list
-- =============================================================================
local favorites = {}

local function favorite(layout, client, class)
    favorites[class] = true

    local menu = widgets.menu {widgets.menu.button {
        icon = client.font_icon,
        text = class,
        on_press = function()
            awful.spawn(client.command, false)
        end
    }, widgets.menu.button {
        text = "Unpin from taskbar",
        on_press = function()
            favorites_daemon:remove_favorite({
                class = class
            })
        end
    }}

    local font_icon = beautiful.get_font_icon_for_app_name(class)

    local button = wibox.widget {
        widget = wibox.container.margin,
        margins = dpi(5),
        {
            widget = widgets.button.text.state,
            forced_width = dpi(65),
            forced_height = dpi(65),
            icon = font_icon,
            size = 20,
            on_release = function()
                menu:hide()
                awful.spawn(client.command, false)
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
    end)

    capi.client.connect_signal("manage", function(c)
        if c.class == class then
            layout:remove_widgets(button)
            favorites[class] = nil
        end
    end)

    return button
end

local function client_task(favorites_layout, task_list, client)
    client.font_icon = beautiful.get_font_icon_for_app_name(client.class)
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
            widget = wibox.container.background,
            id = "background",
            forced_width = capi.client.focus == client and dpi(50) or dpi(20),
            forced_height = dpi(5),
            shape = helpers.ui.rrect(beautiful.border_radius),
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

    client:connect_signal("property::class", function()
        client.font_icon = beautiful.get_font_icon_for_app_name(client.class)
        button:set_icon(client.font_icon)
        indicator:set_bg(client.font_icon.color)
    end)

    client:connect_signal("focus", function()
        button:get_children_by_id("button")[1]:turn_on()
        indicator_animation:set(dpi(50))
    end)

    client:connect_signal("unfocus", function()
        button:get_children_by_id("button")[1]:turn_off()
        indicator_animation:set(dpi(20))
    end)

    client:connect_signal("swapped", function()
        if awful.client.getmaster() == client then
            if task_list:remove_widgets(widget) == true then
                task_list:insert(1, widget)
            end
        end
    end)

    client:connect_signal("unmanage", function()
        menu:hide()
        task_list:remove_widgets(widget)

        for _, c in ipairs(capi.client.get()) do
            if c.class == client.class then
                return
            end
        end

        local client_favorite = favorites_daemon:is_favorite(client.class)
        if client_favorite ~= nil and favorites[client.class] == nil then
            favorites_layout:add(favorite(favorites_layout, client_favorite, client.class))
        end
    end)

    if awful.client.getmaster() == client then
        task_list:insert(1, widget)
    else
        task_list:add(widget)
    end

    client.current_task_list = task_list
    client.current_task_widget = widget

    capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
        indicator:get_children_by_id("background")[1].bg =
            old_colorscheme_to_new_map[client.font_icon.color]
    end)
end

local function new(s)
    local favorites = wibox.widget {
        layout = wibox.layout.flex.horizontal,
        spacing = dpi(15)
    }

    local task_list = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(20)
    }

    for _, __ in ipairs(s.tags) do
        local tag_task_list = wibox.widget {
            layout = wibox.layout.flex.horizontal,
            spacing = dpi(15)
        }
        task_list:add(tag_task_list)
    end

    -- Wait a little bit so clients show at the correct order
    gtimer {
        timeout = 3.5,
        single_shot = true,
        call_now = false,
        autostart = true,
        callback = function()
            for _, c in ipairs(capi.client.get()) do
                client_task(favorites, task_list.children[c.first_tag.index], c)
            end

            capi.client.connect_signal("tagged", function(c, t)
                if c.current_task_list and c.current_task_widget then
                    c.current_task_list:remove_widgets(c.current_task_widget)
                    c.current_task_list = nil
                    c.current_task_widget = nil
                end

                if favorites_daemon:is_favorite(c.class) then
                    favorites:remove(c.favorite_widget)
                end

                client_task(favorites, task_list.children[t.index], c)
            end)
        end
    }

    for class, client in pairs(favorites_daemon:get_favorites()) do
        favorites:add(favorite(favorites, client, class))
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