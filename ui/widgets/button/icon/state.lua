-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gtable = require("gears.table")
local ibnwidget = require("ui.widgets.button.icon.normal")
local helpers = require("helpers")
local setmetatable = setmetatable

local icon_button_state = {
    mt = {}
}

local properties = {"icon_on_normal_bg"}

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

function icon_button_state:set_icon_normal_bg(icon_normal_bg)
    local wp = self._private
    wp.icon_normal_bg = icon_normal_bg
    self:icon_effect(true)

    if self._private.icon_on_normal_bg == nil then
        self:set_icon_on_normal_bg(helpers.color.darken_or_lighten(icon_normal_bg, 0.2))
    end
end

function icon_button_state:set_icon_on_normal_bg(icon_on_normal_bg)
    local wp = self._private
    wp.icon_on_normal_bg = icon_on_normal_bg
    self:icon_effect(true)
end

local function new()
    local widget = ibnwidget {true}
    gtable.crush(widget, icon_button_state, true)

    local wp = widget._private

    -- Setup default values
    wp.defaults.icon_on_normal_bg = helpers.color.darken_or_lighten(wp.defaults.icon_normal_bg, 0.2)

    widget:icon_effect(true)

    return widget
end

function icon_button_state.mt:__call(...)
    return new()
end

build_properties(icon_button_state, properties)

return setmetatable(icon_button_state, icon_button_state.mt)
