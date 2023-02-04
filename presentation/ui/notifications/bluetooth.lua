-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local beautiful = require("beautiful")
local naughty = require("naughty")
local bluetooth_daemon = require("daemons.hardware.bluetooth")
local helpers = require("helpers")

local bluetooth_icons = {"bluetooth", "bluetooth-48", "bluetooth-radio", "gnome-bluetooth", "preferences-bluetooth"}

bluetooth_daemon:connect_signal("state", function(self, state)
    if helpers.misc.should_show_notification() == true then
        local text = state == true and "Enabled" or "Disabled"
        local font_icon = state == true and beautiful.icons.bluetooth.on or beautiful.icons.bluetooth.off
        local icons = state == true and bluetooth_icons or
                          {"bluetooth-inactive", "blueman-disabled", "bluetooth", "bluetooth-48", "bluetooth-radio",
                           "gnome-bluetooth", "preferences-bluetooth"}
        local category = state == true and "device.added" or "device.removed"

        naughty.notification {
            app_font_icon = beautiful.icons.bluetooth.on,
            app_icon = bluetooth_icons,
            app_name = "Bluetooth",
            font_icon = font_icon,
            icon = icons,
            title = "Bluetooth",
            text = text,
            category = category
        }
    end
end)

bluetooth_daemon:connect_signal("device_event", function(self, event, device)
    local text = ""
    local category = nil

    if event == "Trusted" then
        text = device.Trusted == true and "Trusted" or "Untrusted"
    elseif event == "Paired" then
        text = device.Paired == true and "Paired" or "Unpairred"
    elseif event == "Connected" then
        text = device.Connected == true and "Connected" or "Disconnected"
        category = device.Connected == true and "device.added" or "device.removed"
    end

    naughty.notification {
        app_font_icon = beautiful.icons.bluetooth.on,
        app_icon = bluetooth_icons,
        app_name = "Bluetooth",
        icon = {device.Icon},
        title = device.Name,
        text = text,
        category = category
    }
end)
