-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local ghsape = require("gears.shape")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local action_panel = require("ui.panels.action")
local beautiful = require("beautiful")
local network_daemon = require("daemons.hardware.network")
local bluetooth_daemon = require("daemons.hardware.bluetooth")
local audio_daemon = require("daemons.hardware.audio")
local upower_daemon = require("daemons.hardware.upower")
local keyboard_layout_daemon = require("daemons.hardware.keyboard_layout")
local ui_daemon = require("daemons.system.ui")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi

local tray = {
	mt = {},
}

local function system_tray()
	local function placement(widget)
		if ui_daemon:get_bars_layout() == "vertical" then
			return awful.placement["bottom_left"](widget, {
				honor_workarea = true,
				honor_padding = true,
				attach = true,
				offset = { y = -dpi(160) },
			})
		else
			return awful.placement[ui_daemon:get_horizontal_bar_position() .. "_right"](widget, {
				honor_workarea = true,
				honor_padding = true,
				attach = true,
				offset = { x = -dpi(220) },
			})
		end
	end

	local system_tray = widgets.animated_popup({
		visible = false,
		ontop = true,
		minimum_width = dpi(200),
		maximum_width = dpi(200),
		maximum_height = dpi(200),
		animate_method = "height",
		hide_on_clicked_outside = true,
		placement = placement,
		shape = helpers.ui.rrect(),
		bg = beautiful.colors.background,
		widget = wibox.widget({
			widget = wibox.container.margin,
			margins = dpi(30),
			{
				widget = wibox.widget.systray,
				forced_height = dpi(200),
				horizontal = false,
			},
		}),
	})

	local button = wibox.widget({
		widget = widgets.button.state,
		forced_width = dpi(50),
		forced_height = dpi(50),
		on_color = beautiful.icons.envelope.color,
		on_press = function()
			system_tray:toggle()
		end,
		{
			widget = widgets.text,
			color = beautiful.icons.envelope.color,
			on_color = beautiful.colors.transparent,
			icon = beautiful.icons.chevron.down,
		},
	})

	system_tray:connect_signal("visibility", function(self, visibile)
		if visibile then
			button:turn_on()
		else
			button:turn_off()
		end
	end)

	return {
		widget = wibox.container.margin,
		margins = dpi(5),
		button,
	}
end

local function network()
	local widget = wibox.widget({
		widget = widgets.text,
		forced_width = dpi(30),
		forced_height = dpi(25),
		halign = "center",
		icon = beautiful.icons.network.wifi_off,
		color = beautiful.icons.envelope.color,
		on_color = beautiful.colors.transparent,
		size = 17,
	})

	network_daemon:connect_signal("wireless_state", function(self, state)
		if state then
			widget:set_icon(beautiful.icons.network.wifi_off)
		else
			widget:set_icon(beautiful.icons.router)
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
	local widget = wibox.widget({
		widget = widgets.text,
		forced_width = dpi(30),
		forced_height = dpi(30),
		halign = "center",
		icon = beautiful.icons.bluetooth.on,
		color = beautiful.icons.envelope.color,
		on_color = beautiful.colors.transparent,
		size = 17,
	})

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
	local widget = wibox.widget({
		widget = widgets.text,
		forced_width = dpi(30),
		forced_height = dpi(30),
		halign = "center",
		icon = beautiful.icons.volume.normal,
		color = beautiful.icons.envelope.color,
		on_color = beautiful.colors.transparent,
		size = 17,
	})

	audio_daemon:connect_signal("sinks::default", function(self, sink)
		if sink.mute or sink.volume == 0 then
			widget:set_icon(beautiful.icons.volume.off)
		elseif sink.volume <= 33 then
			widget:set_icon(beautiful.icons.volume.low)
		elseif sink.volume <= 66 then
			widget:set_icon(beautiful.icons.volume.normal)
		elseif sink.volume > 66 then
			widget:set_icon(beautiful.icons.volume.high)
		end
	end)

	return widget
end

local function keyboard_layout()
	local text = wibox.widget({
		widget = widgets.text,
		halign = "center",
		color = beautiful.colors.background_no_opacity,
		on_color = beautiful.icons.envelope.color,
		text = keyboard_layout_daemon:get_current_layout_as_text(),
		size = 15,
		bold = true,
	})

	local widget = wibox.widget({
		widget = widgets.background,
		forced_width = dpi(40),
		forced_height = dpi(40),
		color = beautiful.icons.envelope.color,
		on_color = beautiful.colors.background_no_opacity,
		shape = helpers.ui.rrect(),
		text,
	})

	keyboard_layout_daemon:connect_signal("update", function(self, layout)
		text:set_text(layout)
	end)

	return widget
end

local function custom_tray()
	local layout = wibox.widget({
		layout = ui_daemon:get_bars_layout() == "vertical" and wibox.layout.fixed.vertical
			or wibox.layout.fixed.horizontal,
		spacing = dpi(15),
		network(),
		bluetooth(),
		volume(),
		keyboard_layout(),
	})

	upower_daemon:connect_signal("battery::init", function(self, device)
		local battery_icon = widgets.battery_icon(device, {
			margins_vertical = dpi(7),
			color = beautiful.icons.envelope.color,
		})
		layout:insert(4, battery_icon)

		action_panel:connect_signal("visibility", function(self, visibility)
			if visibility == true then
				battery_icon:set_color(beautiful.colors.background_no_opacity)
			else
				battery_icon:set_color(beautiful.icons.envelope.color)
			end
		end)
	end)

	local widget = wibox.widget({
		widget = wibox.container.margin,
		margins = dpi(5),
		{
			widget = widgets.button.state,
			on_color = beautiful.icons.envelope.color,
			id = "button",
			on_release = function()
				action_panel:toggle()
			end,
			layout,
		},
	})

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
	return wibox.widget({
		layout = ui_daemon:get_bars_layout() == "vertical" and wibox.layout.fixed.vertical
			or wibox.layout.fixed.horizontal,
		system_tray(),
		custom_tray(),
	})
end

function tray.mt:__call()
	return new()
end

return setmetatable(tray, tray.mt)
