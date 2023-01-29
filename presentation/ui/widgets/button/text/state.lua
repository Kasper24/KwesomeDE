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

local text_button_state = { mt = {} }

local properties =
{
	"text_bg", "text_hover_bg", "text_press_bg",
	"text_on_bg", "text_on_hover_bg", "text_on_press_bg",
	"animate_size",
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

local function effect(widget, text_bg)
    if text_bg ~= nil then
		widget.color_animation:set(helpers.color.hex_to_rgb(text_bg))
    end
end

function text_button_state:set_normal_text_bg(text_normal_bg)
	local wp = self._private
	wp.text_normal_bg = text_normal_bg
	wp.text_hover_bg = helpers.color.button_color(text_normal_bg, 0.1)
	wp.text_press_bg = helpers.color.button_color(text_normal_bg, 0.2)
	effect(self, text_normal_bg)
end

function text_button_state:set_text_on_normal_bg(text_on_normal_bg)
	local wp = self._private
	wp.text_on_normal_bg = text_on_normal_bg
	wp.text_on_hover_bg = helpers.color.button_color(text_on_normal_bg, 0.1)
	wp.text_on_press_bg = helpers.color.button_color(text_on_normal_bg, 0.2)
end

function text_button_state:set_icon(icon)
	self.text_widget:set_icon(icon)
	self:set_text_bg(icon.color)
end

local function new()
	local widget = ebwidget.state()
	widget.text_widget = twidget()
	widget:set_child(widget.text_widget)

	gtable.crush(widget, text_button_state, true)

	local wp = widget._private
	wp.size = widget.text_widget:get_size()

	-- Setup default values
	wp.text_normal_bg = beautiful.random_accent_color()
	wp.text_hover_bg = helpers.color.button_color(wp.text_normal_bg, 0.1)
	wp.text_press_bg = helpers.color.button_color(wp.text_normal_bg, 0.2)

	wp.text_on_normal_bg = helpers.color.button_color(wp.text_normal_bg, 0.2)
	wp.text_on_hover_bg = helpers.color.button_color(wp.text_on_normal_bg, 0.1)
	wp.text_on_press_bg = helpers.color.button_color(wp.text_on_normal_bg, 0.2)

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
		pos = wp.size,
		easing = helpers.animation.easing.linear,
		duration = 0.2,
		update = function(self, pos)
			widget.text_widget:set_size(pos)
		end
	}

	widget:connect_signal("_private::on_hover", function(state)
		if state == true then
			effect(widget, wp.text_on_hover_bg)
		else
			effect(widget, wp.text_hover_bg)
		end
	end)

	widget:connect_signal("_private::on_leave", function(state)
		if state == true then
			effect(widget, wp.text_on_bg)
		else
			effect(widget, wp.text_normal_bg)
		end
	end)

	widget:connect_signal("_private::on_turn_on", function()
		effect(widget, wp.text_on_bg)
	end)

	widget:connect_signal("_private::on_turn_off", function()
		effect(widget, wp.text_normal_bg)
	end)

	widget:connect_signal("_private::on_press", function()
		if wp.animate_size == true then
			widget.size_animation:set(math.max(12, wp.size - 20))
		end
	end)

	widget:connect_signal("_private::on_release", function()
		if wp.animate_size == true then
			if widget.size_animation.state == true then
				widget.size_animation.ended:subscribe(function()
					widget.size_animation:set(wp.size)
					widget.size_animation.ended:unsubscribe()
				end)
			else
				widget.size_animation:set(wp.size)
			end
		end
	end)

	effect(widget, wp.text_normal_bg)

	return widget
end

function text_button_state.mt:__call(...)
    return new(...)
end

build_properties(text_button_state, properties)
build_text_properties(text_button_state, text_properties)

return setmetatable(text_button_state, text_button_state.mt)