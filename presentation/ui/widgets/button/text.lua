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

local text_button = { mt = {} }

function text_button:set_font(font)
	self.children[1].children[1].children[1]:set_font(font)
end

function text_button:set_bold(bold)
	self.children[1].children[1].children[1]:set_bold(bold)
end

function text_button:set_size(font, size)
	self.children[1].children[1].children[1]:set_size(font, size)
end

function text_button:set_color(color)
	self.children[1].children[1].children[1]:set_color(color)
end

function text_button:set_text(text)
	self.children[1].children[1].children[1]:set_text(text)
end

local normal_properties =
{
	"text_normal_bg", "text_hover_bg", "text_press_bg",
	"animate_size"
}

local state_properties =
{
	"text_normal_bg", "text_hover_bg", "text_press_bg",
	"text_on_normal_bg", "text_on_hover_bg", "text_on_press_bg",
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

local function effect(widget, text_bg)
    if text_bg ~= nil then
		widget.color_animation:set(helpers.color.hex_to_rgb(text_bg))
    end
end

local function button(args, type)
    local widget = type == "normal" and ebwidget.normal(args) or ebwidget.state(args)
	gtable.crush(widget, text_button, true)

	local text_widget = twidget(args)

	-- Set initial values
	text_widget:set_color(args.text_normal_bg)
	widget:set_child(text_widget)

	-- Setup animations
	widget.color_animation = helpers.animation:new
	{
		pos = helpers.color.hex_to_rgb(args.text_normal_bg),
		easing = helpers.animation.easing.linear,
		duration = 0.2,
		update = function(self, pos)
			text_widget:set_color(helpers.color.rgb_to_hex(pos))
		end
	}

	widget.size_animation = helpers.animation:new
	{
		pos = args.size or 20,
		easing = helpers.animation.easing.linear,
		duration = 0.2,
		update = function(self, pos)
			text_widget:set_size(pos)
		end
	}

	return widget
end

function text_button.state(args)
    args = args or {}

	args.text_normal_bg = args.text_normal_bg or beautiful.random_accent_color()
	args.text_hover_bg = args.text_hover_bg or helpers.color.button_color(args.text_normal_bg, 0.1)
	args.text_press_bg = args.text_press_bg or helpers.color.button_color(args.text_normal_bg, 0.2)

	args.text_on_normal_bg = args.text_on_normal_bg or args.text_normal_bg
	args.text_on_hover_bg = args.text_on_hover_bg or helpers.color.button_color(args.text_on_normal_bg, 0.1)
	args.text_on_press_bg = args.text_on_press_bg or helpers.color.button_color(args.text_on_normal_bg, 0.2)

	args.animate_size = args.animate_size == nil and true or args.animate_size

	local widget = button(args, "state")
	build_properties(widget, state_properties)

	widget:connect_signal("_private::on_hover", function(state)
		if state == true then
			effect(widget, args.text_on_hover_bg)
		else
			effect(widget, args.text_hover_bg)
		end
	end)

	widget:connect_signal("_private::on_leave", function(state)
		if state == true then
			effect(widget, args.text_on_normal_bg)
		else
			effect(widget, args.text_normal_bg)
		end
	end)

	widget:connect_signal("_private::on_turn_on", function(state)
		effect(widget, args.text_on_normal_bg)
	end)

	widget:connect_signal("_private::on_turn_off", function(state)
		effect(widget, args.text_normal_bg)
	end)

	widget:connect_signal("_private::on_press", function(state)
		if args.animate_size == true then
			widget.size_animation:set(math.max(12, args.size - 20))
		end
	end)

	widget:connect_signal("_private::on_release", function(state)
		if args.animate_size == true then
			if widget.size_animation.state == true then
				widget.size_animation.ended:subscribe(function()
					widget.size_animation:set(args.size)
					widget.size_animation.ended:unsubscribe()
				end)
			else
				widget.size_animation:set(args.size)
			end
		end
	end)

	if args.on_by_default == true then
		widget:turn_on()
	end

	return widget
end

function text_button.normal(args)
	args = args or {}

	args.text_normal_bg = args.text_normal_bg or beautiful.random_accent_color()
	args.text_hover_bg = args.text_hover_bg or helpers.color.button_color(args.text_normal_bg, 0.1)
	args.text_press_bg = args.text_press_bg or helpers.color.button_color(args.text_normal_bg, 0.2)

	args.animate_size = args.animate_size == nil and true or args.animate_size

	local widget = button(args, "normal")
	build_properties(widget, normal_properties)

	widget:connect_signal("_private::on_hover", function(state)
		effect(widget, args.text_hover_bg)
	end)

	widget:connect_signal("_private::on_leave", function(state)
		effect(widget, args.text_normal_bg)
	end)

	widget:connect_signal("_private::on_press", function(state)
		effect(widget, args.text_press_bg)
		if args.animate_size == true then
			widget.size_animation:set(math.max(12, args.size - 20))
		end
	end)

	widget:connect_signal("_private::on_release", function(state)
		effect(widget, args.text_normal_bg)
		if args.animate_size == true then
			if widget.size_animation.state == true then
				widget.size_animation.ended:subscribe(function()
					widget.size_animation:set(args.size)
					widget.size_animation.ended:unsubscribe()
				end)
			else
				widget.size_animation:set(args.size)
			end
		end
	end)

	return widget
end

return setmetatable(text_button, text_button.mt)