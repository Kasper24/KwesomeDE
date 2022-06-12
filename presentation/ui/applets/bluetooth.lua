-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local lgi = require("lgi")
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local beautiful = require("beautiful")
local bluetooth_daemon = require("daemons.hardware.bluetooth")
local helpers = require("helpers")
local icon_theme = require("services.icon_theme")
local dpi = beautiful.xresources.apply_dpi
local capi = { awesome = awesome }

local bluetooth = { }
local instance = nil

function bluetooth:show(next_to)
    self.widget.screen = awful.screen.focused()
    self.widget:move_next_to(next_to)
    self.widget.visible = true
    self:emit_signal("visibility", true)
end

function bluetooth:hide()
    self.widget.visible = false
    self:emit_signal("visibility", false)
end

function bluetooth:toggle(next_to)
    if self.widget.visible then
        self:hide()
    else
        self:show(next_to)
    end
end

local function device_widget(device, path, layout, accent_color)
    local widget = nil

    local device_icon = wibox.widget
    {
        widget = wibox.widget.imagebox,
        forced_width = dpi(50),
        forced_height = dpi(50),
        image = icon_theme:get_icon_path(device.Icon or "bluetooth")
    }

    local name = widgets.text
    {
        width = dpi(600),
        height = dpi(30),
        halign = "left",
        size = 12,
        text = device.Name,
        color = beautiful.colors.on_surface,
    }

    local cancel = widgets.button.text.normal
    {
        normal_bg = beautiful.colors.surface,
        text_normal_bg = beautiful.colors.on_surface,
        size = 12,
        text = "Cancel",
        on_press = function()
            widget:turn_off()
            widget.forced_height = dpi(60)
        end
    }

    local connect_or_disconnect = widgets.button.text.normal
    {
        normal_bg = beautiful.colors.surface,
        text_normal_bg = beautiful.colors.on_surface,
        size = 12,
        text = device.Connected == true and "Disconnect" or "Connect",
        on_press = function()
            if device.Connected == true then
                device:DisconnectAsync()
            else
                device:ConnectAsync()
            end
        end
    }

    local trust_or_untrust = widgets.button.text.normal
    {
        normal_bg = beautiful.colors.surface,
        text_normal_bg = beautiful.colors.on_surface,
        size = 12,
        text = device.Trusted == true and "Untrust" or "Trust",
        on_press = function()
            local is_trusted = device.Trusted
            device:Set("org.bluez.Device1", "Trusted", lgi.GLib.Variant("b", not is_trusted))
            device.Trusted = {signature = "b", value = not is_trusted}
        end
    }

    local pair_or_unpair = widgets.button.text.normal
    {
        normal_bg = beautiful.colors.surface,
        text_normal_bg = beautiful.colors.on_surface,
        size = 12,
        text = device.Paired == true and "Unpair" or "Pair",
        on_press = function()
            if device.Paired == true then
                device:PairAsync()
            else
                device:CancelPairingAsync()
            end
        end
    }

    widget = widgets.button.elevated.state
    {
        forced_height = dpi(60),
        on_normal_bg = beautiful.colors.background,
        on_hover_bg = beautiful.colors.background,
        on_press_bg = beautiful.colors.background,
        on_press = function(self)
            if self._private.state == false then
                capi.awesome.emit_signal("bluetooth_device_widget::expanded", widget)
                self.forced_height = dpi(130)
                self:turn_on()
            end
        end,
        child =
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(15),
                device_icon,
                name,
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

    bluetooth_daemon:connect_signal(path .. "_removed", function(self)
        layout:remove_widgets(widget)
    end)

    bluetooth_daemon:connect_signal(path .. "_updated", function(self)
        connect_or_disconnect.text = device.Connected and "Disconnect" or "Connect"
        trust_or_untrust.text = device.Trusted and "Untrust" or "Trust"
        pair_or_unpair.text = device.Paired and "Unpair" or "Pair"
    end)


    capi.awesome.connect_signal("bluetooth_device_widget::expanded", function(toggled_on_widget)
        if toggled_on_widget ~= widget then
            widget:turn_off()
            widget.forced_height = dpi(60)
        end
    end)

    return widget
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, bluetooth, true)

    ret._private = {}

    local header = widgets.text
    {
        halign = "left",
        bold = true,
        color = beautiful.random_accent_color(),
        text = "Bluetooth"
    }

    local scan = widgets.button.text.normal
    {
        text_normal_bg = beautiful.colors.on_background,
        size = 15,
        font = beautiful.arrow_rotate_right_icon.font,
        text = beautiful.arrow_rotate_right_icon.icon,
        on_press = function()
            bluetooth_daemon:scan()
        end
    }

    local settings = widgets.button.text.normal
    {
        text_normal_bg = beautiful.colors.on_background,
        size = 15,
        font = beautiful.gear_icon.font,
        text = beautiful.gear_icon.icon,
        on_press = function()
            bluetooth_daemon:open_settings()
        end
    }

    local layout = wibox.widget
    {
        layout = widgets.overflow.vertical,
        forced_height = dpi(600),
        spacing = dpi(15),
        scrollbar_widget =
        {
            widget = wibox.widget.separator,
            shape = helpers.ui.rrect(beautiful.border_radius),
        },
        scrollbar_width = dpi(10),
        step = 50,
    }

    local no_bluetooth = widgets.text
    {
        color = beautiful.random_accent_color(),
        halign = "center",
        size = 100,
        font = beautiful.bluetooth_off_icon.font,
        text = beautiful.bluetooth_off_icon.icon
    }

    local stack = wibox.widget
    {
        layout = wibox.layout.stack,
        top_only = true,
        layout,
        no_bluetooth
    }

    local seperator = wibox.widget
    {
        widget = wibox.widget.separator,
        forced_width = dpi(1),
        forced_height = dpi(1),
        shape = helpers.ui.rrect(beautiful.border_radius),
        orientation = "horizontal",
        color = beautiful.colors.surface
    }

    local accent_color = beautiful.random_accent_color()

    bluetooth_daemon:connect_signal("new_device", function(self, device, path)
        layout:add(device_widget(device, path, layout, accent_color))
        stack:raise_widget(layout)
    end)

    bluetooth_daemon:connect_signal("state", function(self, state)
        if state == false then
            stack:raise_widget(no_bluetooth)
        end
    end)

    ret.widget = awful.popup
    {
        bg = beautiful.colors.background,
        ontop = true,
        visible = false,
        minimum_width = dpi(600),
        maximum_width = dpi(600),
        shape = helpers.ui.rrect(beautiful.border_radius),
        widget =
        {
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

    return ret
end

if not instance then
    instance = new()
end
return instance