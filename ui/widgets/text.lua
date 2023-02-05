-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gtable = require("gears.table")
local gstring = require("gears.string")
local wibox = require("wibox")
local beautiful = require("beautiful")
local helpers = require("helpers")
local setmetatable = setmetatable
local tostring = tostring
local string = string
local capi = {
    awesome = awesome
}

local text = {
    mt = {}
}

local properties = {"bold", "italic", "size", "color", "text", "icon"}

local function generate_markup(self)
    local bold_start = ""
    local bold_end = ""
    local italic_start = ""
    local italic_end = ""

    if self._private.bold == true then
        bold_start = "<b>"
        bold_end = "</b>"
    end
    if self._private.italic == true then
        italic_start = "<i>"
        italic_end = "</i>"
    end

    local font = self._private.font or beautiful.font_name
    local size = self._private.size or 20
    local color = self._private.color or beautiful.colors.on_background
    local text = self._private.text or ""

    -- Need to unescape in a case the text was escaped by other code before
    text = gstring.xml_unescape(tostring(text))
    text = gstring.xml_escape(tostring(text))

    size = math.ceil(size * 1024)
    self.markup = string.format("<span font_family='%s' font_size='%s'>", font, size) .. bold_start .. italic_start ..
                      helpers.ui.colorize_text(text, color) .. italic_end .. bold_end .. "</span>"
end

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

function text:set_icon(icon)
    local wp = self._private

    wp.icon = icon
    wp.font = wp.font or icon.font
    wp.size = wp.size or icon.size or 20
    wp.color = wp.color or icon.color
    wp.text = icon.icon

    self:emit_signal("widget::redraw_needed")
    self:emit_signal("property::icon", icon)
end

local function new(hot_reload)
    local widget = wibox.widget.textbox()
    gtable.crush(widget, text, true)

    local wp = widget._private

    -- Setup default values
    wp.bold = false
    wp.italic = false

    widget:connect_signal("widget::redraw_needed", function()
        generate_markup(widget)
    end)

    if hot_reload ~= false then
        capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
            wp.color = old_colorscheme_to_new_map[wp.color]
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
