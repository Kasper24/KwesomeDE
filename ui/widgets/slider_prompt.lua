local gmath = require("gears.math")
local wibox = require("wibox")
local swidget = require("ui.widgets.slider")
local pwidget = require("ui.widgets.prompt")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local tostring = tostring
local tonumber = tonumber

local slider_prompt = {
    mt = {}
}

local function new(args)
	args = args or {}

	args.spacing = args.spacing or dpi(20)
	args.value = args.value or 0

	args.forced_width = args.slider_width
	args.forced_height = args.slider_height
	local slider = swidget(args)

	local prompt = pwidget(args)
	prompt:set_forced_width(args.prompt_width or dpi(80))
	prompt:set_forced_height(args.prompt_height or dpi(40))
	prompt:set_only_numbers(true)
	prompt:set_round(args.round)
	prompt:set_halign("center")
	prompt:set_text(tostring(slider:get_value()))

	local widget = wibox.widget {
		layout = wibox.layout.fixed.horizontal,
		spacing = args.spacing,
		slider,
		prompt
	}

	function widget:set_value(val)
		slider:set_value(val)
		prompt:set_text(val)
	end

	function widget:set_maximum(maximum)
        slider:set_maximum(maximum)
	end

	prompt:connect_signal("text::changed", function(self, text)
		local value = tonumber(text)

		-- Don't the prompt to show values like '01', '02' etc
		if value > 0 and text:sub(1, 1) == "0" then
			prompt:set_text(tostring(value), true)
		end
	end)

	prompt:connect_signal("stopped", function(self, text)
		local value = tonumber(text)

		if value == slider:get_value() then
			return
		end

		if value > args.maximum then
			prompt:set_text(tostring(args.maximum))
			slider:set_value(args.maximum)
			widget:emit_signal('property::value', args.maximum)
		elseif value < args.minimum then
			prompt:set_text(tostring(args.minimum))
			slider:set_value(args.minimum)
			widget:emit_signal('property::value', args.minimum)
		else
			slider:set_value(value)
			widget:emit_signal('property::value', value)
		end
	end)

	slider:connect_signal("property::value", function(self, value)
		prompt:set_text(tostring(value))
        widget:emit_signal('property::value', value)
    end)

	return widget
end

function slider_prompt.mt:__call(...)
    return new(...)
end

return setmetatable(slider_prompt, slider_prompt.mt)