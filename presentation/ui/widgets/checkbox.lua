-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gtable = require("gears.table")
local gshape = require("gears.shape")
local wibox = require("wibox")
local beautiful = require("beautiful")
local helpers = require("helpers")
local setmetatable = setmetatable
local dpi = beautiful.xresources.apply_dpi

local checkbox = {
    mt = {}
}

local properties = {"on_turn_on", "on_turn_off", "color"}

local function build_properties(prototype, prop_names)
    for _, prop in ipairs(prop_names) do
        if not prototype["set_" .. prop] then
            prototype["set_" .. prop] = function(self, value)
                if self._private[prop] ~= value then
                    self._private[prop] = value
                    self:emit_signal("widget::redraw_needed")
                    self:emit_signal("property::" .. prop, value)
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

function checkbox:set_color(color)
    local wp = self._private
    wp.color = color
    wp.ball_animation.pos.color = helpers.color.hex_to_rgb(color)
    wp.ball_indicator.bg = color
end

function checkbox:turn_on()
    local wp = self._private

    wp.ball_animation:set{
        margin_left = wp.done_ball_position,
        color = helpers.color.hex_to_rgb(wp.color)
    }
    wp.state = true

    if wp.on_turn_on ~= nil then
        wp.on_turn_on()
    end
end

function checkbox:turn_off()
    local wp = self._private

    wp.ball_animation:set{
        margin_left = wp.start_ball_position,
        color = helpers.color.hex_to_rgb(beautiful.colors.on_background)
    }
    wp.state = false

    if wp.on_turn_off ~= nil then
        wp.on_turn_off()
    end
end

function checkbox:toggle()
    if self._private.state == true then
        self:turn_off()
    else
        self:turn_on()
    end
end

function checkbox:get_state()
    return self._private.state
end

function checkbox:set_state(state)
    if state == true then
        self:turn_on()
    else
        self:turn_off()
    end
end

local function new()
    local switch_dimensions = {
        w = dpi(46),
        h = dpi(18)
    }
    local ball_dimensions = {
        w = dpi(18),
        h = dpi(18)
    }
    local start_ball_position = ball_dimensions.w - switch_dimensions.w
    local done_ball_position = -start_ball_position -- just invert it
    local color = beautiful.colors.random_accent_color()

    local ball_indicator = wibox.widget {
        widget = wibox.container.margin,
        left = start_ball_position,
        {
            widget = wibox.container.background,
            id = "ball",
            forced_height = ball_dimensions.h,
            forced_width = ball_dimensions.w,
            shape = gshape.circle,
            bg = color
        },
        set_bg = function(self, new_bg)
            self:get_children_by_id("ball")[1].bg = new_bg
        end
    }

    local widget = wibox.widget {
        widget = wibox.container.place,
        valign = "center",
        {
            widget = wibox.container.background,
            id = "background_role",
            forced_height = switch_dimensions.h,
            forced_width = switch_dimensions.w,
            shape = gshape.rounded_bar,
            bg = beautiful.colors.surface,
            ball_indicator
        }
    }
    gtable.crush(widget, checkbox, true)

    local wp = widget._private
    wp.state = false
    wp.color = color
    wp.ball_indicator = ball_indicator
    wp.start_ball_position = start_ball_position
    wp.done_ball_position = done_ball_position

    wp.ball_animation = helpers.animation:new{
        duration = 0.2,
        easing = helpers.animation.easing.inOutQuad,
        pos = {
            margin_left = start_ball_position,
            color = helpers.color.hex_to_rgb(beautiful.colors.on_background)
        },
        update = function(self, pos)
            if pos.margin_left then
                ball_indicator.left = pos.margin_left
            end
            if pos.color then
                ball_indicator.bg = helpers.color.rgb_to_hex(pos.color)
            end
        end
    }

    helpers.ui.add_hover_cursor(widget, beautiful.hover_cursor)

    widget:connect_signal("button::press", function(self, lx, ly, button, mods, find_widgets_result)
        if helpers.table.contains(mods, "Mod4") then
            return
        end

        if button == 1 then
            widget:toggle()
        end
    end)

    return widget
end

function checkbox.mt:__call(...)
    return new(...)
end

build_properties(checkbox, properties)

return setmetatable(checkbox, checkbox.mt)
