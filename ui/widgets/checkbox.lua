-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gtable = require("gears.table")
local gshape = require("gears.shape")
local wibox = require("wibox")
local bwidget = require("ui.widgets.background")
local beautiful = require("beautiful")
local helpers = require("helpers")
local setmetatable = setmetatable
local dpi = beautiful.xresources.apply_dpi
local capi = {
    awesome = awesome,
    mouse = mouse
}

local checkbox = {
    mt = {}
}

local properties = {"on_turn_on", "on_turn_off", "color"}

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

function checkbox:set_active_color(active_color)
    local wp = self._private
    wp.active_color = active_color
end

function checkbox:turn_on()
    local wp = self._private

    wp.animation:set{
        margin_left = done_ball_position,
        color = helpers.color.hex_to_rgb(wp.active_color)
    }
    wp.state = true

    if wp.on_turn_on ~= nil then
        wp.on_turn_on()
    end
end

function checkbox:turn_off()
    local wp = self._private

    wp.animation:set{
        margin_left = start_ball_position,
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

function checkbox:set_state(state)
    if state == true then
        self:turn_on()
    else
        self:turn_off()
    end
end

function checkbox:get_state()
    return self._private.state
end

local function new()
    local widget = wibox.widget {
        widget = wibox.container.place,
        valign = "center",
        {
            widget = bwidget,
            forced_height = switch_dimensions.h,
            forced_width = switch_dimensions.w,
            shape = gshape.rounded_bar,
            bg = beautiful.colors.surface,
            {
                widget = wibox.container.margin,
                id = "ball_margins",
                left = start_ball_position,
                {
                    widget = bwidget,
                    id = "ball",
                    forced_height = ball_dimensions.h,
                    forced_width = ball_dimensions.w,
                    shape = gshape.circle,
                    bg = beautiful.colors.on_background,
                },
            }
        }
    }
    gtable.crush(widget, checkbox, true)

    local wp = widget._private
    wp.state = false
    wp.active_color = beautiful.colors.random_accent_color()

    local ball_margins = widget:get_children_by_id("ball_margins")[1]
    local ball = widget:get_children_by_id("ball")[1]

    wp.animation = helpers.animation:new{
        duration = 0.2,
        easing = helpers.animation.easing.inOutQuad,
        pos = {
            margin_left = start_ball_position,
            color = helpers.color.hex_to_rgb(beautiful.colors.on_background)
        },
        update = function(self, pos)
            if pos.margin_left then
                ball_margins.left = pos.margin_left
            end
            if pos.color then
                ball.bg = helpers.color.rgb_to_hex(pos.color)
            end
        end
    }

    widget:connect_signal("mouse::enter", function()
        local widget = capi.mouse.current_wibox
        if widget then
            widget.cursor = beautiful.hover_cursor
        end
    end)

    widget:connect_signal("mouse::leave", function()
        local widget = capi.mouse.current_wibox
        if widget then
            widget.cursor = "left_ptr"
        end
    end)

    widget:connect_signal("button::press", function(self, lx, ly, button, mods, find_widgets_result)
        if helpers.table.contains(mods, "Mod4") then
            return
        end

        if button == 1 then
            widget:toggle()
        end
    end)

    capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
        wp.active_color = old_colorscheme_to_new_map[wp.active_color]
        if wp.state == true then
            ball.bg = wp.active_color
        else
            ball.bg = beautiful.colors.on_background
        end
    end)

    return widget
end

function checkbox.mt:__call(...)
    return new(...)
end

build_properties(checkbox, properties)

return setmetatable(checkbox, checkbox.mt)
