-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local app = require("ui.apps.app")
local beautiful = require("beautiful")
local wifi_tab = require("ui.apps.settings.tabs.wifi")
local accounts_tab = require("ui.apps.settings.tabs.accounts")
local appearance_tab = require("ui.apps.settings.tabs.appearance")
local dpi = beautiful.xresources.apply_dpi

local instance = nil

local function tabs()
    -- local picture = wibox.widget {
    --     widget = widgets.profile,
    --     forced_height = dpi(50),
    --     forced_width = dpi(50),
    --     valign = "center",
    --     clip_shape = helpers.ui.rrect(),
    -- }

    -- local name = wibox.widget {
    --     widget = widgets.text,
    --     size = 15,
    --     italic = true,
    --     text = os.getenv("USER") .. "@" .. capi.awesome.hostname
    -- }

    -- local user = wibox.widget {
    --     layout = wibox.layout.fixed.horizontal,
    --     spacing = dpi(15),
    --     picture,
    --     name
    -- }

    -- local navbar = wibox.widget {
    --     widget = wibox.container.constraint,
    --     mode = "max",
    --     width = dpi(300),
    --     {
    --         layout = wibox.layout.fixed.vertical,
    --         spacing = dpi(30),
    --         user,
    --         tab_buttons
    --     }
    -- }
end

local function tab_button(navigator, id, icon, title)
    return wibox.widget {
        widget = widgets.button.elevated.state,
        halign = "left",
        on_normal_bg = beautiful.icons.computer.color,
        on_release = function()
            navigator:emit_signal("tab::select", id)
        end,
        {
            layout = wibox.layout.fixed.horizontal,
            spacing = dpi(15),
            {
                widget = widgets.text,
                size = 13,
                halign = "left",
                text_normal_bg = beautiful.colors.on_background,
                text_on_normal_bg = beautiful.colors.on_accent,
                icon = icon,
            },
            {
                widget = widgets.text,
                size = 13,
                halign = "left",
                text_normal_bg = beautiful.colors.on_background,
                text_on_normal_bg = beautiful.colors.on_accent,
                text = title,
            }
        }
    }

end

local function main()
    local title = wibox.widget {
        widget = widgets.text,
        bold = true,
        size = 15,
        text = "Settings"
    }

    local close_button = wibox.widget {
        widget = widgets.button.text.normal,
        forced_width = dpi(40),
        forced_height = dpi(40),
        text_normal_bg = beautiful.icons.computer.color,
        icon = beautiful.icons.xmark,
        on_release = function()
            SETTINGS_APP:hide()
        end
    }

    local navigator = wibox.widget {
        widget = widgets.vertical_navigator,
    }

    navigator:set_tabs {
        {
            {
                id = "wifi",
                button = tab_button(navigator, "wifi", beautiful.icons.network.wifi_high, "Wi-Fi"),
                tab = wifi_tab()
            },
            {
                id = "bluetooth",
                button = tab_button(navigator, "bluetooth", beautiful.icons.bluetooth.on, "Bluetooth"),
                tab = wifi_tab()
            },
        },
        {
            {
                id = "accounts",
                button = tab_button(navigator, "accounts", beautiful.icons.user, "Accounts"),
                tab = accounts_tab()
            },
        },
        {
            {
                id = "appearance",
                button = tab_button(navigator, "appearance", beautiful.icons.spraycan, "Appearance"),
                tab = appearance_tab()
            }
        }
    }

    local widget = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        {
            layout = wibox.layout.align.horizontal,
            title,
            nil,
            close_button
        },
        navigator
    }

    return widget
end

local function new()
    SETTINGS_APP = app {
        title ="Settings",
        class = "Settings",
        width = dpi(1650),
        height = dpi(1080),
    }

    local first = true
    SETTINGS_APP:connect_signal("visibility", function(self, visible)
        if visible == true and first == true then
            local widget = wibox.widget {
                widget = wibox.container.margin,
                margins = dpi(15),
                main()
            }

            SETTINGS_APP:set_widget(widget)
            first = false
        end
    end)

    return SETTINGS_APP
end

if not instance then
    instance = new()
end
return instance
