require(... .. ".ui.apps.welcome")
require(... .. ".ui.desktop")
require(... .. ".ui.popups.brightness")
require(... .. ".ui.popups.keyboard_layout")
require(... .. ".ui.popups.loading")
require(... .. ".ui.popups.lock")
require(... .. ".ui.popups.volume")
require(... .. ".ui.notifications")
require(... .. ".ui.titlebar")
require(... .. ".ui.wibar")

local action_panel = require(... .. ".ui.panels.action")
local info_panel = require(... .. ".ui.panels.info")
local notification_panel = require(... .. ".ui.panels.notification")
local power_popup = require(... .. ".ui.popups.power")
local cpu_popup = require(... .. ".ui.panels.action.info.cpu")
local ram_popup = require(... .. ".ui.panels.action.info.ram")
local disk_popup = require(... .. ".ui.panels.action.info.disk")
local audio_popup = require(... .. ".ui.panels.action.info.audio")
local wifi_popup = require(... .. ".ui.panels.action.dashboard.wifi")
local bluetooth_popup = require(... .. ".ui.panels.action.dashboard.bluetooth")

local capi = {
    client = client
}

capi.client.connect_signal("property::fullscreen", function(c)
    if c.fullscreen then
        action_panel:hide()
        info_panel:hide()
        notification_panel:hide()
        cpu_popup:hide()
        ram_popup:hide()
        disk_popup:hide()
        audio_popup:hide()
        wifi_popup:hide()
        bluetooth_popup:hide()
    end
end)

capi.client.connect_signal("focus", function(c)
    if c.fullscreen then
        action_panel:hide()
        info_panel:hide()
        notification_panel:hide()
        cpu_popup:hide()
        ram_popup:hide()
        disk_popup:hide()
        audio_popup:hide()
        wifi_popup:hide()
        bluetooth_popup:hide()
    end
end)

action_panel:connect_signal("visibility", function(self, visible)
    if visible == true then
        power_popup:hide()
        notification_panel:hide()
    else
        cpu_popup:hide()
        ram_popup:hide()
        disk_popup:hide()
        audio_popup:hide()
        wifi_popup:hide()
        bluetooth_popup:hide()
    end
end)

info_panel:connect_signal("visibility", function(self, visible)
    if visible == true then
        power_popup:hide()
    end
end)

notification_panel:connect_signal("visibility", function(self, visible)
    if visible == true then
        action_panel:hide()
        power_popup:hide()
    end
end)

power_popup:connect_signal("visibility", function(self, visible)
    if visible == true then
        action_panel:hide()
        info_panel:hide()
        notification_panel:hide()
    end
end)

cpu_popup:connect_signal("visibility", function(self, visible)
    if visible == true then
        ram_popup:hide()
        disk_popup:hide()
        audio_popup:hide()
        wifi_popup:hide()
        bluetooth_popup:hide()
    end
end)

ram_popup:connect_signal("visibility", function(self, visible)
    if visible == true then
        cpu_popup:hide()
        disk_popup:hide()
        audio_popup:hide()
        wifi_popup:hide()
        bluetooth_popup:hide()
    end
end)

disk_popup:connect_signal("visibility", function(self, visible)
    if visible == true then
        cpu_popup:hide()
        ram_popup:hide()
        audio_popup:hide()
        wifi_popup:hide()
        bluetooth_popup:hide()
    end
end)

audio_popup:connect_signal("visibility", function(self, visible)
    if visible == true then
        cpu_popup:hide()
        ram_popup:hide()
        disk_popup:hide()
        wifi_popup:hide()
        bluetooth_popup:hide()
    end
end)

wifi_popup:connect_signal("visibility", function(self, visible)
    if visible == true then
        cpu_popup:hide()
        ram_popup:hide()
        audio_popup:hide()
        disk_popup:hide()
        bluetooth_popup:hide()
    end
end)

bluetooth_popup:connect_signal("visibility", function(self, visible)
    if visible == true then
        cpu_popup:hide()
        ram_popup:hide()
        audio_popup:hide()
        disk_popup:hide()
        wifi_popup:hide()
    end
end)
