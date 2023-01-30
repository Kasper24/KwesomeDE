-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local gtable = require("gears.table")
local twidget = require("presentation.ui.widgets.text")
local ebwidget = require("presentation.ui.widgets.button.elevated")
local beautiful = require("beautiful")
local helpers = require("helpers")
local setmetatable = setmetatable
local math = math

local text_button_normal = { mt = {} }

local properties =
{
	"text_bg", "text_hover_bg", "text_press_bg"
}

local text_properties =
{
	"bold", "italic", "size",
	"color", "text", "icon",
	"halign", "valign", "font"
}

local function build_properties(prototype, prop_names)
    for _, prop in ipairs(prop_names) do
        if not prototype["set_" .. prop] then
            prototype["set_" .. prop] = function(self, value)
                if self._private[prop] ~= value then
                    self._private[prop] = value
                    self:emit_signal("widget::redraw_needed")
                    self:emit_signal("property::"..prop, value)
                end
                return self
            end
        end
        if not prototype["get_" .. prop] then
            prototype["get_" .. prop] = function(self)
                return self._private[prop]
            end
        end
    end
end

local function build_text_properties(prototype, prop_names)
    for _, prop in ipairs(prop_names) do
		if not prototype["set_" .. prop] then
			prototype["set_" .. prop] = function(self, value)
				local text_widget = self.children[1].children[1].children[1]
				text_widget["set_" .. prop](text_widget, value)
			end
		end
		if not prototype["get_" .. prop] then
			prototype["get_" .. prop] = function(self)
				local text_widget = self.children[1].children[1].children[1]
				return text_widget["get_" .. prop](text_widget)
			end
		end
    end
end

function text_button_normal:text_effect(instant)
	local wp = self._private
	local on_prefix = wp.state and "on_" or ""
	local bg = wp["text_" .. on_prefix .. wp.mode .. "_bg"]

	if instant == true then
		self.text_widget:set_color(bg)
	else
		self.color_animation:set(helpers.color.hex_to_rgb(bg))
	end
end

function text_button_normal:set_text_normal_bg(text_normal_bg)
	local wp = self._private
	wp.text_normal_bg = text_normal_bg
	wp.text_hover_bg = helpers.color.button_color(text_normal_bg, 0.1)
	wp.text_press_bg = helpers.color.button_color(text_normal_bg, 0.2)
	self:text_effect( true)
end

function text_button_normal:set_icon(icon)
	self.text_widget:set_icon(icon)
	self:set_text_normal_bg(icon.color)
	self.orginal_size = self.text_widget:get_size()
end

function text_button_normal:set_size(size)
	self.text_widget:set_size(size)
	self.orginal_size = self.text_widget:get_size()
end

local function new(is_state)
	local widget = is_state and ebwidget.state{} or ebwidget.normal{}
	widget.text_widget = twidget()
	widget:set_child(widget.text_widget)

	gtable.crush(widget, text_button_normal, true)

	local wp = widget._private

	-- Setup default values
	wp.text_normal_bg = beautiful.colors.random_accent_color()
	wp.text_hover_bg = helpers.color.button_color(wp.text_bg, 0.1)
	wp.text_press_bg = helpers.color.button_color(wp.text_bg, 0.2)
	wp.animate_size = true

	-- Setup animations
	widget.color_animation = helpers.animation:new
	{
		pos = helpers.color.hex_to_rgb(wp.text_normal_bg),
		easing = helpers.animation.easing.linear,
		duration = 0.2,
		update = function(self, pos)
			widget.text_widget:set_color(helpers.color.rgb_to_hex(pos))
		end
	}

	widget.size_animation = helpers.animation:new
	{
		pos = widget.text_widget:get_size(),
		easing = helpers.animation.easing.linear,
		duration = 0.125,
		update = function(self, pos)
			widget.text_widget:set_size(pos)
		end
	}

	local first_run = true

	widget:connect_signal("event", function(self, event)
		if first_run == true then
			widget.size_animation.pos = widget.orginal_size
			first_run = false
		end

		self:text_effect()

		if widget.text_widget._private.icon then
			if event == "press" or event == "secondary_press" then
				widget.size_animation:set(widget.orginal_size / 1.5)
			elseif event == "release" or event == "secondary_release" then
				widget.size_animation:set(widget.orginal_size)
			end
		end
	end)

	widget:text_effect(true)

	return widget
end

function text_button_normal.mt:__call(...)
    return new(...)
end

build_properties(text_button_normal, properties)
build_text_properties(text_button_normal, text_properties)

return setmetatable(text_button_normal, text_button_normal.mt)