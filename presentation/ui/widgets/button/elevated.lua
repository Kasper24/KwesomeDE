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

local elevated_button = { mt = {} }

local normal_properties =
{
	"normal_bg", "hover_bg", "press_bg",
	"normal_shape", "hover_shape", "press_shape",
	"normal_border_width", "hover_border_width", "press_border_width",
	"normal_border_color", "hover_border_color", "press_border_color",
	"on_hover", "on_leave",
	"on_press", "on_release",
	"on_secondary_press", "on_secondary_release",
	"on_scroll_up", "on_scroll_down",
}

local state_properties =
{
	"normal_bg", "hover_bg", "press_bg",
	"normal_shape", "hover_shape", "press_shape",
	"normal_border_width", "hover_border_width", "press_border_width",
	"normal_border_color", "hover_border_color", "press_border_color",
	"on_hover", "on_leave",
	"on_press", "on_release",
	"on_secondary_press", "on_secondary_release",
	"on_scroll_up", "on_scroll_down",
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

local function effect(widget, bg, shape, border_width, border_color)
	local animation_targets = {}

    if bg ~= nil then
		animation_targets.color = helpers.color.hex_to_rgb(bg)
    end
    if shape ~= nil then
        -- widget:get_children_by_id("background_role")[1].shape = shape
    end
    if border_width ~= nil then
		animation_targets.border_width = border_width
    end
    if border_color ~= nil then
		animation_targets.border_color = helpers.color.hex_to_rgb(border_color)
    end

	widget.animation:set(animation_targets)
end

local function button(args)
	local widget = wibox.container.background()

    local bg = beautiful.colors.surface
	local shape = args.normal_shape or helpers.ui.rrect(beautiful.border_radius)
	local border_width = args.normal_border_width or nil
	local border_color = args.normal_border_color or beautiful.colors.transparent

	function widget:set_child(child)
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
		widget:set_widget(child_widget)
	end

	-- Setup initial values
	widget:set_bg(bg)
	widget:set_shape(shape)
	widget:set_border_width(border_width)
	widget:set_border_color(border_color)

	-- Set the child widget
	widget:set_child(args.child)

	-- Add hover cursor
	helpers.ui.add_hover_cursor(widget, beautiful.hover_cursor)

	-- Color/Border animations
	widget.animation = helpers.animation:new
	{
		pos =
		{
			color = helpers.color.hex_to_rgb(args.normal_bg),
			border_width = args.normal_border_width,
			border_color =  helpers.color.hex_to_rgb(args.normal_border_color)
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

	return widget
end

function elevated_button.state(args)
	args = args or {}

	args.normal_bg = args.normal_bg or beautiful.colors.background
	args.hover_bg = args.hover_bg or helpers.color.button_color(args.normal_bg, 0.1)
	args.press_bg = args.press_bg or helpers.color.button_color(args.normal_bg, 0.2)
	args.on_normal_bg = args.on_normal_bg or args.press_bg
	args.on_hover_bg = args.on_hover_bg or helpers.color.button_color(args.on_normal_bg, 0.1)
	args.on_press_bg = args.on_press_bg or helpers.color.button_color(args.on_normal_bg, 0.2)

	args.normal_shape = args.normal_shape or helpers.ui.rrect(beautiful.border_radius)
	args.hover_shape = args.hover_shape or args.normal_shape
	args.press_shape = args.press_shape or args.hover_shape
	args.on_normal_shape = args.on_normal_shape or args.press_shape
	args.on_hover_shape = args.on_hover_shape or args.on_normal_shape
	args.on_press_shape = args.on_press_shape or args.on_hover_shape

	args.normal_border_width = args.normal_border_width or nil
	args.hover_border_width = args.hover_border_width or args.normal_border_width
	args.press_border_width = args.press_border_width or args.hover_border_width
	args.on_normal_border_width = args.on_normal_border_width or args.press_border_width
	args.on_hover_border_width = args.on_hover_border_width or args.on_normal_border_width
	args.on_press_border_width = args.on_press_border_width or args.on_hover_border_width

	args.normal_border_color = args.normal_border_color or beautiful.colors.transparent
	args.hover_border_color = args.hover_border_color or args.normal_border_color
	args.press_border_color = args.press_border_color or args.hover_border_color
	args.on_normal_border_color = args.on_normal_border_color or args.press_border_color
	args.on_hover_border_color = args.on_hover_border_color or args.on_normal_border_color
	args.on_press_border_color = args.on_press_border_color or args.on_hover_border_color

    args.on_hover = args.on_hover or nil
    args.on_leave = args.on_leave or nil
    args.on_press = args.on_press or nil
    args.on_release = args.on_release or nil
	args.on_secondary_press = args.on_secondary_press or nil
    args.on_secondary_release = args.on_secondary_release or nil
	args.on_scroll_up = args.on_scroll_up or nil
    args.on_scroll_down = args.on_scroll_down or nil
    args.on_turn_on = args.on_turn_on or nil
    args.on_turn_off = args.on_turn_off or nil

	local widget = button(args)
	build_properties(widget, state_properties)
    gtable.crush(widget._private, args, true)
	local wp = widget._private
	wp.state = false

	function widget:turn_on()
		if wp.state == false then
			effect(widget, wp.on_normal_bg, wp.on_normal_shape, wp.on_normal_border_width, wp.on_normal_border_color)
			widget:emit_signal("_private::on_turn_on")
			wp.state = true
		end
	end

	function widget:turn_off()
		if wp.state == true then
			effect(widget, wp.normal_bg, wp.normal_shape, wp.normal_border_width, wp.normal_border_color)
			widget:emit_signal("_private::on_turn_off")
			wp.state = false
		end
	end

	function widget:toggle()
		if wp.state == true then
			widget:turn_off()
		else
			widget:turn_on()
		end
	end

	widget:connect_signal("mouse::enter", function(self, find_widgets_result)
		if wp.hover_effect == false then
			return
		end

		if widget._private.state == true then
			effect(widget, wp.on_hover_bg, wp.on_hover_shape, wp.on_hover_border_width, wp.on_hover_border_color)
		else
			effect(widget, wp.hover_bg, wp.hover_shape, wp.hover_border_width, wp.hover_border_color)
		end
        if wp.on_hover ~= nil then
		    wp.on_hover(self, widget._private.state)
        end

		widget:emit_signal("_private::on_hover", widget._private.state)
	end)

	widget:connect_signal("mouse::leave", function(self, find_widgets_result)
		if widget.button ~= nil then
			widget:emit_signal("button::release", 1, 1, widget.button, {}, find_widgets_result, true)
		end

		if widget._private.state == true then
			effect(widget, wp.on_normal_bg, wp.on_normal_shape, wp.on_normal_border_width, wp.on_normal_border_color)
		else
			effect(widget, wp.normal_bg, wp.normal_shape, wp.normal_border_width, wp.normal_border_color)
		end
        if wp.on_leave ~= nil then
		    wp.on_leave(self, widget._private.state)
        end
		widget:emit_signal("_private::on_leave", widget._private.state)
	end)

	widget:connect_signal("button::press", function(self, lx, ly, button, mods, find_widgets_result)
		if #mods > 0 and not helpers.table.contains_only(mods, {"Lock", "Mod2",}) then
			return
		end

		widget.button = button

		if button == 1 then
			if widget._private.state == true then
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
				if widget._private.state == true then
					effect(widget, wp.on_normal_bg, wp.on_normal_shape, wp.on_normal_border_width, wp.on_normal_border_color)
				else
					effect(widget, wp.normal_bg, wp.normal_shape, wp.normal_border_width, wp.normal_border_color)
				end
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

	if wp.on_by_default == true then
		widget:turn_on()
	end

	return widget
end

function elevated_button.normal(args)
	args = args or {}

	args.normal_bg = args.normal_bg or beautiful.colors.background
	args.hover_bg = args.hover_bg or helpers.color.button_color(args.normal_bg, 0.1)
	args.press_bg = args.press_bg or helpers.color.button_color(args.normal_bg, 0.2)

	args.normal_shape = args.normal_shape or helpers.ui.rrect(beautiful.border_radius)
	args.hover_shape = args.hover_shape or args.normal_shape
	args.press_shape = args.press_shape or args.normal_shape

	args.normal_border_width = args.normal_border_width or nil
	args.hover_border_width = args.hover_border_width or args.normal_border_width
	args.press_border_width = args.press_border_width or args.hover_border_width

	args.normal_border_color = args.normal_border_color or beautiful.colors.transparent
	args.hover_border_color = args.hover_border_color or args.normal_border_color
	args.press_border_color = args.press_border_color or args.hover_border_color

    args.on_hover = args.on_hover or nil
    args.on_leave = args.on_leave or nil
    args.on_press = args.on_press or nil
    args.on_release = args.on_release or nil
	args.on_secondary_press = args.on_secondary_press or nil
    args.on_secondary_release = args.on_secondary_release or nil
	args.on_scroll_up = args.on_scroll_up or nil
    args.on_scroll_down = args.on_scroll_down or nil

	local widget = button(args)
	build_properties(widget, state_properties)
    gtable.crush(widget._private, args, true)
	local wp = widget._private

	widget:connect_signal("mouse::enter", function(self, find_widgets_result)
		effect(widget, wp.hover_bg, wp.hover_shape, wp.hover_border_width, wp.hover_border_color)
        if wp.on_hover ~= nil then
		    wp.on_hover(self, find_widgets_result)
        end
		widget:emit_signal("_private::on_hover", self, find_widgets_result)
	end)

	widget:connect_signal("mouse::leave", function(self, find_widgets_result)
		if widget.button ~= nil then
			if widget.button == 1 then
				if wp.on_release ~= nil or wp.on_press ~= nil then
					effect(widget, wp.normal_bg, wp.normal_shape, wp.normal_border_width, wp.normal_border_color)
				end
				widget:emit_signal("_private::on_release", self, 1, 1, widget.button, {}, find_widgets_result)
			elseif widget.button == 3 then
				if wp.on_secondary_release ~= nil or wp.on_secondary_press ~= nil then
					effect(widget, wp.normal_bg, wp.normal_shape, wp.normal_border_width, wp.normal_border_color)
				end
				widget:emit_signal("_private::on_secondary_release", self, 1, 1, widget.button, {}, find_widgets_result)
			end
			widget.button = nil
		end
		effect(widget, wp.normal_bg, wp.normal_shape, wp.normal_border_width, wp.normal_border_color)
        if wp.on_leave ~= nil then
		    wp.on_leave(self, find_widgets_result)
        end
		widget:emit_signal("_private::on_leave", self, find_widgets_result)
	end)

	widget:connect_signal("button::press", function(self, lx, ly, button, mods, find_widgets_result)
		if #mods > 0 and not helpers.table.contains_only(mods, {"Lock", "Mod2",}) then
			return
		end

		widget.button = button
		if button == 1 then
			if wp.on_press ~= nil then
				wp.on_press(self, lx, ly, button, mods, find_widgets_result)
				effect(widget, wp.press_bg, wp.press_shape, wp.press_border_width, wp.press_border_color)
			end
			widget:emit_signal("_private::on_press", self, lx, ly, button, mods, find_widgets_result)
		elseif button == 3 then
			if wp.on_secondary_press ~= nil then
				wp.on_secondary_press(self, lx, ly, button, mods, find_widgets_result)
				effect(widget, wp.press_bg, wp.press_shape, wp.press_border_width, wp.press_border_color)
				widget:emit_signal("_private::on_secondary_press", self, lx, ly, button, mods, find_widgets_result)
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

	widget:connect_signal("button::release", function(self, lx, ly, button, mods, find_widgets_result)
		widget.button = nil
		if button == 1 then
			if wp.on_release ~= nil or wp.on_press ~= nil then
				effect(widget, wp.normal_bg, wp.normal_shape, wp.normal_border_width, wp.normal_border_color)
			end
			if wp.on_release ~= nil then
				wp.on_release(self, lx, ly, button, mods, find_widgets_result)
			end
			widget:emit_signal("_private::on_release", self, lx, ly, button, mods, find_widgets_result)

		elseif button == 3 then
			if wp.on_secondary_release ~= nil or wp.on_secondary_press ~= nil then
				effect(widget, wp.normal_bg, wp.normal_shape, wp.normal_border_width, wp.normal_border_color)
			end
			if wp.on_secondary_release ~= nil then
				wp.on_secondary_release(self, lx, ly, button, mods, find_widgets_result)
			end
			widget:emit_signal("_private::on_secondary_release", self, lx, ly, button, mods, find_widgets_result)
		end
	end)

	return widget
end

return setmetatable(elevated_button, elevated_button.mt)