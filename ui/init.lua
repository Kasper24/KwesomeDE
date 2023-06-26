local awful = require("awful")
local widgets = require("ui.widgets")
local settings_app = require("ui.apps.settings")
local action_panel = require(... .. ".panels.action")
local info_panel = require(... .. ".panels.info")
local power_popup = require(... .. ".screens.power")
local lock_popup = require(... .. ".screens.lock")
local cpu_popup = require(... .. ".applets.cpu")
local ram_popup = require(... .. ".applets.ram")
local disk_popup = require(... .. ".applets.disk")
local audio_popup = require(... .. ".applets.audio")
local wifi_popup = require(... .. ".applets.wifi")
local bluetooth_popup = require(... .. ".applets.bluetooth")
local system_daemon = require("daemons.system.system")
local ui_daemon = require("daemons.system.ui")
local helpers = require("helpers")
local capi = {
    screen = screen,
    client = client
}

require(... .. ".desktop")
require(... .. ".popups.hotkeys.qutebrowser")
require(... .. ".popups.hotkeys.ranger")
require(... .. ".popups.hotkeys.vim")
require(... .. ".notifications")
require(... .. ".quick_notifications")
require(... .. ".titlebar")
require(... .. ".wibar")

system_daemon:connect_signal("version::new::single", function()
    settings_app:connect_signal("managed", function()
        SETTINGS_APP_NAVIGATOR:select("about")
    end)
    settings_app:show()
end)

capi.client.connect_signal("request::manage", function(client)
    if lock_popup:is_visible() or power_popup:is_visible() then
        if client.fake_root ~= true then
            client.hidden = true
        end
    end
end)

capi.client.connect_signal("property::fullscreen", function(client)
    if client.fullscreen then
        action_panel:hide()
        info_panel:hide()
        cpu_popup:hide()
        ram_popup:hide()
        disk_popup:hide()
        audio_popup:hide()
        wifi_popup:hide()
        bluetooth_popup:hide()

        for screen in capi.screen do
            screen.left_wibar.ontop = false
            screen.top_wibar.ontop = false
        end
    else
        if #helpers.client.find({fullscreen = true}) == 0 then
            for screen in capi.screen do
                screen.left_wibar.ontop = true
                screen.top_wibar.ontop = true
            end
        end
    end
end)

capi.client.connect_signal("focus", function(client)
    if client.fullscreen then
        action_panel:hide()
        info_panel:hide()
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

power_popup:connect_signal("visibility", function(self, visible)
    if visible == true then
        action_panel:hide()
        info_panel:hide()
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

power_popup:connect_signal("visibility", function(self, visibie)
    for s in capi.screen do
        if visibie and s ~= awful.screen.focused() then
            s.screen_mask.visible = true
        elseif visibie == false then
            s.screen_mask.visible = false
        end
    end

    if visibie then
        for _, client in ipairs(capi.client.get()) do
            if client.fake_root ~= true then
                client.hidden = true
            end
        end
    else
        for _, client in ipairs(capi.client.get()) do
            client.hidden = false
        end
    end
end)

lock_popup:connect_signal("visibility", function(self, visibie)
    for s in capi.screen do
        if visibie then
            if s ~= awful.screen.focused() then
                s.screen_mask.visible = true
            end
            s.left_wibar.ontop = false
            s.top_wibar.ontop = false
        else
            s.screen_mask.visible = false
            if #helpers.client.find({fullscreen = true}) == 0 then
                s.left_wibar.ontop = true
                s.top_wibar.ontop = true
            end
        end
    end

    if visibie then
        for _, client in ipairs(capi.client.get()) do
            if client.fake_root ~= true then
                client.hidden = true
            end
        end
    else
        for _, client in ipairs(capi.client.get()) do
            client.hidden = false
        end
    end
end)

awful.screen.connect_for_each_screen(function(s)
    s.screen_mask = widgets.screen_mask(s)
end)

if DEBUG ~= true and helpers.misc.is_restart() == false then
    if ui_daemon:get_show_lockscreen_on_login() then
        lock_popup:show()
    else
        require(... .. ".screens.loading")
    end
end
