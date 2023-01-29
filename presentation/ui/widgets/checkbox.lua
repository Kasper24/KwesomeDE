-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local gshape = require("gears.shape")
local wibox = require("wibox")
local beautiful = require("beautiful")
local helpers = require("helpers")
local setmetatable = setmetatable
local dpi = beautiful.xresources.apply_dpi

local checkbox = { mt = {} }

local function new(args)
    args = args or {}

    local switch_dimensions = { w = dpi(46), h = dpi(18) }
    local ball_dimensions = {  w = dpi(18), h = dpi(18) }

    local start_ball_position = ball_dimensions.w - switch_dimensions.w
    local done_ball_position = -start_ball_position -- just invert it

    local accent_color = args.color or beautiful.colors.random_accent_color()

    local ball_indicator = wibox.widget
    {
        widget = wibox.container.margin,
        left = start_ball_position,
        {
            widget = wibox.container.background,
            id = "ball",
            forced_height = ball_dimensions.h,
            forced_width = ball_dimensions.w,
            shape = gshape.circle,
            bg = accent_color,
        },
        set_bg = function(self, new_bg)
          self:get_children_by_id("ball")[1].bg = new_bg
        end,
    }

    local ball_animation = helpers.animation:new
    {
        duration = 0.25,
        easing = helpers.animation.easing.inOutQuad,
        pos =
        {
            margin_left = start_ball_position,
            color = helpers.color.hex_to_rgb(beautiful.colors.on_background),
        },
        update = function(self, pos)
            if pos.margin_left then
                ball_indicator.left = pos.margin_left
            end
            if pos.color then
                ball_indicator.bg = helpers.color.rgb_to_hex(pos.color)
            end
        end,
    }

    local widget = wibox.widget
    {
        widget = wibox.container.place,
        valign = "center",
        {
            widget = wibox.container.background,
            id = "background_role",
            forced_height = switch_dimensions.h,
            forced_width = switch_dimensions.w,
            shape = gshape.rounded_bar,
            bg = beautiful.colors.surface,
            ball_indicator,
        },
    }
    helpers.ui.add_hover_cursor(widget, beautiful.hover_cursor)

    function widget:turn_on()
        ball_animation:set
        {
            margin_left = done_ball_position,
            color = helpers.color.hex_to_rgb(accent_color),
        }
        if args.on_turn_on ~= nil then
            args.on_turn_on()
        end

        widget.state = true
    end

    function widget:turn_off()
        ball_animation:set
        {
            margin_left = start_ball_position,
            color = helpers.color.hex_to_rgb(beautiful.colors.on_background),
        }
        if args.on_turn_off ~= nil then
            args.on_turn_off()
        end

        widget.state = false
    end

    function widget:toggle()
        if widget.state == true then
            widget:turn_off()
        else
            widget:turn_on()
        end
    end

    widget:connect_signal("button::press", function(self, lx, ly, button, mods, find_widgets_result)
        if button == 1 then
            widget:toggle()
        end
    end)

    widget.state = args.on_by_default
	if args.on_by_default == true then
        widget:turn_on()
	end

    return widget
end

function checkbox.mt:__call(...)
    return new(...)
end

return setmetatable(checkbox, checkbox.mt)