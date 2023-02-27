-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local lgi = require("lgi")
local awful = require("awful")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local bluetooth_daemon = require("daemons.hardware.bluetooth")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local capi = {
    awesome = awesome
}

local instance = nil

local function device_widget(device, path)
    local widget = nil
    local anim = nil

    local device_icon = wibox.widget {
        widget = wibox.widget.imagebox,
        forced_width = dpi(50),
        forced_height = dpi(50),
        image = helpers.icon_theme.get_icon_path(device:get_icon() or "bluetooth")
    }

    local name = wibox.widget {
        widget = widgets.text,
        forced_width = dpi(600),
        forced_height = dpi(30),
        halign = "left",
        size = 12,
        text = device:get_name(),
        color = beautiful.colors.on_surface
    }

    local cancel = wibox.widget {
        widget = widgets.button.text.normal,
        normal_bg = beautiful.colors.surface,
        text_normal_bg = beautiful.colors.on_surface,
        size = 12,
        text = "Cancel",
        on_release = function()
            widget:get_children_by_id("button")[1]:turn_off()
            anim:set(dpi(60))
        end
    }

    local connect_or_disconnect = wibox.widget {
        widget = widgets.button.text.normal,
        normal_bg = beautiful.colors.surface,
        text_normal_bg = beautiful.colors.on_surface,
        size = 12,
        text = device:is_connected() == true and "Disconnect" or "Connect",
        on_release = function()
            device:toggle_connect()
        end
    }

    local trust_or_untrust = wibox.widget {
        widget = widgets.button.text.normal,
        normal_bg = beautiful.colors.surface,
        text_normal_bg = beautiful.colors.on_surface,
        size = 12,
        text = device:is_trusted() == true and "Untrust" or "Trust",
        on_release = function()
            device:toggle_trust()
        end
    }

    local pair_or_unpair = wibox.widget {
        widget = widgets.button.text.normal,
        normal_bg = beautiful.colors.surface,
        text_normal_bg = beautiful.colors.on_surface,
        size = 12,
        text = device:is_paired() == true and "Unpair" or "Pair",
        on_release = function()
            device:toggle_pair()
        end
    }

    widget = wibox.widget {
        widget = wibox.container.constraint,
        mode = "exact",
        height = dpi(60),
        {
            widget = widgets.button.elevated.state,
            on_normal_bg = beautiful.colors.transparent,
            id = "button",
            on_release = function(self)
                if self._private.state == false then
                    capi.awesome.emit_signal("bluetooth_device_widget::expanded", widget)
                    anim:set(dpi(130))
                    self:turn_on()
                end
            end,
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(15),
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = dpi(15),
                    device_icon,
                    name
                },
                {
                    layout = wibox.layout.flex.horizontal,
                    spacing = dpi(15),
                    connect_or_disconnect,
                    trust_or_untrust,
                    pair_or_unpair,
                    cancel
                }
            }
        }
    }

    anim = helpers.animation:new{
        pos = dpi(60),
        duration = 0.2,
        easing = helpers.animation.easing.linear,
        update = function(self, pos)
            widget.height = pos
        end
    }

    bluetooth_daemon:connect_signal(path .. "_updated", function(self)
        connect_or_disconnect:set_text(device:is_connected() and "Disconnect" or "Connect")
        trust_or_untrust:set_text(device:is_trusted() and "Untrust" or "Trust")
        pair_or_unpair:set_text(device:is_paired() and "Unpair" or "Pair")
    end)

    capi.awesome.connect_signal("bluetooth_device_widget::expanded", function(toggled_on_widget)
        if toggled_on_widget ~= widget then
            widget:get_children_by_id("button")[1]:turn_off()
            anim:set(dpi(60))
        end
    end)

    return widget
end

local function new()
    local header = wibox.widget {
        widget = widgets.text,
        halign = "left",
        bold = true,
        color = beautiful.icons.bluetooth.off.color,
        text = "Bluetooth"
    }

    local scan = wibox.widget {
        widget = widgets.button.text.normal,
        text_normal_bg = beautiful.colors.on_background,
        icon = beautiful.icons.arrow_rotate_right,
        size = 15,
        on_release = function()
            bluetooth_daemon:scan()
        end
    }

    local settings = wibox.widget {
        widget = widgets.button.text.normal,
        text_normal_bg = beautiful.colors.on_background,
        icon = beautiful.icons.gear,
        size = 15,
        on_release = function()
            bluetooth_daemon:open_settings()
        end
    }

    local layout = wibox.widget {
        layout = widgets.overflow.vertical,
        forced_height = dpi(600),
        spacing = dpi(15),
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(10),
        step = 50
    }

    local no_bluetooth = wibox.widget {
        widget = widgets.text,
        halign = "center",
        icon = beautiful.icons.bluetooth.off,
        size = 100
    }

    local stack = wibox.widget {
        layout = wibox.layout.stack,
        top_only = true,
        layout,
        no_bluetooth
    }

    local seperator = wibox.widget {
        widget = widgets.background,
        forced_height = dpi(1),
        shape = helpers.ui.rrect(),
        bg = beautiful.colors.surface
    }

    bluetooth_daemon:connect_signal("new_device", function(self, device, path)
        local widget = device_widget(device, path)
        layout:add(widget)
        stack:raise_widget(layout)

        bluetooth_daemon:connect_signal(path .. "_removed", function(self)
            layout:remove_widgets(widget)
        end)
    end)

    bluetooth_daemon:connect_signal("state", function(self, state)
        if state == false then
            stack:raise_widget(no_bluetooth)
        end
    end)

    return widgets.animated_panel {
        ontop = true,
        visible = false,
        minimum_width = dpi(600),
        maximum_width = dpi(600),
        placement = function(widget)
            awful.placement.bottom_right(widget, {
                honor_workarea = true,
                honor_padding = true,
                attach = true,
                margins = { right = dpi(550)}
            })
        end,
        shape = helpers.ui.rrect(),
        bg = beautiful.colors.background,
        widget = wibox.widget {
            widget = wibox.container.margin,
            margins = dpi(25),
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(15),
                {
                    layout = wibox.layout.align.horizontal,
                    header,
                    nil,
                    {
                        layout = wibox.layout.fixed.horizontal,
                        spacing = dpi(15),
                        scan,
                        settings
                    }
                },
                seperator,
                stack
            }
        }
    }
end

if not instance then
    instance = new()
end
return instance
