-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local gtable = require("gears.table")
local wibox = require("wibox")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local elevated_button_state = { mt = {} }

local properties =
{
	"normal_bg", "hover_bg", "press_bg",
	"normal_shape", "hover_shape", "press_shape",
	"normal_border_width", "hover_border_width", "press_border_width",
	"normal_border_color, hover_border_color", "press_border_color",
	"on_normal_bg", "on_hover_bg", "on_press_bg",
	"on_normal_shape", "on_hover_shape", "on_press_shape",
	"on_normal_border_width", "on_hover_border_width", "on_press_border_width",
	"on_normal_border_color", "on_hover_border_color", "on_press_border_color",
	"on_hover", "on_leave",
	"on_press", "on_release",
	"on_secondary_press", "on_secondary_release",
	"on_scroll_up", "on_scroll_down",
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

local function effect(widget, mode)
	local wp = widget._private
	local on_prefix = wp.state and "on_" or ""
	mode = mode .. "_"
	local bg = wp[on_prefix .. mode .. "bg"]
	local shape = wp[on_prefix .. mode .. "shape"]
	local border_width = wp[on_prefix .. mode .. "border_width"]
	local border_color = wp[on_prefix .. mode .. "border_color"]

	widget.animation:set{
		color = helpers.color.hex_to_rgb(bg),
		border_width = border_width,
		border_color = helpers.color.hex_to_rgb(border_color)
	}
	widget.shape = shape
end

function elevated_button_state:set_child(child)
	local child_widget = wibox.widget
	{
		widget = wibox.container.place,
		halign = "center",
		valign = "center",
		{
			widget = wibox.container.margin,
			margins = dpi(10),
			child
		}
	}
	self:set_widget(child_widget)
end

function elevated_button_state:get_child()
	return self._private.child
end

function elevated_button_state:set_on_by_default(value)
	if value == true then
		self:turn_on()
	end
end

function elevated_button_state:turn_on()
	local wp = self._private
	wp.state = true
	effect(self, "normal")
	self:emit_signal("_private::on_turn_on")
end

function elevated_button_state:turn_off()
	local wp = self._private
	wp.state = false
	effect(self, "normal")
	self:emit_signal("_private::on_turn_on")
end

function elevated_button_state:toggle()
	local wp = self._private
	if wp.state == true then
		self:turn_off()
	else
		self:turn_on()
	end
end

function elevated_button_state:set_normal_bg(normal_bg)
	local wp = self._private
	wp.normal_bg = normal_bg
	wp.hover_bg = helpers.color.button_color(normal_bg, 0.1)
	wp.press_bg = helpers.color.button_color(normal_bg, 0.2)
	self:emit_signal("widget::redraw_needed")
    self:emit_signal("property::bg", normal_bg)
end

function elevated_button_state:set_on_normal_bg(on_normal_bg)
	local wp = self._private
	wp.on_normal_bg = on_normal_bg
	wp.on_hover_bg = helpers.color.button_color(on_normal_bg, 0.1)
	wp.on_press_bg = helpers.color.button_color(on_normal_bg, 0.2)
end

local function new()
	local widget = wibox.container.background()
	gtable.crush(widget, elevated_button_state, true)

	local wp = widget._private
	wp.state = false

	-- Setup default values
	wp.normal_bg = beautiful.colors.background
	wp.hover_bg = helpers.color.button_color(wp.normal_bg, 0.1)
	wp.press_bg = helpers.color.button_color(wp.normal_bg, 0.2)
	wp.on_normal_bg = helpers.color.button_color(wp.normal_bg, 0.2)
	wp.on_hover_bg = helpers.color.button_color(wp.on_normal_bg, 0.1)
	wp.on_press_bg = helpers.color.button_color(wp.on_normal_bg, 0.2)

	wp.normal_shape = helpers.ui.rrect(beautiful.border_radius)
	wp.hover_shape = wp.normal_shape
	wp.press_shape = wp.normal_shape
	wp.on_normal_shape = wp.normal_shape
	wp.on_hover_shape = wp.normal_shape
	wp.on_press_shape = wp.normal_shape

	wp.normal_border_width = nil
	wp.hover_border_width = wp.normal_border_width
	wp.press_border_width = wp.normal_border_width
	wp.on_normal_border_width = wp.normal_border_width
	wp.on_hover_border_width = wp.normal_border_width
	wp.on_press_border_width = wp.normal_border_width

	wp.normal_border_color = beautiful.colors.transparent
	wp.hover_border_color = wp.normal_border_color
	wp.press_border_color = wp.normal_border_color
	wp.on_normal_border_color =  wp.normal_border_color
	wp.on_hover_border_color = wp.normal_border_color
	wp.on_press_border_color = wp.normal_border_color

	-- TODO: Set to empty function by default to prevent all these if checks ffs
    wp.on_hover = nil
    wp.on_leave = nil
    wp.on_press = nil
    wp.on_release = nil
	wp.on_secondary_press = nil
    wp.on_secondary_release = nil
	wp.on_scroll_up = nil
    wp.on_scroll_down = nil
    wp.on_turn_on = nil
    wp.on_turn_off = nil

	-- Add hover cursor
	helpers.ui.add_hover_cursor(widget, beautiful.hover_cursor)

	-- Color/Border animations
	widget.animation = helpers.animation:new
	{
		pos =
		{
			color = helpers.color.hex_to_rgb(wp.normal_bg),
			border_width = wp.normal_border_width,
			border_color =  helpers.color.hex_to_rgb(wp.normal_border_color)
		},
		easing = helpers.animation.easing.linear,
		duration = 0.2,
		update = function(self, pos)
			if pos.color then
				widget.bg = helpers.color.rgb_to_hex(pos.color)
			end
			if pos.border_width then
				widget.border_width = pos.border_width
			end
			if pos.border_color then
				widget.border_color = helpers.color.rgb_to_hex(pos.border_color)
			end
		end
	}

	widget:connect_signal("mouse::enter", function(self, find_widgets_result)
		if wp.hover_effect == false then
			return
		end

		effect(widget, "hover")

        if wp.on_hover ~= nil then
		    wp.on_hover(self, wp.state)
        end

		widget:emit_signal("_private::on_hover", wp.state)
	end)

	widget:connect_signal("mouse::leave", function(self, find_widgets_result)
		if widget.button ~= nil then
			widget:emit_signal("button::release", 1, 1, widget.button, {}, find_widgets_result, true)
		end

		effect(widget, "normal")

        if wp.on_leave ~= nil then
		    wp.on_leave(self, wp.state)
        end
		widget:emit_signal("_private::on_leave", wp.state)
	end)

	widget:connect_signal("button::press", function(self, lx, ly, button, mods, find_widgets_result)
		if #mods > 0 and not helpers.table.contains_only(mods, {"Lock", "Mod2",}) then
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

			widget:emit_signal("_private::on_press", self, lx, ly, button, mods, find_widgets_result)
		elseif button == 3 then
			widget:emit_signal("_private::on_secondary_press", self, lx, ly, button, mods, find_widgets_result)

			if wp.on_secondary_press ~= nil then
				wp.on_secondary_press(self, lx, ly, button, mods, find_widgets_result)
			end
		elseif button == 4 then
			if wp.on_scroll_up ~= nil then
				wp.on_scroll_up(self, lx, ly, button, mods, find_widgets_result)
			end
		elseif button == 5 then
			if wp.on_scroll_down ~= nil then
				wp.on_scroll_down(self, lx, ly, button, mods, find_widgets_result)
			end
		end
	end)

	widget:connect_signal("button::release", function(self, lx, ly, button, mods, find_widgets_result, fake)
		widget.button = nil

		if button == 1 then
			if wp.on_turn_on ~= nil or wp.on_turn_off ~= nil or wp.on_press then
				effect(widget, "normal")
			end

			widget:emit_signal("_private::on_release", self, lx, ly, button, mods, find_widgets_result)

			if wp.on_release ~= nil and fake ~= true then
				wp.on_release(self, lx, ly, button, mods, find_widgets_result)
			end
		elseif button == 3 then
			widget:emit_signal("_private::on_secondary_release", self, lx, ly, button, mods, find_widgets_result)

			if wp.on_secondary_release ~= nil and fake ~= true then
				wp.on_secondary_release(self, lx, ly, button, mods, find_widgets_result)
			end
		end
	end)

	effect(widget, "normal")

	return widget
end

function elevated_button_state.mt:__call(...)
    return new(...)
end

build_properties(elevated_button_state, properties)

return setmetatable(elevated_button_state, elevated_button_state.mt)