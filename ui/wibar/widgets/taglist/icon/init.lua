-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local widgets = require("ui.widgets")
-- local tag_preview = require("ui.popups.tag_preview")
local beautiful = require("beautiful")
local ui_daemon = require("daemons.system.ui")
local library = require("library")
local dpi = beautiful.xresources.apply_dpi
local ipairs = ipairs
local capi = {
	client = client,
}

local icon = {
	mt = {},
}

local function tag_menu(tag)
	local menu = widgets.menu({
		widgets.menu.button({
			icon = tag.icon,
			text = tag.index,
			on_release = function()
				tag:view_only()
			end,
		}),
		widgets.menu.button({
			text = "Toggle tag",
			on_release = function()
				awful.tag.viewtoggle(tag)
			end,
		}),
		widgets.menu.button({
			text = "Move focused client",
			on_release = function()
				local focused_client = capi.client.focus
				if focused_client then
					focused_client:move_to_tag(tag)
				end
			end,
		}),
		widgets.menu.button({
			text = "Toggle focused client",
			on_release = function()
				local focused_client = capi.client.focus
				if focused_client then
					focused_client:toggle_tag(tag)
				end
			end,
		}),
		widgets.menu.button({
			text = "Move all clients",
			on_release = function()
				for _, client in ipairs(capi.client.get()) do
					client:move_to_tag(tag)
				end
			end,
		}),
		widgets.menu.button({
			text = "Toggle all clients",
			on_release = function()
				for _, client in ipairs(capi.client.get()) do
					client:toggle_tag(tag)
				end
			end,
		}),
	})

	return menu
end

local function update_taglist(self, tag)
	local clients = tag:clients()

	if #clients > 0 then
		local tag_has_non_skip_taskbar_client = false
		for _, client in ipairs(clients) do
			if not client.skip_taskbar then
				tag_has_non_skip_taskbar_client = true
				break
			end
		end
		if tag_has_non_skip_taskbar_client then
			self.indicator_animation:set(dpi(40))
		else
			self.indicator_animation:set(dpi(0))
		end
	else
		self.indicator_animation:set(dpi(0))
	end

	-- if (#clients == 1 and clients[1].skip_taskbar ~= true) or #clients > 1 then
	--     self.indicator_animation:set(dpi(40))
	-- else
	--     self.indicator_animation:set(dpi(0))
	-- end

	if tag.selected then
		self.widget.children[1]:turn_on()
	else
		self.widget.children[1]:turn_off()
	end
end

local function tag_widget(self, tag)
	local menu = tag_menu(tag)

	local button = wibox.widget({
		widget = widgets.button.state,
		id = "button",
		halign = "center",
		on_color = beautiful.colors.surface,
		-- on_hover = function()
		--     if #tag:clients() > 0 then
		--         tag_preview:show(tag, {
		--             wibox = awful.screen.focused().vertical_wibar,
		--             widget = self,
		--             offset = {
		--                 x = dpi(70),
		--                 y = dpi(70)
		--             }
		--         })
		--     end
		-- end,
		on_leave = function()
			-- tag_preview:hide()
		end,
		on_release = function()
			library.misc.tag_back_and_forth(tag.index)
			-- tag_preview:hide()
		end,
		on_secondary_release = function(self)
			local coords = nil
			if ui_daemon:get_bars_layout() == "horizontal" then
				coords = library.ui.get_widget_geometry_in_device_space(
					{ wibox = awful.screen.focused().horizontal_wibar },
					self
				)
				coords.y = coords.y + awful.screen.focused().horizontal_wibar.y
				if ui_daemon:get_horizontal_bar_position() == "top" then
					coords.y = coords.y + dpi(65)
				else
					coords.y = coords.y + -dpi(190)
				end
			else
				coords = library.ui.get_widget_geometry_in_device_space(
					{ wibox = awful.screen.focused().vertical_wibar },
					self
				)
				coords.x = coords.x + dpi(50)
			end

			menu:toggle({ coords = coords })
			-- tag_preview:hide()
		end,
		on_scroll_up = function()
			awful.tag.viewprev(tag.screen)
		end,
		on_scroll_down = function()
			awful.tag.viewnext(tag.screen)
		end,
		{
			widget = widgets.text,
			color = beautiful.colors.on_background,
			on_color = beautiful.colors.accent,
			icon = tag.icon,
		},
	})

	local indicator = wibox.widget({
		widget = widgets.background,
		forced_width = dpi(5),
		forced_height = dpi(5),
		id = "background",
		shape = library.ui.rrect(),
		bg = beautiful.colors.on_background,
	})

	local stack = wibox.widget({
		widget = wibox.layout.stack,
		button,
		{
			widget = wibox.container.place,
			indicator,
		},
	})

	local prop = nil
	if ui_daemon:get_bars_layout() == "vertical" or ui_daemon:get_bars_layout() == "vertical_horizontal" then
		prop = "forced_height"
		stack.children[2].halign = "right"
		stack.children[2].valign = "center"
	else
		prop = "forced_width"
		stack.children[2].halign = "center"
		stack.children[2].valign = "bottom"
	end

	self.indicator_animation = library.animation:new({
		duration = 0.2,
		easing = library.animation.easing.linear,
		update = function(self, pos)
			indicator[prop] = pos
		end,
	})

	self:set_widget(stack)
end

local function new(screen)
	-- Rotating imageboxes results in some cairo error, so if both bars are shown
	-- and the top bar is at the bottom, the tag-order in the ui will look reversed
	return awful.widget.taglist({
		screen = screen,
		filter = awful.widget.taglist.filter.all,
		layout = {
			layout = ui_daemon:get_bars_layout() == "horizontal" and wibox.layout.fixed.horizontal
				or wibox.layout.fixed.vertical,
		},
		widget_template = {
			widget = wibox.container.margin,
			forced_width = dpi(60),
			forced_height = dpi(60),
			create_callback = function(self, tag, index, tags)
				tag_widget(self, tag)
				update_taglist(self, tag)
			end,
			update_callback = function(self, tag, index, tags)
				update_taglist(self, tag)
			end,
		},
	})
end

function icon.mt:__call(...)
	return new(...)
end

return setmetatable(icon, icon.mt)
