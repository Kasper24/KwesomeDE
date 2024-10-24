-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local awful = require("awful")
local gtimer = require("gears.timer")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local picom_daemon = require("daemons.system.picom")
local library = require("library")
local dpi = beautiful.xresources.apply_dpi

local instance = nil

local function new()
	local icon = wibox.widget({
		widget = widgets.text,
		halign = "center",
		valign = "center",
		icon = beautiful.icons.spraycan,
		color = beautiful.colors.accent,
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
		minimum_width = dpi(150),
		maximum_width = dpi(150),
		maximum_height = dpi(50),
		animate_fake_widget = false,
		shape = library.ui.rrect(),
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
	picom_daemon:connect_signal("state", function(self, state)
		if show == true then
			if state then
				text:set_text("Turned On")
			else
				text:set_text("Turned Off")
			end
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
