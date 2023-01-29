-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local gtable = require("gears.table")
local wibox = require("wibox")
local beautiful = require("beautiful")
local ebnwidget = require("presentation.ui.widgets.button.elevated.normal")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local elevated_button_state = { mt = {} }

local properties =
{
	"on_normal_bg", "on_hover_bg", "on_press_bg",
	"on_normal_shape", "on_hover_shape", "on_press_shape",
	"on_normal_border_width", "on_hover_border_width", "on_press_border_width",
	"on_normal_border_color", "on_hover_border_color", "on_press_border_color",
	"on_turn_on", "on_turn_off",
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

function elevated_button_state:set_on_by_default(value)
	if value == true then
		self:turn_on()
	end
end

function elevated_button_state:turn_on()
	local wp = self._private
	wp.mode = "normal"
	wp.state = true
	self:effect()
	self:emit_signal("event", "on")
end

function elevated_button_state:turn_off()
	local wp = self._private
	wp.mode = "normal"
	wp.state = false
	self:effect()
	self:emit_signal("event", "off")
end

function elevated_button_state:toggle()
	local wp = self._private
	if wp.state == true then
		self:turn_off()
	else
		self:turn_on()
	end
end

function elevated_button_state:set_on_normal_bg(on_normal_bg)
	local wp = self._private
	wp.on_normal_bg = on_normal_bg
	wp.on_hover_bg = helpers.color.button_color(on_normal_bg, 0.1)
	wp.on_press_bg = helpers.color.button_color(on_normal_bg, 0.2)
	self:effect(true)
end

local function new()
	local widget = ebnwidget(true)
	gtable.crush(widget, elevated_button_state, true)

	local wp = widget._private
	wp.state = false

	-- Setup default values
	wp.on_normal_bg = helpers.color.button_color(wp.normal_bg, 0.2)
	wp.on_hover_bg = helpers.color.button_color(wp.on_normal_bg, 0.1)
	wp.on_press_bg = helpers.color.button_color(wp.on_normal_bg, 0.2)

	wp.on_normal_shape = wp.normal_shape
	wp.on_hover_shape = wp.normal_shape
	wp.on_press_shape = wp.normal_shape

	wp.on_normal_border_width = wp.normal_border_width
	wp.on_hover_border_width = wp.normal_border_width
	wp.on_press_border_width = wp.normal_border_width

	wp.on_normal_border_color =  wp.normal_border_color
	wp.on_hover_border_color = wp.normal_border_color
	wp.on_press_border_color = wp.normal_border_color

    wp.on_turn_on = nil
    wp.on_turn_off = nil

	widget:connect_signal("button::press", function(self, lx, ly, button, mods, find_widgets_result)
		if helpers.table.contains(mods, {"Mod4"}) then
			return
		end

		widget.button = button

		if button == 1 then
			if wp.state == true then
				if wp.on_turn_off then
					widget:turn_off()
					wp.on_turn_off(self, lx, ly, button, mods, find_widgets_result)
				elseif wp.on_press then
					wp.on_press(self, lx, ly, button, mods, find_widgets_result)
				end
			else
				if wp.on_turn_on then
					widget:turn_on()
					wp.on_turn_on(self, lx, ly, button, mods, find_widgets_result)
				elseif wp.on_press then
					wp.on_press(self, lx, ly, button, mods, find_widgets_result)
				end
			end

			widget:emit_signal("event", "press")
		elseif button == 3 and wp.on_secondary_press ~= nil then
			widget:emit_signal("event", "secondary_press")
			wp.on_secondary_press(self, lx, ly, button, mods, find_widgets_result)
		elseif button == 4 and wp.on_scroll_up ~= nil then
			wp.on_scroll_up(self, lx, ly, button, mods, find_widgets_result)
		elseif button == 5 and wp.on_scroll_down ~= nil then
			wp.on_scroll_down(self, lx, ly, button, mods, find_widgets_result)
		end
	end)

	widget:connect_signal("button::release", function(self, lx, ly, button, mods, find_widgets_result)
		if button == 1 then
			if wp.on_turn_on ~= nil or wp.on_turn_off ~= nil or wp.on_press then
				wp.mode = "normal"
				self:effect()
				widget:emit_signal("event", "release")
			end

			if wp.on_release ~= nil then
				wp.on_release(self, lx, ly, button, mods, find_widgets_result)
			end
		elseif button == 3 then
			if wp.on_secondary_release ~= nil then
				widget:emit_signal("event", "secondary_release")
				wp.on_secondary_release(self, lx, ly, button, mods, find_widgets_result)
			end
		end
	end)

	widget:effect(true)

	return widget
end

function elevated_button_state.mt:__call(...)
    return new(...)
end

build_properties(elevated_button_state, properties)

return setmetatable(elevated_button_state, elevated_button_state.mt)