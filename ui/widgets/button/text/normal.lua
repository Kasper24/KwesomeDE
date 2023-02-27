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

local properties = {"text_bg", "text_hover_bg", "text_press_bg"}
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
                local text_widget = self.children[1].children[1].children[1]
                text_widget["set_" .. prop](text_widget, value)
            end
        end
        if not prototype["get_" .. prop] then
            prototype["get_" .. prop] = function(self)
                local text_widget = self.children[1].children[1].children[1]
                return text_widget["get_" .. prop](text_widget)
            end
        end
    end
end

function text_button_normal:text_effect(instant)
    local wp = self._private
    local on_prefix = wp.state and "on_" or ""
    local key = "text_" .. on_prefix .. wp.mode .. "_"
    local bg = wp[key .. "bg"] or wp.defaults[key .. "bg"]

    if instant == true then
        self.color_animation:stop()
        self.color_animation.pos = helpers.color.hex_to_rgb(bg)
        self.text_widget:set_color(bg)
    else
        self.color_animation:set(helpers.color.hex_to_rgb(bg))
    end
end

function text_button_normal:set_text_normal_bg(text_normal_bg)
    local wp = self._private
    wp.text_normal_bg = text_normal_bg
    wp.defaults.text_hover_bg = helpers.color.button_color(text_normal_bg, 0.1)
    wp.defaults.text_press_bg = helpers.color.button_color(text_normal_bg, 0.2)
    self:text_effect(true)
end

function text_button_normal:set_icon(icon)
    self.text_widget:set_icon(icon)
    self.orginal_size = self.text_widget:get_size()

    if self._private.text_normal_bg == nil then
        self:set_text_normal_bg(icon.color)
    end
end

function text_button_normal:set_size(size)
    self.text_widget:set_size(size)
    self.orginal_size = self.text_widget:get_size()
end

local function new(is_state)
    local widget = is_state and ebwidget.state {} or ebwidget.normal {}
    widget.text_widget = twidget(false)
    widget:set_widget(widget.text_widget)

    gtable.crush(widget, text_button_normal, true)

    local wp = widget._private

    -- Setup default values
    wp.defaults.text_normal_bg = beautiful.colors.random_accent_color()
    wp.defaults.text_hover_bg = helpers.color.button_color(wp.defaults.text_normal_bg, 0.1)
    wp.defaults.text_press_bg = helpers.color.button_color(wp.defaults.text_normal_bg, 0.2)

    -- Setup animations
    widget.color_animation = helpers.animation:new{
        easing = helpers.animation.easing.linear,
        duration = 0.2,
        update = function(self, pos)
            widget.text_widget:set_color(helpers.color.rgb_to_hex(pos))
        end
    }

    widget.size_animation = helpers.animation:new{
        pos = widget.text_widget:get_size(),
        easing = helpers.animation.easing.linear,
        duration = 0.125,
        update = function(self, pos)
            widget.text_widget:set_size(pos)
        end
    }

    local first_run = true
    widget:connect_signal("event", function(self, event)
        if first_run == true then
            widget.size_animation.pos = widget.orginal_size
            first_run = false
        end

        if widget.text_widget._private.icon then
            if event == "press" or event == "secondary_press" then
                widget.size_animation:set(widget.orginal_size / 1.5)
            elseif event == "release" or event == "secondary_release" then
                widget.size_animation:set(widget.orginal_size)
            end
        end
    end)

    capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
        wp.text_normal_bg = old_colorscheme_to_new_map[wp.text_normal_bg] or
                                old_colorscheme_to_new_map[wp.defaults.text_normal_bg]
        wp.text_hover_bg = old_colorscheme_to_new_map[wp.text_hover_bg] or
                            old_colorscheme_to_new_map[wp.defaults.text_hover_bg] or
                            helpers.color.button_color(wp.text_normal_bg, 0.1)
        wp.text_press_bg = old_colorscheme_to_new_map[wp.text_press_bg] or
                            old_colorscheme_to_new_map[wp.defaults.text_press_bg] or
                            helpers.color.button_color(wp.text_normal_bg, 0.2)

        wp.text_on_normal_bg = old_colorscheme_to_new_map[wp.text_on_normal_bg] or
                                old_colorscheme_to_new_map[wp.defaults.text_on_normal_bg] or
                                helpers.color.button_color(wp.text_normal_bg, 0.2)
        wp.text_on_hover_bg = old_colorscheme_to_new_map[wp.text_on_hover_bg] or
                                old_colorscheme_to_new_map[wp.defaults.text_on_hover_bg] or
                                helpers.color.button_color(wp.text_on_normal_bg, 0.1)
        wp.text_on_press_bg = old_colorscheme_to_new_map[wp.text_on_press_bg] or
                                old_colorscheme_to_new_map[wp.defaults.text_on_press_bg] or
                                helpers.color.button_color(wp.text_on_normal_bg, 0.2)

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
