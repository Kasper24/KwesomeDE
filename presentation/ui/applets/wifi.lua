-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local beautiful = require("beautiful")
local network_daemon = require("daemons.hardware.network")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local pairs = pairs
local capi = { awesome = awesome }

local wifi = { }
local instance = nil

function wifi:show(next_to)
    self.widget.screen = awful.screen.focused()
    self.widget:move_next_to(next_to)
    self.widget.visible = true
    self:emit_signal("visibility", true)
end

function wifi:hide()
    self.widget.visible = false
    self:emit_signal("visibility", false)
end

function wifi:toggle(next_to)
    if self.widget.visible then
        self:hide()
    else
        self:show(next_to)
    end
end

local function access_point_widget(layout, access_point, accent_color)
    local widget = nil

    local wifi_icon = widgets.text
    {
        halign = "left",
        font = beautiful.wifi_high_icon.font,
        size = 25,
        text =  access_point.strength > 66 and beautiful.wifi_high_icon.icon or
                access_point.strength > 33 and beautiful.wifi_medium_icon.icon or beautiful.wifi_low_icon.icon
    }

    local lock_icon = widgets.text
    {
        font = beautiful.lock_icon.font,
        size = 20,
        text =  beautiful.lock_icon.icon
    }

    local prompt = widgets.prompt
    {
        forced_width = dpi(450),
        obscure = true,
        text = access_point.password,
        icon_font = beautiful.lock_icon.font,
        icon = beautiful.lock_icon.icon,
        forced_height = dpi(50),
        paddings = dpi(15),
    }

    local toggle_password_button = widgets.checkbox
    {
        on_by_default = true,
        on_turn_on = function()
            prompt:set_obscure(true)
        end,
        on_turn_off = function()
            prompt:set_obscure(false)
        end
    }

    local name = widgets.text
    {
        width = dpi(600),
        height = dpi(30),
        halign = "left",
        size = 12,
        text =  network_daemon:is_access_point_active(access_point)
                and access_point.ssid .. " - Activated"
                or access_point.ssid,
        color = beautiful.colors.on_surface,
    }

    local auto_connect_text = widgets.text
    {
        valign = "center",
        size = 12,
        color = beautiful.colors.on_surface,
        text =  "Auto Connect: "
    }

    local auto_connect_checkbox = widgets.checkbox
    {
        valign = "center",
        on_by_default = true
    }

    local cancel = widgets.button.text.normal
    {
        normal_bg = beautiful.colors.surface,
        text_normal_bg = beautiful.colors.on_surface,
        size = 12,
        text = "Cancel",
        on_press = function()
            prompt:stop()
            widget:turn_off()
            widget.forced_height = dpi(60)
        end
    }

    local connect_or_disconnect = widgets.button.text.normal
    {
        normal_bg = beautiful.colors.surface,
        text_normal_bg = beautiful.colors.on_surface,
        size = 12,
        text = network_daemon:is_access_point_active(access_point) == true and "Disconnect" or "Connect",
        on_press = function()
            network_daemon:toggle_access_point(access_point, prompt:get_text(), auto_connect_checkbox:get_value())
        end
    }

    local spinning_circle = widgets.spinning_circle
    {
        forced_width = dpi(25),
        forced_height = dpi(25),
        thickness = dpi(10)
    }
    spinning_circle:abort()

    local connect_or_disconnect_stack = wibox.widget
    {
        widget = wibox.layout.stack,
        top_only = true,
        connect_or_disconnect,
        spinning_circle
    }

    network_daemon:connect_signal(access_point.hw_address .. "::state", function(self, new_state, old_state)
        name:set_text(access_point.ssid .. " - " .. network_daemon.device_state_to_string(new_state))

        if new_state ~= network_daemon.DeviceState.ACTIVATED then
            connect_or_disconnect:set_text("Connect")
        end

        if new_state == network_daemon.DeviceState.PREPARE then
            spinning_circle:start()
            connect_or_disconnect_stack:raise_widget(spinning_circle)
        elseif new_state == network_daemon.DeviceState.ACTIVATED then
            layout:remove_widgets(widget)
            layout:insert(1, widget)
            connect_or_disconnect:set_text("Disconnect")

            spinning_circle:abort()
            connect_or_disconnect_stack:raise_widget(connect_or_disconnect)

            prompt:stop()
            widget:turn_off()
            widget.forced_height = dpi(60)
        end
    end)

    network_daemon:connect_signal("access_point::connected", function(self, ssid, strength)
        spinning_circle:abort()
        connect_or_disconnect_stack:raise_widget(connect_or_disconnect)
    end)

    widget = widgets.button.elevated.state
    {
        on_normal_bg = beautiful.colors.background,
        on_hover_bg = beautiful.colors.background,
        on_press_bg = beautiful.colors.background,
        forced_height = dpi(65),
        on_press = function(self)
            if self._private.state == false then
                capi.awesome.emit_signal("access_point_widget::expanded", widget)
                prompt:start()
                self.forced_height = dpi(250)
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
                wifi_icon,
                name,
                lock_icon
            },
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(5),
                prompt.widget,
                toggle_password_button
            },
            {
                layout = wibox.layout.fixed.horizontal,
                auto_connect_text,
                auto_connect_checkbox,
            },
            {
                layout = wibox.layout.flex.horizontal,
                spacing = dpi(15),
                connect_or_disconnect_stack,
                cancel
            }
        }
    }

    capi.awesome.connect_signal("access_point_widget::expanded", function(toggled_on_widget)
        if toggled_on_widget ~= widget then
            prompt:stop()
            widget:turn_off()
            widget.forced_height = dpi(60)
        end
    end)

    return widget
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, wifi, true)

    ret._private = {}

    local header = widgets.text
    {
        halign = "left",
        bold = true,
        color = beautiful.random_accent_color(),
        text = "Wi-Fi"
    }

    local rescan = widgets.button.text.normal
    {
        text_normal_bg = beautiful.colors.on_background,
        size = 15,
        font = beautiful.arrow_rotate_right_icon.font,
        text = beautiful.arrow_rotate_right_icon.icon,
        on_press = function()
            network_daemon:scan_access_points()
        end
    }

    local settings = widgets.button.text.normal
    {
        text_normal_bg = beautiful.colors.on_background,
        size = 15,
        font = beautiful.gear_icon.font,
        text = beautiful.gear_icon.icon,
        on_press = function()
            network_daemon:open_settings()
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

    local no_wifi = widgets.text
    {
        color = beautiful.random_accent_color(),
        halign = "center",
        size = 100,
        font = beautiful.wifi_off_icon.font,
        text = beautiful.wifi_off_icon.icon
    }

    local stack = wibox.widget
    {
        layout = wibox.layout.stack,
        top_only = true,
        layout,
        no_wifi
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

    network_daemon:connect_signal("scan_access_points::success", function(self, access_points)
        layout:reset()
        for _, access_point in pairs(access_points) do
            if network_daemon:is_access_point_active(access_point) then
                layout:insert(1, access_point_widget(layout, access_point, accent_color))
            else
                layout:add(access_point_widget(layout, access_point, accent_color))
            end
        end
        stack:raise_widget(layout)
    end)

    network_daemon:connect_signal("wireless_state", function(self, state)
        if state == false then
            stack:raise_widget(no_wifi)
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
                        rescan,
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