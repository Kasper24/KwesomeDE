-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gtable = require("gears.table")
local tbnwidget = require("ui.widgets.button.text.normal")
local helpers = require("helpers")
local setmetatable = setmetatable
local ipairs = ipairs

local text_button_state = {
    mt = {}
}

local properties = {"text_on_normal_bg"}

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

function text_button_state:set_text_normal_bg(text_normal_bg)
    local wp = self._private
    wp.text_normal_bg = text_normal_bg
    self:text_effect(true)

    if self._private.text_on_normal_bg == nil then
        self:set_text_on_normal_bg(helpers.color.button_color(text_normal_bg, 0.2))
    end
end

function text_button_state:set_text_on_normal_bg(text_on_normal_bg)
    local wp = self._private
    wp.text_on_normal_bg = text_on_normal_bg
    self:text_effect(true)
end

local function new()
    local widget = tbnwidget {true}
    gtable.crush(widget, text_button_state, true)

    local wp = widget._private

    -- Setup default values
    wp.defaults.text_on_normal_bg = helpers.color.button_color(wp.defaults.text_normal_bg, 0.2)

    widget:text_effect(true)

    return widget
end

function text_button_state.mt:__call(...)
    return new(...)
end

build_properties(text_button_state, properties)

return setmetatable(text_button_state, text_button_state.mt)
