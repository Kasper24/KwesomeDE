-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("ui.widgets")
local ui_daemon = require("daemons.system.ui")
local library = require("library")
local dpi = beautiful.xresources.apply_dpi

local instance = nil

local calender = require("ui.panels.info.widgets.calendar")
local weather = require("ui.panels.info.widgets.weather")
local notifications = require("ui.panels.info.widgets.notifications")
local web_notifications = require("ui.panels.info.widgets.web_notifications")

local function horizontal_separator()
	return wibox.widget({
		widget = widgets.background,
		forced_width = dpi(1),
		shape = library.ui.rrect(),
		bg = beautiful.colors.surface,
	})
end

local function vertical_separator()
	return wibox.widget({
		widget = widgets.background,
		forced_height = dpi(1),
		shape = library.ui.rrect(),
		bg = beautiful.colors.surface,
	})
end

local function new()
	local function placement(widget)
		if ui_daemon:get_bars_layout() ~= "vertical" then
			if ui_daemon:get_widget_at_center() == "tasklist" then
				if ui_daemon:get_horizontal_bar_position() == "top" then
					return awful.placement.top_right(widget, {
						honor_workarea = true,
						honor_padding = true,
						attach = true,
					})
				else
					return awful.placement.bottom_right(widget, {
						honor_workarea = true,
						honor_padding = true,
						attach = true,
					})
				end
			else
				if ui_daemon:get_horizontal_bar_position() == "top" then
					return awful.placement.top(widget, {
						honor_workarea = true,
						honor_padding = true,
						attach = true,
					})
				else
					return awful.placement.bottom(widget, {
						honor_workarea = true,
						honor_padding = true,
						attach = true,
					})
				end
			end
		else
			return awful.placement.top_left(widget, {
				honor_workarea = true,
				honor_padding = true,
				attach = true,
			})
		end
	end

	local widget = wibox.widget({
		widget = wibox.container.margin,
		margins = dpi(25),
		{
			layout = wibox.layout.fixed.horizontal,
			spacing = dpi(15),
			{
				layout = wibox.layout.fixed.vertical,
				spacing = dpi(15),
				{
					widget = wibox.container.margin,
					forced_width = dpi(400),
					forced_height = dpi(500),
					calender,
				},
				vertical_separator(),
				{
					widget = wibox.container.margin,
					forced_width = dpi(400),
					notifications,
				},
			},
			horizontal_separator(),
			{
				layout = wibox.layout.fixed.vertical,
				spacing = dpi(15),
				{
					widget = wibox.container.margin,
					forced_height = dpi(500),
					weather,
				},
				vertical_separator(),
				{
					widget = wibox.container.margin,
					web_notifications,
				},
			},
		},
	})

	local animate_method = "width"
	if ui_daemon:get_widget_at_center() == "clock" and ui_daemon:get_bars_layout() ~= "vertical" then
		animate_method = "height"
	end

	INFO_PANEL = widgets.animated_popup({
		visible = false,
		ontop = true,
		minimum_width = dpi(1000),
		maximum_width = dpi(1000),
		max_height = true,
		animate_method = animate_method,
		hide_on_clicked_outside = true,
		placement = placement,
		shape = library.ui.rrect(),
		bg = beautiful.colors.background,
		widget = widget,
	})

	return INFO_PANEL
end

if not instance then
	instance = new()
end
return instance
