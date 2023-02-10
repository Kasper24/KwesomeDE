local gshape = require("gears.shape")
local wibox = require("wibox")
local bwidget = require("ui.widgets.background")
local beautiful = require("beautiful")
local color = require("external.color")
local dpi = beautiful.xresources.apply_dpi
local helpers = require("helpers")
local math = math
local capi = {
	mouse = mouse,
    mousegrabber = mousegrabber
}

local slider = {
    mt = {}
}

local function set_x(x)
    return function(geo, args)
        return {x=x, y=(args.parent.height - geo.height)/2}
    end
end

local function new(args)
	args = args or {}

    args.forced_width = args.forced_width or nil
	args.forced_height = args.forced_height or dpi(8)
    args.maximum = args.maximum or 1
    args.margins = args.margins or dpi(0)
    args.bar_height = args.bar_height or dpi(8)
	args.bar_color = color.color { hex = args.bar_color or beautiful.colors.surface }
	args.bar_active_color = color.color { hex = args.bar_active_color or beautiful.colors.random_accent_color() }
    args.handle_template = args.handle_template or nil
    args.handle_width = args.handle_width or dpi(20)
    args.handle_height = args.handle_height or dpi(20)
    args.handle_shape = args.handle_shape or gshape.circle
	args.handle_color = args.handle_color or args.bar_active_color.hex
    args.handle_border_width = args.handle_border_width or dpi(2)
    args.handle_border_color = args.handle_border_color or  beautiful.colors.background

	local value = (args.value or 0) / args.maximum
	local w = 0
    local is_dragging = false

	local bar_start, bar_end, bar_current, height2, hb2, pi2, value_min, value_max, effwidth, ipos, lpos
	hb2 = args.bar_height / 2
    bar_start = args.margins + hb2
    bar_end = w - (bar_start)
    bar_current = value + args.bar_height
    pi2 = math.pi * 2
    value_min = args.margins - hb2
    value_max = w - bar_start - hb2
    effwidth = value_max - value_min

	local handle = args.handle_template or wibox.widget {
        widget = bwidget,
        point = { x = 0, y = 0 },
        forced_width = args.handle_width,
		forced_height = args.handle_height,
        shape = args.handle_shape,
        bg = args.handle_color,
        border_width = args.handle_border_width,
        border_color = args.handle_border_color
	}

	local layout = wibox.layout {
        layout = wibox.layout.manual,
		handle
	}

	local bar = wibox.widget {
        widget = wibox.widget.make_base_widge,
		forced_width = args.forced_width,
        forced_height = args.forced_height,
        pos = 0,
		fit = function(_, _, width, height) return width, height end,
		draw = function(self, _, cr, width, height)
			w = width --get the width whenever redrawing just in case
			bar_end = width - (bar_start) --update bar_end which depends on width
			height2 = height / 2 --update height2 which depends on height
			value_max = width - bar_start - hb2
			effwidth = value_max - value_min

			value = effwidth * self.pos + value_min
			bar_current = value + args.bar_height
			layout:move(1, set_x(value))

			cr:set_line_width(args.bar_height)

			cr:set_source_rgb(args.bar_color.r / 255, args.bar_color.g / 255, args.bar_color.b / 255)
			cr:arc(bar_end, height2, hb2, 0, pi2)
			cr:fill()

			cr:move_to(bar_start, height2)
			cr:line_to(bar_end, height2)
			cr:stroke()

			cr:set_source_rgb(args.bar_active_color.r / 255, args.bar_active_color.g / 255, args.bar_active_color.b / 255)
			cr:arc(bar_start, height2, hb2, 0, pi2)
			cr:arc(bar_current, height2, hb2, 0, pi2)
			cr:fill()

			cr:move_to(bar_start, height2)
			cr:line_to(bar_current, height2)
			cr:stroke()
		end
	}

	local widget = wibox.widget {
		layout = wibox.layout.stack,
		forced_width = args.forced_width,
		forced_height = args.forced_height,
		bar,
		layout
	}

	local animation = helpers.animation:new {
        easing = helpers.animation.easing.linear,
		duration = 0.05,
        update = function(self, pos)
            bar.pos = pos
            bar:emit_signal("widget::redraw_needed")
        end,
        signals = {
            ["ended"] = function()
                widget:emit_signal("property::value", bar.pos * args.maximum)
            end
        }
	}

	layout:connect_signal("button::press", function(self, x, y, button, _, geo)
		if button ~= 1 then return end

		--reset initial position for later
		ipos = nil

		--initially move it to the target (only one call of max and min is prolly fine)
		animation:set(math.min(math.max(((x - args.bar_height) / effwidth), 0), 1))

		capi.mousegrabber.run(function(mouse)
			--stop (and emit signal) if you release mouse 1
			if not mouse.buttons[1] then
				widget:emit_signal("slider::ended_mouse_things", animation.pos)
                is_dragging = false
				return false
			end

            is_dragging = true

			--get initial position
			if not ipos then ipos = mouse.x end

			lpos = (x + mouse.x - ipos - args.bar_height) / effwidth

			--make sure target \in (0, 1)
			animation:set(math.max(math.min(lpos, 1), 0))

			return true
		end,"fleur")
	end)

	layout:connect_signal("mouse::enter", function()
        local widget = capi.mouse.current_wibox
        if widget then
            widget.cursor = "fleur"
        end
    end)

    layout:connect_signal("mouse::leave", function()
        local widget = capi.mouse.current_wibox
        if widget then
            widget.cursor = "left_ptr"
        end
    end)

	function widget:set_value(val)
		animation:set(val)
	end

	function widget:set_value_instant(val)
        if is_dragging == false then
            animation.pos = val
            bar.pos = val / args.maximum
            bar:emit_signal("widget::redraw_needed")
        end
	end

	function widget:set_maximum(maximum)
        args.maximum = maximum
	end

	return widget
end

function slider.mt:__call(...)
    return new(...)
end

return setmetatable(slider, slider.mt)