-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local action_panel = require("ui.panels.action")
local beautiful = require("beautiful")
local network_daemon = require("daemons.hardware.network")
local bluetooth_daemon = require("daemons.hardware.bluetooth")
local pactl_daemon = require("daemons.hardware.pactl")
local upower_daemon = require("daemons.hardware.upower")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi

local tray = {
    mt = {}
}

local function system_tray()
    local system_tray = wibox.widget {
        widget = wibox.container.constraint,
        strategy = "max",
        width = dpi(0),
        {
            widget = wibox.container.margin,
            margins = {
                left = dpi(15),
                top = dpi(20)
            },
            {
                widget = wibox.widget.systray,
                base_size = dpi(25)
            }
        }
    }

    local system_tray_animation = helpers.animation:new{
        easing = helpers.animation.easing.linear,
        duration = 0.2,
        update = function(self, pos)
            system_tray.width = pos
        end
    }

    local arrow = wibox.widget {
        widget = wibox.container.margin,
        margins = dpi(5),
        {
            widget = widgets.button.text.state,
            forced_width = dpi(50),
            forced_height = dpi(50),
            icon = beautiful.icons.chevron_circle.left,
            on_turn_on = function(self)
                system_tray_animation:set(400)
                self:set_icon(beautiful.icons.chevron_circle.right)
            end,
            on_turn_off = function(self)
                system_tray_animation:set(0)
                self:set_icon(beautiful.icons.chevron_circle.left)
            end
        }
    }

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        arrow,
        system_tray
    }
end

local function network()
    local widget = wibox.widget {
        widget = widgets.text,
        halign = "center",
        icon = beautiful.icons.network.wifi_off,
        size = 17
    }

    network_daemon:connect_signal("wireless_state", function(self, state)
        if state then
            widget:set_icon(beautiful.icons.router)
        else
            widget:set_icon(beautiful.icons.network.wifi_off)
        end
    end)

    network_daemon:connect_signal("access_point::connected", function(self, ssid, strength)
        if strength < 33 then
            widget:set_icon(beautiful.icons.network.wifi_low)
        elseif strength >= 33 then
            widget:set_icon(beautiful.icons.network.wifi_medium)
        elseif strength >= 66 then
            widget:set_icon(beautiful.icons.network.wifi_high)
        end
    end)

    return widget
end

local function bluetooth()
    local widget = wibox.widget {
        widget = widgets.text,
        halign = "center",
        icon = beautiful.icons.bluetooth.on,
        size = 17
    }

    bluetooth_daemon:connect_signal("state", function(self, state)
        if state == true then
            widget:set_icon(beautiful.icons.bluetooth.on)
        else
            widget:set_icon(beautiful.icons.bluetooth.off)
        end
    end)

    return widget
end

local function volume()
    local widget = wibox.widget {
        widget = widgets.text,
        halign = "center",
        icon = beautiful.icons.volume.normal,
        size = 17
    }

    pactl_daemon:connect_signal("default_sinks_updated", function(self, device)
        if device.mute or device.volume == 0 then
            widget:set_icon(beautiful.icons.volume.off)
        elseif device.volume <= 33 then
            widget:set_icon(beautiful.icons.volume.low)
        elseif device.volume <= 66 then
            widget:set_icon(beautiful.icons.volume.normal)
        elseif device.volume > 66 then
            widget:set_icon(beautiful.icons.volume.high)
        end
    end)

    return widget
end

local function custom_tray()
    local layout = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(20),
        network(),
        bluetooth(),
        volume()
    }

    local startup = true
    upower_daemon:connect_signal("battery::update", function()
        if startup == true then
            layout:add(widgets.battery_icon())
            startup = false
        end
    end)

    local widget = wibox.widget {
        widget = wibox.container.margin,
        margins = dpi(5),
        {
            widget = widgets.button.elevated.state,
            id = "button",
            on_release = function()
                action_panel:toggle()
            end,
            child = layout
        }
    }

    action_panel:connect_signal("visibility", function(self, visibility)
        if visibility == true then
            widget:get_children_by_id("button")[1]:turn_on()
        else
            widget:get_children_by_id("button")[1]:turn_off()
        end
    end)

    return widget
end

local function new()
    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        system_tray(),
        custom_tray()
    }
end

function tray.mt:__call()
    return new()
end

return setmetatable(tray, tray.mt)