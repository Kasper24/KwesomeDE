local naughty = require("naughty")
local network_manager_daemon = require("daemons.hardware.network_manager")
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

-- network_daemon:connect_signal("wired::disconnected", function(self)
--     if show == true then
--         naughty.notification
--         {
--             app_icon = icons,
--             app_name = "Network Manager",
--             icon = icons,
--             title = "Connection Disconnected",
--             text = "Ethernet network has been disconnected"
--         }
--     end
--     show = true
-- end)

-- network_daemon:connect_signal("wired::connected", function(self, interface, healthy)
--     if show == true then
--         if healthy then
--             naughty.notification
--             {
--                 app_icon = icons,
--                 app_name = "Network Manager",
--                 icon = icons,
--                 title = "Connection Established",
--                 text = "Connected to internet with <b>\"" .. interface .. "\"</b>"
--             }
--         end
--     end
--     show = true
-- end)

network_manager_daemon:connect_signal("wireless_state", function(self, state, ssid)
    if helpers.misc.should_show_notification() == true then
        local title = state == true and "Connection Established" or "Connection Disconnected"
        local text = state == true and "You are now connected to " .. ssid or "Wi-Fi network has been disconnected"
        local category = state == true and "network.connected" or "network.disconnected"

        naughty.notification
        {
            app_icon = icons,
            app_name = "Network Manager",
            icon = icons,
            title = title,
            text = text,
            category = category
        }
    end
end)