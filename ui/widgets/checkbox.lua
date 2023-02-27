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
    root = root,
    mouse = mouse
}

local checkbox = {
    mt = {}
}

local properties = { "on_turn_on", "on_turn_off", "color"}

local switch_dimensions = {
    w = dpi(50),
    h = dpi(20)
}
local ball_dimensions = {
    w = dpi(25),
    h = dpi(25)
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

function checkbox:turn_on()
    local wp = self._private
    wp.state = true

    wp.animation:set{
        handle_offset = done_ball_position + wp.handle_offset,
        handle_color = wp.handle_active_color,
    }

    if wp.on_turn_on ~= nil then
        wp.on_turn_on()
    end
end

function checkbox:turn_off()
    local wp = self._private
    wp.state = false

    wp.animation:set{
        handle_offset = -wp.handle_offset,
        handle_color = beautiful.colors.background,
    }

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

function checkbox:set_handle_offset(handle_offset)
    local wp = self._private
    wp.animation:stop()

    wp.handle_offset = handle_offset

    if wp.state == true then
        self:turn_on()
    else
        self:turn_off()
    end
end

function checkbox:set_handle_active_color(active_color)
    local wp = self._private
    wp.animation:stop()

    wp.handle_active_color = active_color
    wp.handle.bg = active_color

    if wp.state == true then
        self:turn_on()
    end
end

function checkbox:set_state(state)
    local wp = self._private
    wp.state = true

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
    local accent_color = beautiful.colors.random_accent_color()

    local widget = wibox.widget {
        widget = wibox.container.place,
        halign = "center",
        valign = "center",
        {
            widget = bwidget,
            id = "background",
            forced_width = switch_dimensions.w,
            forced_height = switch_dimensions.h,
            shape = gshape.rounded_bar,
            bg = beautiful.colors.surface_no_opacity,
            border_width = dpi(2),
            border_color = beautiful.colors.background_no_opacity,
            {
                layout = wibox.layout.manual,
                id = "handle_layout",
                {
                    widget = bwidget,
                    id = "handle",
                    forced_width = ball_dimensions.w,
                    forced_height = ball_dimensions.h,
                    point = { x = -2, y = 0 },
                    shape = gshape.circle,
                    bg = accent_color,
                    border_width = dpi(2),
                    border_color = beautiful.colors.background_no_opacity,
                }
            }
        }
    }
    gtable.crush(widget, checkbox, true)

    local wp = widget._private
    wp.state = false

    wp.background = widget:get_children_by_id("background")[1]
    wp.handle_layout = widget:get_children_by_id("handle_layout")[1]
    wp.handle = widget:get_children_by_id("handle")[1]

    wp.handle_active_color = accent_color
    wp.handle_offset = 2

    wp.animation = helpers.animation:new{
        duration = 0.2,
        easing = helpers.animation.easing.inOutQuad,
        pos = {
            handle_offset = -wp.handle_offset,
            handle_color = beautiful.colors.on_background
        },
        update = function(self, pos)
            wp.handle_layout:move(1, { x = pos.handle_offset, y = 0 })
            wp.background.bg = pos.handle_color
        end
    }

    widget:connect_signal("mouse::enter", function()
        capi.root.cursor("hand2")
        local widget = capi.mouse.current_wibox
        if widget then
            widget.cursor = "hand2"
        end
    end)

    widget:connect_signal("mouse::leave", function()
        capi.root.cursor("left_ptr")
        local widget = capi.mouse.current_wibox
        if widget then
            widget.cursor = "left_ptr"
        end
    end)

    widget:connect_signal("button::press", function(self, lx, ly, button, mods, find_widgets_result)
        if gtable.hasitem(mods, "Mod4") then
            return
        end

        if button == 1 then
            widget:toggle()
        end
    end)

    capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
        wp.handle_active_color = old_colorscheme_to_new_map[wp.handle_active_color]
        wp.handle.bg = wp.handle_active_color

        if wp.state == true then
            wp.background.bg = wp.handle_active_color
        else
            wp.background.bg = beautiful.colors.background_no_opacity
        end
    end)

    return widget
end

function checkbox.mt:__call(...)
    return new(...)
end

build_properties(checkbox, properties)

return setmetatable(checkbox, checkbox.mt)
