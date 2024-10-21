-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local awful = require("awful")
local gtimer = require("gears.timer")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local audio_daemon = require("daemons.hardware.audio")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi

local instance = nil

local function new()
	local icon = wibox.widget({
		widget = widgets.text,
		halign = "center",
		icon = beautiful.icons.volume.normal,
		size = 15,
	})

	local text = wibox.widget({
		widget = widgets.text,
		halign = "center",
		valign = "center",
		size = 12,
	})

	local slider = wibox.widget({
		widget = widgets.progressbar,
		forced_width = dpi(90),
		forced_height = dpi(10),
		shape = helpers.ui.rrect(),
		bar_shape = helpers.ui.rrect(),
		value = 0,
		max_value = 100,
		background_color = beautiful.colors.surface,
		color = beautiful.icons.volume.normal.color,
	})

	local widget = widgets.animated_popup({
		screen = awful.screen.focused(),
		visible = false,
		ontop = true,
		placement = function(c)
			awful.placement.centered(c, {
				offset = {
					y = 300,
				},
			})
		end,
		minimum_width = dpi(200),
		maximum_width = dpi(200),
		maximum_height = dpi(50),
		animate_fake_widget = false,
		shape = helpers.ui.rrect(),
		bg = beautiful.colors.background,
		widget = wibox.widget({
			widget = wibox.container.margin,
			margins = dpi(15),
			{
				widget = wibox.container.place,
				halign = "center",
				valign = "center",
				{
					layout = wibox.layout.fixed.horizontal,
					spacing = dpi(15),
					icon,
					slider,
					text,
				},
			},
		}),
	})

	local hide_timer = gtimer({
		single_shot = true,
		call_now = false,
		autostart = false,
		timeout = 1,
		callback = function()
			widget:hide()
		end,
	})

	local anim = helpers.animation:new({
		duration = 0.2,
		easing = helpers.animation.easing.linear,
		update = function(self, pos)
			slider.value = pos
		end,
	})

	local show = false
	audio_daemon:connect_signal("sinks::default", function(self, sink)
		if show == true then
			if sink.mute or sink.volume == 0 then
				icon:set_icon(beautiful.icons.volume.off)
			elseif sink.volume <= 33 then
				icon:set_icon(beautiful.icons.volume.low)
			elseif sink.volume <= 66 then
				icon:set_icon(beautiful.icons.volume.normal)
			elseif sink.volume > 66 then
				icon:set_icon(beautiful.icons.volume.high)
			end

			text:set_text(sink.volume)
			anim:set(sink.volume)

			widget:show()
			hide_timer:again()
		else
			anim:set(sink.volume / 100)
			show = true
		end
	end)

	return widget
end

if not instance then
	instance = new()
end
return instance
