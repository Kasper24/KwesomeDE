-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gtable = require("gears.table")
local iwidget = require("ui.widgets.icon")
local ebwidget = require("ui.widgets.button.elevated")
local beautiful = require("beautiful")
local helpers = require("helpers")
local setmetatable = setmetatable
local ipairs = ipairs

local icon_button_normal = {
    mt = {}
}

local properties = {"icon_normal_bg"}
local icon_properties = {
    "icon", "clip_shape",
    "resize","upscale", "downscale",
    "stylesheet", "dpi", "auto_dpi",
    "horizontal_fit_policy", "vertical_fit_policy",
    "valign", "halign",
    "max_scaling_factor", "scaling_quality"
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

local function build_icon_properties(prototype, prop_names)
    for _, prop in ipairs(prop_names) do
        if not prototype["set_" .. prop] then
            prototype["set_" .. prop] = function(self, value)
                local icon_widget = self:get_content_widget()
                icon_widget["set_" .. prop](icon_widget, value)
            end
        end
        if not prototype["get_" .. prop] then
            prototype["get_" .. prop] = function(self)
                local icon_widget = self:get_content_widget()
                return icon_widget["get_" .. prop](icon_widget)
            end
        end
    end
end

function icon_button_normal:text_effect(instant)
    local wp = self._private
    local on_prefix = wp.state and "on_" or ""
    local key = "icon_" .. on_prefix .. "normal" .. "_"
    local bg = wp[key .. "bg"] or wp.defaults[key .. "bg"]

    if instant == true then
        wp.color_anim:stop()
        wp.color_anim.pos = bg
        wp.size_anim.pos = wp.original_size
        self:get_content_widget():set_color(bg)
    else
        wp.color_anim:set(bg)
        if wp.old_mode ~= "press" and wp.mode == "press" then
            wp.size_anim:set(wp.original_size * 0.7)
        elseif wp.old_mode == "press" and wp.mode ~= "press" then
            wp.size_anim:set(wp.original_size)
        end
    end
end

function icon_button_normal:set_icon_normal_bg(icon_normal_bg)
    local wp = self._private
    wp.icon_normal_bg = icon_normal_bg
    self:text_effect(true)
end

local function new(is_state)
    local widget = is_state and ebwidget.state {} or ebwidget.normal {}
    widget:set_widget(iwidget())

    gtable.crush(widget, icon_button_normal, true)

    local wp = widget._private

    -- Setup default values
    wp.defaults.icon_normal_bg = beautiful.colors.random_accent_color()

    -- TODO REMOVE
    wp.original_size = 50

    -- Setup animations
    wp.color_anim = helpers.animation:new{
        easing = helpers.animation.easing.linear,
        duration = 0.2,
        update = function(self, pos)
            widget:get_content_widget():set_color(pos)
        end
    }

    wp.size_anim = helpers.animation:new{
        pos = wp.original_size,
        easing = helpers.animation.easing.linear,
        duration = 0.125,
        update = function(self, pos)
            widget:get_content_widget():set_forced_width(pos)
            widget:get_content_widget():set_forced_height(pos)
        end
    }

    widget:text_effect(true)

    return widget
end

function icon_button_normal.mt:__call(...)
    return new(...)
end

build_properties(icon_button_normal, properties)
build_icon_properties(icon_button_normal, icon_properties)

return setmetatable(icon_button_normal, icon_button_normal.mt)
