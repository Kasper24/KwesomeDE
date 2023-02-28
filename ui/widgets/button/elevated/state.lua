-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gtable = require("gears.table")
local ebnwidget = require("ui.widgets.button.elevated.normal")
local helpers = require("helpers")
local setmetatable = setmetatable
local ipairs = ipairs

local elevated_button_state = {
    mt = {}
}

local properties = {
    "on_normal_bg",
    "on_normal_shape", "on_hover_shape", "on_press_shape",
    "on_normal_border_width", "on_hover_border_width", "on_press_border_width",
    "on_normal_border_color", "on_hover_border_color", "on_press_border_color",
    "on_turn_on", "on_turn_off"
}

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

function elevated_button_state:set_on_by_default(value)
    if value == true then
        self:turn_on()
    end
end

function elevated_button_state:turn_on()
    local wp = self._private
    wp.state = true
    self:effect()
end

function elevated_button_state:turn_off()
    local wp = self._private
    wp.state = false
    self:effect()
end

function elevated_button_state:toggle()
    local wp = self._private
    if wp.state == true then
        self:turn_off()
    else
        self:turn_on()
    end
end

function elevated_button_state:set_normal_bg(normal_bg)
    local wp = self._private
    wp.normal_bg = normal_bg
    self:effect(true)

    if wp.on_normal_bg == nil then
        self:set_on_normal_bg(helpers.color.button_color(normal_bg, 0.2))
    end
end

function elevated_button_state:set_normal_shape(normal_shape)
    local wp = self._private
    wp.normal_shape = normal_shape
    wp.defaults.hover_shape = normal_shape
    wp.defaults.press_shape = normal_shape
    self:effect(true)

    if wp.on_normal_shape == nil then
        self:set_on_normal_shape(normal_shape)
    end
end

function elevated_button_state:set_normal_border_width(normal_border_width)
    local wp = self._private
    wp.normal_border_width = normal_border_width
    wp.defaults.hover_border_width = normal_border_width
    wp.defaults.press_border_width = normal_border_width
    self:effect(true)

    if wp.on_normal_shape == nil then
        self:set_on_normal_border_width(normal_border_width)
    end
end

function elevated_button_state:set_normal_border_color(normal_border_color)
    local wp = self._private
    wp.normal_border_color = normal_border_color
    wp.defaults.hover_border_color = normal_border_color
    wp.defaults.press_border_color = normal_border_color
    self:effect(true)

    if wp.on_normal_shape == nil then
        self:set_on_normal_border_color(normal_border_color)
    end
end

function elevated_button_state:set_on_normal_bg(on_normal_bg)
    local wp = self._private
    wp.on_normal_bg = on_normal_bg
    self:effect(true)
end

function elevated_button_state:set_on_normal_shape(on_normal_shape)
    local wp = self._private
    wp.on_normal_shape = on_normal_shape
    wp.defaults.on_hover_shape = on_normal_shape
    wp.defaults.on_press_shape = on_normal_shape
    self:effect(true)
end

function elevated_button_state:set_on_normal_border_width(on_normal_border_width)
    local wp = self._private
    wp.on_normal_border_width = on_normal_border_width
    wp.defaults.on_hover_border_width = on_normal_border_width
    wp.defaults.on_press_border_width = on_normal_border_width
    self:effect(true)
end

function elevated_button_state:set_on_normal_border_color(on_normal_border_color)
    local wp = self._private
    wp.on_normal_border_color = on_normal_border_color
    wp.defaults.on_hover_border_color = on_normal_border_color
    wp.defaults.on_press_border_color = on_normal_border_color
    self:effect(true)
end

local function new()
    local widget = ebnwidget(true)
    gtable.crush(widget, elevated_button_state, true)

    local wp = widget._private
    wp.state = false

    wp.defaults.on_normal_bg = helpers.color.button_color(wp.defaults.normal_bg, 0.2)

    wp.defaults.on_normal_shape = wp.defaults.normal_shape
    wp.defaults.on_hover_shape = wp.defaults.normal_shape
    wp.defaults.on_press_shape = wp.defaults.normal_shape

    wp.defaults.on_normal_border_width = wp.defaults.normal_border_width
    wp.defaults.on_hover_border_width = wp.defaults.normal_border_width
    wp.defaults.on_press_border_width = wp.defaults.normal_border_width

    wp.defaults.on_normal_border_color = wp.defaults.normal_border_color
    wp.defaults.on_hover_border_color = wp.defaults.normal_border_color
    wp.defaults.on_press_border_color = wp.defaults.normal_border_color

    wp.on_turn_on = nil
    wp.on_turn_off = nil

    widget:connect_signal("button::press", function(self, lx, ly, button, mods, find_widgets_result)
        if gtable.hasitem(mods, "Mod4") then
            return
        end

        if button == 1 then
            wp.old_mode = wp.mode
            wp.mode = "press"
            wp.lx = lx
            wp.ly = ly
            wp.widget_width = find_widgets_result.widget_width
            self:effect()

            if wp.on_press then
                wp.on_press(self, lx, ly, button, mods, find_widgets_result)
            end
        elseif button == 3 and (wp.on_secondary_press or wp.on_secondary_release) then
            wp.old_mode = wp.mode
            wp.mode = "press"
            wp.lx = lx
            wp.ly = ly
            wp.widget_width = find_widgets_result.widget_width
            self:effect()

            if wp.on_secondary_press then
                wp.on_secondary_press(self, lx, ly, button, mods, find_widgets_result)
            end
        elseif button == 4 and wp.on_scroll_up then
            wp.on_scroll_up(self, lx, ly, button, mods, find_widgets_result)
        elseif button == 5 and wp.on_scroll_down then
            wp.on_scroll_down(self, lx, ly, button, mods, find_widgets_result)
        end

        widget.button = button
    end)

    widget:connect_signal("button::release", function(self, lx, ly, button, mods, find_widgets_result)
        if button == 1 then
            wp.old_mode = wp.mode
            wp.mode = "hover"
            wp.lx = lx
            wp.ly = ly
            self:effect()

            if wp.state == true then
                if wp.on_turn_off then
                    widget:turn_off()
                    wp.on_turn_off(self, lx, ly, button, mods, find_widgets_result)
                elseif wp.on_release then
                    wp.on_release(self, lx, ly, button, mods, find_widgets_result)
                end
            else
                if wp.on_turn_on then
                    widget:turn_on()
                    wp.on_turn_on(self, lx, ly, button, mods, find_widgets_result)
                elseif wp.on_release then
                    wp.on_release(self, lx, ly, button, mods, find_widgets_result)
                end
            end
        elseif button == 3 and (wp.on_secondary_release or wp.on_secondary_press) then
            wp.old_mode = wp.mode
            wp.mode = "hover"
            self:effect()

            if wp.on_secondary_release then
                wp.on_secondary_release(self, lx, ly, button, mods, find_widgets_result)
            end
        end
    end)

    widget:effect(true)

    return widget
end

function elevated_button_state.mt:__call(...)
    return new(...)
end

build_properties(elevated_button_state, properties)

return setmetatable(elevated_button_state, elevated_button_state.mt)
