-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local widgets = require("ui.widgets")
local action_panel = require("ui.panels.action")
local notification_panel = require("ui.panels.notification")
local info_panel = require("ui.panels.info")
local app_launcher = require("ui.popups.app_launcher")
local screenshot_app = require("ui.apps.screenshot")
local record_app = require("ui.apps.record")
local hotkeys_popup = require("ui.popups.hotkeys")
local power_popup = require("ui.popups.power")
local theme_app = require("ui.apps.theme")
local beautiful = require("beautiful")
local ipairs = ipairs
local capi = {
    awesome = awesome,
    screen = screen,
    tag = tag
}

local recent_places_daemon = require("daemons.system.recent_places")

local instance = nil

local function recent_places_sub_menu(recent_places)
    local menu = widgets.menu {}

    for _, place in ipairs(recent_places) do
        menu:add(widgets.menu.button {
            text = place.title,
            on_press = function()
                awful.spawn("xdg-open " .. place.path, false)
            end
        })
    end

    local button = widgets.menu.sub_menu_button {
        icon = beautiful.icons.folder_open,
        text = "Recent Places",
        sub_menu = menu
    }

    return button
end

local function tag_sub_menu()
    local menu = widgets.menu {}

    for _, tag in ipairs(capi.screen.primary.tags) do
        local button = widgets.menu.checkbox_button {
            text = tag.name,
            handle_active_color = beautiful.icons.tag.color,
            on_press = function()
                tag:view_only()
            end
        }

        menu:add(button)

        tag:connect_signal("property::selected", function(t)
            if t.selected == true then
                button:turn_on()
            else
                button:turn_off()
            end
        end)
    end

    return menu
end

local function layout_sub_menu()
    local menu = widgets.menu {}

    local function create_layout_menu_for_tag(tag)
        menu:reset()

        for _, layout in ipairs(tag.layouts) do
            local button = widgets.menu.checkbox_button {
                text = layout.name,
                image = beautiful["layout_" .. (layout.name or "")],
                handle_active_color = beautiful.icons.table_layout.color,
                on_press = function()
                    tag.layout = layout
                end
            }

            menu:add(button)

            if tag.layout == layout then
                button:turn_on()
            else
                button:turn_off()
            end

            tag:connect_signal("property::layout", function()
                if tag.layout == layout then
                    button:turn_on()
                else
                    button:turn_off()
                end
            end)
        end
    end

    capi.tag.connect_signal("property::selected", function(tag)
        create_layout_menu_for_tag(tag)
    end)

    create_layout_menu_for_tag(awful.screen.focused().selected_tag)

    return menu
end

local function widget()
    local menu = widgets.menu {widgets.menu.button {
        icon = beautiful.icons.launcher,
        text = "Applicaitons",
        on_press = function()
            app_launcher:show()
        end
    }, widgets.menu.button {
        icon = beautiful.icons.industry,
        text = "Action Panel",
        on_press = function()
            action_panel:toggle()
        end
    }, widgets.menu.button {
        icon = beautiful.icons.message,
        text = "Notification Panel",
        on_press = function()
            notification_panel:toggle()
        end
    }, widgets.menu.button {
        icon = beautiful.icons.calendar,
        text = "Info Panel",
        on_press = function()
            info_panel:toggle()
        end
    }, widgets.menu.button {
        icon = beautiful.icons.keyboard,
        text = "Keybinds",
        on_press = function()
            hotkeys_popup.show_help()
        end
    }, widgets.menu.separator(), widgets.menu.button {
        icon = beautiful.icons.camera_retro,
        text = "Screenshot",
        on_press = function()
            screenshot_app:show()
        end
    }, widgets.menu.button {
        icon = beautiful.icons.video,
        text = "Record",
        on_press = function()
            record_app:show()
        end
    }, widgets.menu.separator(), widgets.menu.sub_menu_button {
        icon = beautiful.icons.tag,
        text = "Tag",
        sub_menu = tag_sub_menu()
    }, widgets.menu.sub_menu_button {
        icon = beautiful.icons.table_layout,
        text = "Layout",
        sub_menu = layout_sub_menu()
    }, widgets.menu.separator(), widgets.menu.button {
        icon = beautiful.icons.gear,
        text = "Settings",
        on_press = function()
            awful.spawn("dconf-editor", false)
        end
    }, widgets.menu.button {
        icon = beautiful.icons.spraycan,
        text = "Theme",
        on_press = function()
            theme_app:show()
        end
    }, widgets.menu.separator(), widgets.menu.button {
        icon = beautiful.icons.reboot,
        text = "Restart",
        on_press = function()
            capi.awesome.restart()
        end
    }, widgets.menu.button {
        icon = beautiful.icons.exit,
        text = "Exit",
        on_press = function()
            power_popup:show()
        end
    }}

    local added_recent_places_menu = false

    recent_places_daemon:connect_signal("update", function(self, recent_places)
        if added_recent_places_menu == true then
            menu:remove_widget(12)
            menu:remove_widget(13)
        end

        menu:add(widgets.menu.separator(), 12)
        menu:add(recent_places_sub_menu(recent_places), 13)

        added_recent_places_menu = true
    end)

    return menu
end

if not instance then
    instance = widget()
end
return instance
