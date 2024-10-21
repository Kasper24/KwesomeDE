-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local awful = require("awful")
local widgets = require("ui.widgets")
local action_panel = require("ui.panels.action")
local info_panel = require("ui.panels.info")
local app_launcher = require("ui.popups.app_launcher")
local screenshot_app = require("ui.apps.screenshot")
local record_app = require("ui.apps.record")
local hotkeys_popup = require("ui.popups.hotkeys")
local power_popup = require("ui.screens.power")
local settings_app = require("ui.apps.settings")
local beautiful = require("beautiful")
local helpers = require("helpers")
local ipairs = ipairs
local capi = {
    awesome = awesome,
    root = root,
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
            on_release = function()
                awful.spawn("xdg-open " .. place.path, false)
            end
        })
    end

    local button = widgets.menu.sub_menu_button {
        font_icon = beautiful.icons.folder_open,
        text = "Recent Places",
        sub_menu = menu
    }

    return button
end

local function tag_sub_menu()
    local menu = widgets.menu {}

    for _, tag in ipairs(capi.root.tags()) do
        local button = widgets.menu.checkbox_button {
            icon = tag.icon,
            text = tag.name,
            handle_active_color = tag.icon.color,
            on_release = function()
                tag:view_only()
            end
        }

        menu:add(button)

        if tag.selected == true then
            button:turn_on()
        else
            button:turn_off()
        end

        tag:connect_signal("property::selected", function(tag)
            if tag.selected == true then
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

    local layouts  = awful.screen.focused().selected_tag.layouts
    for _, layout in ipairs(layouts) do
        local widget = widgets.menu.checkbox_button {
            text = layout.name,
            image = beautiful["layout_" .. (layout.name or "")],
            handle_active_color = beautiful.icons.table_layout.color,
            on_release = function()
                awful.screen.focused().selected_tag.layout = layout
            end
        }

        if awful.screen.focused().selected_tag.layout.name == layout.name then
            widget:turn_on()
        end

        menu:connect_signal("layout::selected", function(self, name)
            if layout.name == name then
                widget:turn_on()
            else
                widget:turn_off()
            end
        end)

        menu:add(widget)
    end

    capi.tag.connect_signal("property::selected", function(tag)
        menu:emit_signal("layout::selected", tag.layout.name)
    end)

    capi.tag.connect_signal("property::layout", function(tag)
        menu:emit_signal("layout::selected", tag.layout.name)
    end)

    return menu
end

local function widget()
    local menu = widgets.menu {
        widgets.menu.button {
            font_icon = beautiful.icons.launcher,
            text = "Applicaitons",
            on_release = function()
                app_launcher:show()
            end
        },
        widgets.menu.button {
            font_icon = beautiful.icons.industry,
            text = "Action Panel",
            on_release = function()
                action_panel:toggle()
            end
        },
        widgets.menu.button {
            font_icon = beautiful.icons.calendar,
            text = "Info Panel",
            on_release = function()
                info_panel:toggle()
            end
        },
        widgets.menu.button {
            font_icon = beautiful.icons.keyboard,
            text = "Keybinds",
            on_release = function()
                hotkeys_popup.show_help()
            end
        },
        widgets.menu.separator(),
        widgets.menu.button {
            font_icon = beautiful.icons.camera_retro,
            text = "Screenshot",
            on_release = function()
                screenshot_app:show()
            end
        },
        widgets.menu.button {
            font_icon = beautiful.icons.video,
            text = "Record",
            on_release = function()
                record_app:show()
            end
        },
        widgets.menu.separator(),
        widgets.menu.sub_menu_button {
            font_icon = beautiful.icons.tag,
            text = "Tag",
            sub_menu = tag_sub_menu()
        },
        widgets.menu.sub_menu_button {
            font_icon = beautiful.icons.table_layout,
            text = "Layout",
            sub_menu = layout_sub_menu()
        },
        widgets.menu.separator(),
        widgets.menu.button {
            font_icon = beautiful.icons.gear,
            text = "Settings",
            on_release = function()
                settings_app:show()
            end
        },
        widgets.menu.separator(),
        widgets.menu.button {
            font_icon = beautiful.icons.reboot,
            text = "Restart",
            on_release = function()
                capi.awesome.restart()
            end
        },
        widgets.menu.button {
            font_icon = beautiful.icons.exit,
            text = "Exit",
            on_release = function()
                power_popup:show()
            end
        }
    }

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
