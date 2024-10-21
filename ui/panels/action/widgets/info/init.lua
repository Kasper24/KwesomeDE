-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local cpu_popup = require("ui.applets.cpu")
local ram_popup = require("ui.applets.ram")
local disk_popup = require("ui.applets.disk")
local audio_popup = require("ui.applets.audio")
local beautiful = require("beautiful")
local cpu_daemon = require("daemons.hardware.cpu")
local ram_daemon = require("daemons.hardware.ram")
local disk_daemon = require("daemons.hardware.disk")
local temperature_daemon = require("daemons.hardware.temperature")
local audio_daemon = require("daemons.hardware.audio")
local brightness_daemon = require("daemons.hardware.brightness")
local library = require("library")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable
local tonumber = tonumber

local info = {
	mt = {},
}

local function progress_bar(icon, on_release)
	local progress_bar = wibox.widget({
		widget = widgets.progressbar,
		forced_width = dpi(450),
		forced_height = dpi(10),
		shape = library.ui.rrect(),
		max_value = 100,
		bar_shape = library.ui.rrect(),
		background_color = beautiful.colors.surface,
		color = icon.color,
	})

	local icon = wibox.widget({
		widget = widgets.background,
		shape = library.ui.rrect(),
		bg = beautiful.colors.surface,
		{
			widget = widgets.text,
			id = "icon",
			forced_width = dpi(40),
			forced_height = dpi(40),
			halign = "center",
			size = 15,
			icon = icon,
		},
	})

	local widget = wibox.widget({
		layout = wibox.layout.fixed.horizontal,
		spacing = dpi(15),
		icon,
		{
			widget = wibox.container.place,
			valign = "center",
			progress_bar,
		},
	})

	if on_release ~= nil then
		local arrow = wibox.widget({
			widget = widgets.button.normal,
			forced_width = dpi(40),
			forced_height = dpi(40),
			on_release = function()
				on_release()
			end,
			{
				widget = widgets.text,
				color = beautiful.colors.on_background,
				size = 15,
				icon = beautiful.icons.chevron.right,
			},
		})
		widget:add(arrow)
		progress_bar.forced_width = dpi(390)
	end

	function widget:set_value(value)
		progress_bar.value = value
	end

	function widget:set_icon(new_icon)
		icon:get_children_by_id("icon")[1]:set_icon(new_icon)
	end

	return widget
end

local function cpu()
	local widget = progress_bar(beautiful.icons.microchip, function()
		cpu_popup:toggle()
	end)

	cpu_daemon:connect_signal("update::slim", function(self, value)
		widget:set_value(value)
	end)

	return widget
end

local function ram()
	local widget = progress_bar(beautiful.icons.memory, function()
		ram_popup:toggle()
	end)

	ram_daemon:connect_signal(
		"update",
		function(self, total, used, free, shared, buff_cache, available, total_swap, used_swap, free_swap)
			local used_ram_percentage = math.floor((used / total) * 100)
			widget:set_value(used_ram_percentage)
		end
	)

	return widget
end

local function disk()
	local widget = progress_bar(beautiful.icons.disc_drive, function()
		disk_popup:toggle()
	end)

	disk_daemon:connect_signal("partition", function(self, disk)
		if disk.mount == "/" then
			widget:set_value(tonumber(disk.perc))
		end
	end)

	return widget
end

local function audio()
	local slider = widgets.slider({
		forced_width = dpi(390),
		maximum = 100,
		bar_active_color = beautiful.icons.volume.off.color,
	})

	local icon = wibox.widget({
		widget = widgets.background,
		shape = library.ui.rrect(),
		bg = beautiful.colors.surface,
		{
			widget = widgets.text,
			id = "icon",
			forced_width = dpi(40),
			forced_height = dpi(40),
			halign = "center",
			size = 15,
			icon = beautiful.icons.volume.off,
		},
	})

	local arrow = wibox.widget({
		widget = widgets.button.normal,
		forced_width = dpi(40),
		forced_height = dpi(40),
		on_release = function()
			audio_popup:toggle()
		end,
		{
			widget = widgets.text,
			color = beautiful.colors.on_background,
			size = 15,
			icon = beautiful.icons.chevron.right,
		},
	})

	local widget = wibox.widget({
		layout = wibox.layout.fixed.horizontal,
		spacing = dpi(15),
		icon,
		slider,
		arrow,
	})

	slider:connect_signal("property::value", function(self, value)
		audio_daemon:get_default_sink():set_volume(value)
	end)

	local icon = icon:get_children_by_id("icon")[1]
	audio_daemon:connect_signal("sinks::default", function(self, sink)
		slider:set_value(sink.volume)

		if sink.mute or sink.volume == 0 then
			icon:set_icon(beautiful.icons.volume.off)
		elseif sink.volume <= 33 then
			icon:set_icon(beautiful.icons.volume.low)
		elseif sink.volume <= 66 then
			icon:set_icon(beautiful.icons.volume.normal)
		elseif sink.volume > 66 then
			icon:set_icon(beautiful.icons.volume.high)
		end
	end)

	return widget
end

local function brightness()
	local slider = widgets.slider({
		forced_width = dpi(420),
		minimum = 1,
		maximum = 100,
		bar_active_color = beautiful.icons.brightness.color,
	})

	local icon = wibox.widget({
		widget = widgets.background,
		shape = library.ui.rrect(),
		bg = beautiful.colors.surface,
		{
			widget = widgets.text,
			id = "icon",
			forced_width = dpi(40),
			forced_height = dpi(40),
			halign = "center",
			size = 15,
			icon = beautiful.icons.brightness,
		},
	})

	local widget = wibox.widget({
		layout = wibox.layout.fixed.horizontal,
		spacing = dpi(15),
		icon,
		slider,
	})

	slider:connect_signal("property::value", function(self, value)
		brightness_daemon:set_brightness(value)
	end)

	brightness_daemon:connect_signal("update", function(self, value)
		slider:set_value(value)
	end)

	return widget
end

local function temperature()
	local widget = progress_bar(beautiful.icons.thermometer.full)

	temperature_daemon:connect_signal("update", function(self, value)
		if value == nil then
			widget:set_icon(beautiful.icons.thermometer.quarter)
			widget:set_value(10)
		else
			if value == 0 then
				widget:set_icon(beautiful.icons.thermometer.quarter)
			elseif value <= 33 then
				widget:set_icon(beautiful.icons.thermometer.half)
			elseif value <= 66 then
				widget:set_icon(beautiful.icons.thermometer.three_quarter)
			elseif value > 66 then
				widget:set_icon(beautiful.icons.thermometer.full)
			end

			widget:set_value(value)
		end
	end)

	return widget
end

local function new()
	return wibox.widget({
		layout = wibox.layout.flex.vertical,
		spacing = dpi(15),
		cpu(),
		ram(),
		disk(),
		audio(),
		brightness(),
		temperature(),
	})
end

function info.mt:__call()
	return new()
end

return setmetatable(info, info.mt)
