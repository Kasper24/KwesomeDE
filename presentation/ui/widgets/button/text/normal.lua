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
	"text_normal_bg", "text_hover_bg", "text_press_bg",
	"animate_size"
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

local function effect(widget, bg, shape, border_width, border_color)
	local animation_targets = {}

    if bg ~= nil then
		animation_targets.color = helpers.color.hex_to_rgb(bg)
    end
    if shape ~= nil then
        widget.shape = shape
    end
    if border_width ~= nil then
		animation_targets.border_width = border_width
    end
    if border_color ~= nil then
		animation_targets.border_color = helpers.color.hex_to_rgb(border_color)
    end

	widget.animation:set(animation_targets)
end

function text_button_normal:set_color(color)
	self.children[1].children[1].children[1]:set_color(color)
end

function text_button_normal:set_text(text)
	self.children[1].children[1].children[1]:set_text(text)
end

local function new(args)
	local widget = ebwidget.normal()
	local text_widget = twidget(args)
	widget:set_child(text_widget)

	gtable.crush(widget, text_button_normal, true)
	gtable.crush(widget, text_widget, true)

	local wp = widget._private

	-- Setup default values
	wp.text_normal_bg = beautiful.random_accent_color()
	wp.text_hover_bg = helpers.color.button_color(wp.text_normal_bg, 0.1)
	wp.text_press_bg = helpers.color.button_color(wp.text_normal_bg, 0.2)
	wp.animate_size = true

	-- Setup animations
	widget.color_animation = helpers.animation:new
	{
		pos = helpers.color.hex_to_rgb(wp.text_normal_bg),
		easing = helpers.animation.easing.linear,
		duration = 0.2,
		update = function(self, pos)
			text_widget:set_color(helpers.color.rgb_to_hex(pos))
		end
	}

	-- TODO check how to get size
	widget.size_animation = helpers.animation:new
	{
		pos = text_widget.size or 20,
		easing = helpers.animation.easing.linear,
		duration = 0.2,
		update = function(self, pos)
			text_widget:set_size(pos)
		end
	}

	widget:connect_signal("_private::on_hover", function()
		effect(widget, wp.text_hover_bg)
	end)

	widget:connect_signal("_private::on_leave", function()
		effect(widget, wp.text_normal_bg)
	end)

	widget:connect_signal("_private::on_press", function()
		effect(widget, wp.text_press_bg)
		if wp.animate_size == true then
			widget.size_animation:set(math.max(12, wp.size - 20))
		end
	end)

	widget:connect_signal("_private::on_release", function()
		effect(widget, wp.text_normal_bg)
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

	return widget
end

function text_button_normal.mt:__call(...)
    return new(...)
end

build_properties(text_button_normal, properties)

return setmetatable(text_button_normal, text_button_normal.mt)