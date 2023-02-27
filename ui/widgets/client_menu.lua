-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local mwidget = require("ui.widgets.menu")
local tasklist_daemon = require("daemons.system.tasklist")
local setmetatable = setmetatable
local ipairs = ipairs

local client_menu = {
    mt = {}
}

local function client_checkbox_button(client, property, text, on_release)
    local button = mwidget.checkbox_button {
        handle_active_color = client.font_icon.color,
        text = text,
        on_release = function()
            client[property] = not client[property]
            if on_release then
                on_release()
            end
        end
    }

    client:connect_signal("property::" .. property, function()
        if client[property] then
            button:turn_on()
        else
            button:turn_off()
        end
    end)

    return button
end

local function new(client)
    local maximize_menu = mwidget {client_checkbox_button(client, "maximized", "Maximize"),
                                   client_checkbox_button(client, "maximized_horizontal", "Maximize Horizontally"),
                                   client_checkbox_button(client, "maximized_vertical", "Maximize Vertically")}

    local layer_menu = mwidget {client_checkbox_button(client, "above", "Above"),
                                client_checkbox_button(client, "below", "Below"),
                                client_checkbox_button(client, "ontop", "On Top")}


    local client_icon_button = mwidget.button {
        icon = client.font_icon,
        text = client.class,
        on_release = function()
            client:jump_to()
        end
    }

    local pin_to_taskbar_button = mwidget.checkbox_button {
        state = tasklist_daemon:is_app_pinned(client.class),
        handle_active_color = client.font_icon.color,
        text = "Pin App",
        on_release = function(self)
            if tasklist_daemon:is_app_pinned(client.class) then
                self:turn_off()
                tasklist_daemon:remove_pinned_app(client.class)
            else
                self:turn_on()
                tasklist_daemon:add_pinned_app(client)
            end
        end
    }

    local menu = mwidget {
        client_icon_button,
        pin_to_taskbar_button,
        mwidget.separator(),
        mwidget.sub_menu_button {
            text = "Layer",
            sub_menu = layer_menu
        },
        mwidget.sub_menu_button {
            text = "Maximize",
            sub_menu = maximize_menu
        },
        client_checkbox_button(client, "minimized", "Minimize"),
        client_checkbox_button(client, "fullscreen", "Fullscreen"),
        client_checkbox_button(client, "titlebar", "Titlebar", function()
            awful.titlebar.toggle(client)
        end),
        client_checkbox_button(client, "sticky", "Sticky"),
        client_checkbox_button(client, "hidden", "Hidden"),
        client_checkbox_button(client, "floating", "Floating"),
        mwidget.button {
            text = "Close",
            on_release = function()
                client:kill()
            end
        }
    }

    for index, action in ipairs(client.actions) do
        menu:add(mwidget.button {
            text = action.name,
            on_release = function()
                action.launch()
            end
        }, 3 + index)

        if index == #client.actions then
            menu:add(mwidget.separator(), 4 + index)
        end
    end

    -- At the time this funciton runs client.custom_titlebar is still nil
    -- so check if that property change and if so remove the titlebar toggle button
    client:connect_signal("property::custom_titlebar", function()
        if client.custom_titlebar == true then
            menu:remove(6)
        end
    end)

    return menu
end

function client_menu.mt:__call(...)
    return new(...)
end

return setmetatable(client_menu, client_menu.mt)
