-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local app = require("ui.apps.app")
local beautiful = require("beautiful")
local tab_button = require("ui.apps.settings.tab_button")
local wifi_tab = require("ui.apps.settings.tabs.wifi")
local bluetooth_tab = require("ui.apps.settings.tabs.bluetooth")
local accounts_tab = require("ui.apps.settings.tabs.accounts")
local appearance_tab = require("ui.apps.settings.tabs.appearance")
local about_tab = require("ui.apps.settings.tabs.about")
local network_daemon = require("daemons.hardware.network")
local bluetooth_daemon = require("daemons.hardware.bluetooth")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local capi = {
    awesome = awesome
}

local instance = nil

local function main()
    local user = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15),
        {
            widget = widgets.profile,
            forced_height = dpi(50),
            forced_width = dpi(50),
            valign = "center",
            clip_shape = helpers.ui.rrect(),
        },
        {
            widget = widgets.text,
            size = 15,
            italic = true,
            text = os.getenv("USER") .. "@" .. capi.awesome.hostname
        }
    }

    local navigator = wibox.widget {
        widget = widgets.navigator.vertical,
        buttons_header = user
    }

    navigator:set_tabs {
        {
            {
                id = "wifi",
                button = tab_button(navigator, "wifi", beautiful.icons.network.wifi_high, "Wi-Fi", function()
                    network_daemon:scan_access_points()
                end),
                tab = wifi_tab()
            },
            {
                id = "bluetooth",
                button = tab_button(navigator, "bluetooth", beautiful.icons.bluetooth.on, "Bluetooth", function()
                    bluetooth_daemon:scan()
                end),
                tab = bluetooth_tab()
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
        },
        {
            {
                id = "about",
                button = tab_button(navigator, "about", beautiful.icons.computer, "About"),
                tab = about_tab()
            }
        }
    }

    return navigator
end

local function new()
    SETTINGS_APP = app {
        title ="Settings",
        class = "Settings",
        width = dpi(1650),
        height = dpi(1080),
        show_titlebar = true,
        widget_fn = function ()
            return main()
        end
    }

    return SETTINGS_APP
end

if not instance then
    instance = new()
end
return instance
