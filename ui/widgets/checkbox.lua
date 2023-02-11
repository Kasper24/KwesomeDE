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
local padding = dpi(5)
local start_ball_position = ball_dimensions.w - switch_dimensions.w
local done_ball_position = -start_ball_position - padding -- just invert it

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

function checkbox:turn_on()
    local wp = self._private

    wp.animation:set{
        handle_offset = done_ball_position,
        handle_color = helpers.color.hex_to_rgb(wp.handle_active_color),
    }
    wp.state = true

    if wp.on_turn_on ~= nil then
        wp.on_turn_on()
    end
end

function checkbox:turn_off()
    local wp = self._private

    wp.animation:set{
        handle_offset = padding * self._private.scale,
        handle_color = helpers.color.hex_to_rgb(beautiful.colors.on_background),
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

function checkbox:set_handle_active_color(active_color)
    local wp = self._private
    wp.handle_active_color = active_color

    local handle = self.children[1].children[1]
    handle.bg = active_color
end

function checkbox:set_scale(scale)
    local wp = self._private
    wp.scale = scale
    self.forced_height = self.forced_height * scale

    local handle = self.children[1].children[1]
    handle.forced_height = handle.forced_height * scale
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
    local handle = wibox.widget {
        widget = bwidget,
        forced_width = ball_dimensions.w,
        forced_height = ball_dimensions.h,
        point = { x = padding, y = 4},
        shape = gshape.circle,
        bg = beautiful.colors.on_background
    }

    local layout = wibox.widget {
        widget = wibox.layout.manual,
        handle
    }

    local widget = wibox.widget {
        widget = bwidget,
        forced_width = switch_dimensions.w,
        forced_height = switch_dimensions.h,
        shape = gshape.rounded_bar,
        bg = beautiful.colors.surface,
        layout
    }
    gtable.crush(widget, checkbox, true)

    local wp = widget._private
    wp.handle_active_color = beautiful.colors.random_accent_color()
    wp.scale = 1
    wp.state = false

    wp.animation = helpers.animation:new{
        duration = 0.2,
        easing = helpers.animation.easing.inOutQuad,
        pos = {
            handle_offset = padding,
            handle_color = helpers.color.hex_to_rgb(beautiful.colors.on_background)
        },
        update = function(self, pos)
            layout:move(1, {x = pos.handle_offset, y = 4})
            handle.bg = helpers.color.rgb_to_hex(pos.handle_color)
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
        wp.handle_active_color = old_colorscheme_to_new_map[wp.handle_active_color]

        if wp.state == true then
            handle.bg = wp.handle_active_color
        else
            handle.bg = beautiful.colors.on_background
        end
    end)

    return widget
end

function checkbox.mt:__call(...)
    return new(...)
end

build_properties(checkbox, properties)

return setmetatable(checkbox, checkbox.mt)
