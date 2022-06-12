-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local beautiful = require("beautiful")
local naughty = require("naughty")
local network_daemon = require("daemons.hardware.network")
local helpers = require("helpers")

local icons =
{
    "gnome-network-displays",
    "org.gnome.NetworkDisplays",
    "preferences-system-network",
    "networkmanager",
    "network-workgroup",
    "mate-network-properties",
    "cs-network"
}

network_daemon:connect_signal("wireless_state", function(self, state)
    if helpers.misc.should_show_notification() == true then
        local text = state == true and "Enabled" or "Disabled"
        local category = state == true and "network.connected" or "network.disconnected"
        local font_icon = state == true and beautiful.wifi_high_icon or beautiful.wifi_off_icon

        naughty.notification
        {
            app_font_icon = beautiful.router_icon,
            app_icon = icons,
            app_name = "Network Manager",
            font_icon = font_icon,
            icon = icons,
            title = "Wi-Fi",
            text = text,
            category = category
        }
    end
end)

network_daemon:connect_signal("access_point::connected", function(self, ssid, strength)
    local font_icon = ""
    if strength < 33 then
        font_icon = beautiful.wifi_low_icon
    elseif strength >= 33 then
        font_icon = beautiful.wifi_medium_icon
    elseif strength >= 66 then
        font_icon = beautiful.wifi_high_icon
    end

    if helpers.misc.should_show_notification() == true then
        naughty.notification
        {
            app_font_icon = beautiful.router_icon,
            app_icon = icons,
            app_name = "Network Manager",
            font_icon = font_icon,
            icon = icons,
            title = "Connection Established",
            text = "You are now connected to " .. ssid,
            category = "network.connected"
        }
    end
end)

network_daemon:connect_signal("scan_access_points::success", function(self)
    if helpers.misc.should_show_notification() == true then
        naughty.notification
        {
            app_font_icon = beautiful.router_icon,
            app_icon = icons,
            app_name = "Network Manager",
            font_icon = beautiful.signal_stream_icon,
            icon = icons,
            title = "Access point rescan",
            text = "Completed",
        }
    end
end)

network_daemon:connect_signal("scan_access_points::failed", function(self, error, error_code)
    if helpers.misc.should_show_notification() == true then
        naughty.notification
        {
            app_font_icon = beautiful.router_icon,
            app_icon = icons,
            app_name = "Network Manager",
            font_icon = beautiful.circle_exclamation_icon,
            icon = icons,
            title = "Failed to scan access points",
            text = helpers.string.trim(error),
            category = "network.error"
        }
    end
end)

network_daemon:connect_signal("add_connection::success", function(self, ssid)
    naughty.notification
    {
        app_font_icon = beautiful.router_icon,
        app_icon = icons,
        app_name = "Network Manager",
        font_icon = beautiful.circle_plus_icon,
        icon = icons,
        title = "Connection " .. ssid .. " added",
        text = "Success",
    }
end)

network_daemon:connect_signal("add_connection::failed", function(self, error, error_code)
    naughty.notification
    {
        app_font_icon = beautiful.router_icon,
        app_icon = icons,
        app_name = "Network Manager",
        font_icon = beautiful.circle_exclamation_icon,
        icon = icons,
        title = "Failed to add Connection",
        text = helpers.string.trim(error),
        category = "network.error"
    }
end)

network_daemon:connect_signal("activate_access_point::success", function(self, ssid)
    naughty.notification
    {
        app_font_icon = beautiful.router_icon,
        app_icon = icons,
        app_name = "Network Manager",
        font_icon = beautiful.toggle_on_icon,
        icon = icons,
        title = "Activated " .. ssid,
        text = "Success",
    }
end)

network_daemon:connect_signal("activate_access_point::failed", function(self, error, error_code)
    naughty.notification
    {
        app_font_icon = beautiful.router_icon,
        app_icon = icons,
        app_name = "Network Manager",
        font_icon = beautiful.circle_exclamation_icon,
        icon = icons,
        title = "Failed to activate access point",
        text = helpers.string.trim(error),
        category = "network.error"
    }
end)