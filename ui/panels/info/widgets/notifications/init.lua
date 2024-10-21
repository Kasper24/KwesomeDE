-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local gstring = require("gears.string")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local notifications_daemon = require("daemons.system.notifications")
local library = require("library")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable
local ipairs = ipairs
local string = string
local notifications = {
	mt = {},
}

local function notification_widget(notification, on_removed)
	local icon = nil
	if notification.font_icon == nil then
		icon = wibox.widget({
			widget = wibox.widget.imagebox,
			forced_width = dpi(40),
			forced_height = dpi(40),
			halign = "left",
			valign = "top",
			clip_shape = library.ui.rrect(),
			image = notification.icon,
		})
	else
		icon = wibox.widget({
			widget = widgets.text,
			halign = "left",
			valign = "top",
			icon = notification.font_icon,
			size = 30,
		})
	end

	local title = wibox.widget({
		widget = wibox.container.place,
		halign = "left",
		{
			widget = widgets.text,
			halign = library.string.contain_right_to_left_characters(notification.title) and "right" or "left",
			valign = "top",
			size = 15,
			bold = true,
			text = notification.title,
		},
	})

	local message = wibox.widget({
		widget = widgets.text,
		valign = "top",
		size = 15,
		text = gstring.xml_unescape(notification.message),
	})

	message.forced_height = message:get_height_for_width_at_dpi(250, 96)

	local time = wibox.widget({
		widget = widgets.text,
		id = "time",
		halign = "left",
		valign = "top",
		size = 12,
	})

	local actions = wibox.widget({
		layout = wibox.layout.flex.horizontal,
		spacing = dpi(15),
	})

	if notification.actions ~= nil then
		for _, action in ipairs(notification.actions) do
			local button = wibox.widget({
				widget = widgets.button.normal,
				-- forced_height = dpi(40),
				color = beautiful.colors.surface,
				on_release = function()
					action:invoke()
				end,
				{
					widget = widgets.text,
					color = beautiful.colors.on_surface,
					size = 12,
					text = action.name,
				},
			})
			actions:add(button)
		end
	end

	local widget = nil
	local dismiss = wibox.widget({
		widget = wibox.container.place,
		valign = "top",
		{
			widget = wibox.container.margin,
			margins = {
				left = dpi(10),
				bottom = dpi(10),
			},
			{
				widget = widgets.button.normal,
				forced_width = dpi(40),
				forced_height = dpi(40),
				on_release = function()
					on_removed(widget)
					notifications_daemon:remove_notification(notification)
					INFO_PANEL:dynamic_disconnect_signals("visibility")
				end,
				{
					widget = widgets.text,
					icon = beautiful.icons.xmark,
				},
			},
		},
	})

	widget = wibox.widget({
		widget = wibox.container.margin,
		margins = dpi(10),
		{
			layout = wibox.layout.align.horizontal,
			icon,
			{
				widget = wibox.container.margin,
				margins = {
					left = dpi(15),
				},
				{
					layout = wibox.layout.fixed.vertical,
					spacing = dpi(5),
					title,
					time,
					message,
					actions,
				},
			},
			dismiss,
		},
	})

	INFO_PANEL:dynamic_connect_signal("visibility", function(self, visible)
		if visible then
			time:set_text(library.string.to_time_ago(notification.time))
		end
	end)

	return widget
end

local function notification_group(notification)
	local icon = wibox.widget({
		widget = widgets.icon,
		size = 40,
		halign = "left",
		valign = "top",
		clip_shape = library.ui.rrect(),
		icon = notification.app_icon,
	})

	local title = wibox.widget({
		widget = widgets.text,
		halign = "left",
		text = notification.app_name:gsub("^%l", string.upper),
	})

	local widget = nil
	local button = wibox.widget({
		widget = widgets.button.state,
		forced_width = dpi(600),
		halign = "left",
		on_turn_on = function()
			widget.height = dpi(500000000)
		end,
		on_turn_off = function()
			widget.height = dpi(70)
		end,
		{
			layout = wibox.layout.fixed.horizontal,
			spacing = dpi(15),
			icon,
			title,
		},
	})

	local seperator = wibox.widget({
		widget = widgets.background,
		forced_height = dpi(1),
		shape = library.ui.rrect(),
		bg = beautiful.colors.surface,
	})

	local layout = wibox.widget({
		layout = wibox.layout.fixed.vertical,
		spacing = dpi(20),
	})

	widget = wibox.widget({
		widget = wibox.container.constraint,
		strategy = "max",
		height = dpi(70),
		{
			layout = wibox.layout.fixed.vertical,
			spacing = dpi(15),
			-- seperator,
			button,
			seperator,
			layout,
		},
	})

	return {
		widget = widget,
		layout = layout,
	}
end

local function new()
	local header = wibox.widget({
		widget = widgets.text,
		bold = true,
		text = "Notifications",
	})

	local clear_notifications = wibox.widget({
		widget = widgets.button.normal,
		forced_width = dpi(50),
		forced_height = dpi(50),
		on_release = function()
			notifications_daemon:remove_all_notifications()
			INFO_PANEL:dynamic_disconnect_signals("visibility")
		end,
		{
			widget = widgets.text,
			icon = beautiful.icons.trash,
			color = beautiful.colors.on_background
		},
	})

	local empty_notifications = wibox.widget({
		widget = wibox.container.margin,
		margins = {
			top = dpi(175),
		},
		{
			layout = wibox.layout.fixed.vertical,
			spacing = dpi(15),
			{
				widget = widgets.text,
				halign = "center",
				icon = beautiful.icons.bell,
				size = 50,
			},
			{
				widget = widgets.text,
				halign = "center",
				size = 15,
				text = "No Notifications",
			},
		},
	})

	local scrollbox = wibox.widget({
		layout = wibox.layout.overflow.vertical,
		spacing = dpi(20),
		scrollbar_widget = widgets.scrollbar,
		scrollbar_width = dpi(10),
		step = 50,
	})

	local stack = wibox.widget({
		layout = wibox.layout.stack,
		top_only = true,
		empty_notifications,
		scrollbox,
	})

	local notification_groups = {}

	notifications_daemon:connect_signal("display::panel", function(self, notification)
		if notification.app_name ~= nil then
			if notification_groups[notification.app_name] == nil then
				notification_groups[notification.app_name] = notification_group(notification)
				scrollbox:insert(1, notification_groups[notification.app_name].widget)
			end
			notification_groups[notification.app_name].layout:insert(
				1,
				notification_widget(notification, function(widget)
					notification_groups[notification.app_name].layout:remove_widgets(widget)

					if #notification_groups[notification.app_name].layout.children == 0 then
						scrollbox:remove_widgets(notification_groups[notification.app_name].widget)
						notification_groups[notification.app_name] = nil
					end
				end)
			)

			scrollbox:remove_widgets(notification_groups[notification.app_name].widget)
			scrollbox:insert(1, notification_groups[notification.app_name].widget)
		end

		stack:raise_widget(scrollbox)
	end)

	notifications_daemon:connect_signal("empty", function(self)
		notification_groups = {}
		scrollbox:reset()
		stack:raise_widget(empty_notifications)
	end)

	return wibox.widget({
		layout = wibox.layout.fixed.vertical,
		spacing = dpi(10),
		{
			layout = wibox.layout.align.horizontal,
			expand = "none",
			header,
			nil,
			clear_notifications,
		},
		stack,
	})
end

function notifications.mt:__call()
	return new()
end

return setmetatable(notifications, notifications.mt)
