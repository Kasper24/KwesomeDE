-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gtable = require("gears.table")
local twidget = require("ui.widgets.text")
local ebwidget = require("ui.widgets.button.elevated")
local beautiful = require("beautiful")
local helpers = require("helpers")
local setmetatable = setmetatable
local ipairs = ipairs
local capi = {
    awesome = awesome
}

local text_button_normal = {
    mt = {}
}

local properties = {"text_normal_bg"}
local text_properties = {
    "font_family", "font_weight", "font_stretch", "font_variant", "bold", "italic",
    "color","underline_color", "strikethrough_color",
    "letter_spacing", "gravity", "gravity_hint", "insert_hyphens", "text_transform", "line_height", "underline", "strikethrough",
    "scale", "size", "text", "icon"
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

local function build_text_properties(prototype, prop_names)
    for _, prop in ipairs(prop_names) do
        if not prototype["set_" .. prop] then
            prototype["set_" .. prop] = function(self, value)
                local text_widget = self:get_content_widget()
                text_widget["set_" .. prop](text_widget, value)
            end
        end
        if not prototype["get_" .. prop] then
            prototype["get_" .. prop] = function(self)
                local text_widget = self:get_content_widget()
                return text_widget["get_" .. prop](text_widget)
            end
        end
    end
end

function text_button_normal:text_effect(instant)
    local wp = self._private
    local on_prefix = wp.state and "on_" or ""
    local key = "text_" .. on_prefix .. "normal" .. "_"
    local bg = wp[key .. "bg"] or wp.defaults[key .. "bg"]

    if instant == true then
        wp.color_anim:stop()
        wp.color_anim.pos = bg
        wp.size_anim.pos = wp.original_size
        self:get_content_widget():set_color(bg)
    else
        wp.color_anim:set(bg)
        if self:get_content_widget():get_icon() and wp.original_size then
            if wp.old_mode ~= "press" and wp.mode == "press" then
                wp.size_anim:set(wp.original_size / 1.5)
            elseif wp.old_mode == "press" and wp.mode ~= "press" then
                wp.size_anim:set(wp.original_size)
            end
        end
    end
end

function text_button_normal:set_text_normal_bg(text_normal_bg)
    local wp = self._private
    wp.text_normal_bg = text_normal_bg
    self:text_effect(true)
end

function text_button_normal:set_icon(icon)
    local wp = self._private
    self:get_content_widget():set_icon(icon)
    wp.original_size = self:get_content_widget():get_size()

    if wp.text_normal_bg == nil then
        self:set_text_normal_bg(icon.color)
    end
end

function text_button_normal:set_size(size)
    local wp = self._private
    self:get_content_widget():set_size(size)
    wp.original_size = self:get_content_widget():get_size()
end

local function new(is_state)
    local widget = is_state and ebwidget.state {} or ebwidget.normal {}
    widget:set_widget(twidget(false))

    gtable.crush(widget, text_button_normal, true)

    local wp = widget._private

    -- Setup default values
    wp.defaults.text_normal_bg = beautiful.colors.random_accent_color()

    -- Setup animations
    wp.color_anim = helpers.animation:new{
        easing = helpers.animation.easing.linear,
        duration = 0.2,
        update = function(self, pos)
            widget:get_content_widget():set_color(pos)
        end
    }

    wp.size_anim = helpers.animation:new{
        pos = widget:get_content_widget():get_size(),
        easing = helpers.animation.easing.linear,
        duration = 0.125,
        update = function(self, pos)
            widget:get_content_widget():set_size(pos)
        end
    }

    capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
        wp.text_normal_bg = old_colorscheme_to_new_map[wp.text_normal_bg] or
                                old_colorscheme_to_new_map[wp.defaults.text_normal_bg]
        wp.text_on_normal_bg = old_colorscheme_to_new_map[wp.text_on_normal_bg] or
                                old_colorscheme_to_new_map[wp.defaults.text_on_normal_bg] or
                                helpers.color.button_color(wp.text_normal_bg, 0.2)

        widget:text_effect(true)
    end)

    widget:text_effect(true)

    return widget
end

function text_button_normal.mt:__call(...)
    return new(...)
end

build_properties(text_button_normal, properties)
build_text_properties(text_button_normal, text_properties)

return setmetatable(text_button_normal, text_button_normal.mt)
