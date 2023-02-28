-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gtable = require("gears.table")
local gstring = require("gears.string")
local wibox = require("wibox")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable
local tostring = tostring
local ipairs = ipairs
local string = string
local math = math
local ceil = math.ceil
local max = math.max
local capi = {
    awesome = awesome
}

local text = {
    mt = {}
}

local properties = {
    "font_family", "font_weight", "font_stretch", "font_variant", "bold", "italic",
    "color","underline_color", "strikethrough_color",
    "letter_spacing", "gravity", "gravity_hint", "insert_hyphens", "text_transform", "line_height", "underline", "strikethrough",
    "scale", "size", "text", "icon",
    "text_normal_bg", "text_on_normal_bg",
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

local function generate_markup(self)
    local wp = self._private

    local bold_start = ""
    local bold_end = ""
    local italic_start = ""
    local italic_end = ""

    if wp.bold == true then
        bold_start = "<b>"
        bold_end = "</b>"
    end
    if wp.italic == true then
        italic_start = "<i>"
        italic_end = "</i>"
    end

    local font = wp.font or wp.defaults.font
    local font_weight = wp.font_weight or wp.defaults.font_weight
    local font_stretch = wp.font_stretch or wp.defaults.font_stretch
    local font_variant = wp.font_variant or wp.defaults.font_variant
    local size = max((wp.size or wp.defaults.size), 1)
    local scale = wp.scale or wp.defaults.scale
    local color = wp.color or wp.defaults.color
    local underline = wp.underline or wp.defaults.underline
    local underline_color = wp.underline_color or wp.defaults.underline_color
    local strikethrough = wp.strikethrough or wp.defaults.strikethrough
    local strikethrough_color = wp.strikethrough_color or wp.defaults.strikethrough_color
    local letter_spacing = wp.letter_spacing or wp.defaults.letter_spacing
    local gravity = wp.gravity or wp.defaults.gravity
    local gravity_hint = wp.gravity_hint or wp.defaults.gravity_hint
    local insert_hyphens = wp.insert_hyphens or wp.defaults.insert_hyphens
    local text_transform = wp.text_transform or wp.defaults.text_transform
    local line_height = wp.line_height or wp.defaults.line_height
    local text = wp.text or wp.defaults.text

    -- Need to unescape in a case the text was escaped by other code before
    text = gstring.xml_unescape(tostring(text))
    text = gstring.xml_escape(text)

    self.markup = string.format("<span font_family='%s' font_weight='%s' font_variant='%s' font_stretch='%s' font_size='%s' foreground='%s' underline='%s' underline_color='%s' strikethrough='%s' strikethrough_color='%s' letter_spacing='%s' gravity='%s' gravity_hint='%s' insert_hyphens='%s' text_transform='%s' line_height='%s'>%s%s%s%s%s</span>",
        font,
        font_weight,
        font_variant,
        font_stretch,
        ceil((dpi(size * scale)) * 1024),
        color,
        underline,
        underline_color,
        tostring(strikethrough),
        strikethrough_color,
        ceil(letter_spacing * 1024),
        gravity,
        gravity_hint,
        tostring(insert_hyphens),
        text_transform,
        ceil(line_height * 1024),
        bold_start,
        italic_start,
        text,
        italic_end,
        bold_end
    )
end

function text:set_icon(icon)
    local wp = self._private

    wp.icon = icon
    wp.defaults.font = wp.font or icon.font
    wp.defaults.size = wp.size or icon.size
    wp.defaults.color = wp.color or icon.color
    wp.defaults.text = icon.icon

    self:emit_signal("widget::redraw_needed")
    self:emit_signal("property::icon", icon)
end

function text:get_size()
    local wp = self._private
    return wp.size or wp.defaults.size
end

local function new(hot_reload)
    local widget = wibox.widget.textbox()
    gtable.crush(widget, text, true)

    local wp = widget._private

    -- Setup default values
    wp.defaults = {}
    wp.defaults.font = beautiful.font_name
    wp.defaults.font_weight = "normal"
    wp.defaults.font_stretch = "normal"
    wp.defaults.font_variant = "normal"
    wp.defaults.size = 20
    wp.defaults.scale = 1
    wp.defaults.color = beautiful.colors.on_background
    wp.defaults.underline = "none"
    wp.defaults.underline_color = beautiful.colors.on_background
    wp.defaults.strikethrough = false
    wp.defaults.strikethrough_color = beautiful.colors.on_background
    wp.defaults.letter_spacing = 0
    wp.defaults.gravity = "south"
    wp.defaults.gravity_hint = "natural"
    wp.defaults.insert_hyphens = false
    wp.defaults.text_transform = "none"
    wp.defaults.line_height = 0
    wp.defaults.text = ""

    widget:connect_signal("widget::redraw_needed", function()
        generate_markup(widget)
    end)

    if hot_reload ~= false then
        capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
            if wp.color then
                wp.color = old_colorscheme_to_new_map[wp.color]
            elseif wp.defaults.color then
                    -- TODO - Fix notif center icon not hot reloading
                    local new_color = old_colorscheme_to_new_map[wp.defaults.color]
                    if new_color then
                        wp.defaults.color = new_color
                    end
            end

            generate_markup(widget)
        end)
    end

    return widget
end

function text.mt:__call(...)
    return new(...)
end

build_properties(text, properties)

return setmetatable(text, text.mt)
