-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local awful = require("awful")
local gtable = require("gears.table")
local wibox = require("wibox")
local pwidget = require("ui.widgets.popup")
local beautiful = require("beautiful")
local helpers = require("helpers")
local ui_daemon = require("daemons.system.ui")
local dpi = beautiful.xresources.apply_dpi
local capi = {
	awesome = awesome,
	client = client,
}

local animated_popup = {
	mt = {},
}

local function fake_widget(self)
	local image = wibox.widget.draw_to_image_surface(self.real_widget, self.maximum_width, self.maximum_height)
	if not self.fake_widget then
		self.fake_widget = wibox.widget({
			widget = wibox.widget.imagebox,
			forced_width = self.maximum_width,
			forced_height = self.maximum_height,
			horizontal_fit_policy = "fit",
			vertical_fit_policy = "fit",
			image = image,
		})
	else
		self.fake_widget.image = image
	end

	return self.fake_widget
end

local function animate_in(self)
	self.animation.pos = 1
	self.animation.easing = helpers.animation.easing.outExpo

	if self.animate_method == "forced_height" then
		if self.max_height then
			self.maximum_height = self.screen.workarea.height
		end
		self.animation:set(self.maximum_height)
	else
		if self.max_height then
			self.minimum_height = self.screen.workarea.height
			self.maximum_height = self.minimum_height
		end
		self.animation:set(self.maximum_width)
	end

	if self.animate_fake_widget then
		self.widget = fake_widget(self)
	end
end

local function animate_out(self)
	if self.animate_fake_widget then
		self.widget = fake_widget(self)
	end
	self.animation.easing = helpers.animation.easing.inExpo
	self.animation:set(1)
end

function animated_popup:show()
	if self.state == true then
		return
	end
	self.state = true

	if self.show_on_focused_screen then
		self.screen = awful.screen.focused()
	end
	self.visible = true
	if ui_daemon:get_animations() then
		animate_in(self)
	else
		if self.animate_method == "forced_height" then
			if self.max_height then
				self.maximum_height = self.screen.workarea.height
			end
			self.widget[self.animate_method] = self.maximum_height
		else
			if self.max_height then
				self.minimum_height = self.screen.workarea.height
				self.maximum_height = self.minimum_height
			end
			self.widget[self.animate_method] = self.maximum_width
		end
	end
	self:emit_signal("visibility", true)
end

function animated_popup:hide()
	if self.state == false then
		return
	end
	self.state = false

	if ui_daemon:get_animations() then
		animate_out(self)
	else
		self.visible = false
		self.widget[self.animate_method] = 1
	end
	self:emit_signal("visibility", false)
end

function animated_popup:toggle()
	if self.animation.state == true then
		return
	end
	if self.visible == false then
		self:show()
	else
		self:hide()
	end
end

local function new(args)
	args = args or {}

	local ret = pwidget(args)
	gtable.crush(ret, animated_popup, true)

	ret.state = false

	ret.minimum_width = args.minimum_width or 1
	ret.minimum_height = args.minimum_height or 1
	ret.maximum_width = args.maximum_width or 1
	ret.maximum_height = args.maximum_height or 1

	ret.animate_method = "forced_" .. (args.animate_method or "height")
	ret.max_height = args.max_height
	ret.hide_on_clicked_outside = args.hide_on_clicked_outside
	ret.show_on_focused_screen = args.show_on_focused_screen == nil and true or args.show_on_focused_screen
	ret.animate_fake_widget = args.animate_fake_widget == nil and true or args.animate_fake_widget
	ret.real_widget = args.widget

	if ret.animate_method == "forced_height" then
		ret.minimum_height = 1
	else
		ret.minimum_width = 1
	end

	ret.animation = helpers.animation:new({
		pos = 1,
		easing = helpers.animation.easing.outExpo,
		duration = 0.8,
		update = function(_, pos)
			ret.widget[ret.animate_method] = dpi(pos)
		end,
		signals = {
			["ended"] = function()
				-- We only changed the fake widget size, now update the real one
				ret.real_widget[ret.animate_method] = ret.widget[ret.animate_method]

				if ret.state == true then
					ret.widget = args.widget
				else
					ret.visible = false
				end
			end,
		},
	})

	capi.awesome.connect_signal("root::pressed", function()
		if ret.hide_on_clicked_outside then
			ret:hide()
		end
	end)

	capi.client.connect_signal("button::press", function()
		if ret.hide_on_clicked_outside then
			ret:hide()
		end
	end)

	return ret
end

function animated_popup.mt:__call(...)
	return new(...)
end

return setmetatable(animated_popup, animated_popup.mt)
