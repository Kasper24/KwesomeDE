-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gtimer = require("gears.timer")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local keyboard_layout_daemon = require("daemons.hardware.keyboard_layout")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi

local instance = nil

local function new()
	local icon = wibox.widget({
		widget = widgets.text,
		halign = "center",
		valign = "center",
		icon = beautiful.icons.keyboard,
		size = 15,
	})

	local text = wibox.widget({
		widget = widgets.text,
		halign = "center",
		valign = "center",
		size = 12,
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
		minimum_width = dpi(100),
		maximum_width = dpi(100),
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

	local show = false
	keyboard_layout_daemon:connect_signal("update", function(self, layout)
		if show == true then
			text:set_text(layout)
			widget:show()
			hide_timer:again()
		end
		show = true
	end)

	return widget
end

if not instance then
	instance = new()
end
return instance
