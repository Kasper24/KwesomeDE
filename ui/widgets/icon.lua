-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gtable = require("gears.table")
local imagebox = require("wibox.widget.imagebox")
local beautiful = require("beautiful")
local setmetatable = setmetatable
local ipairs = ipairs

local capi = {
    awesome = awesome
}

local icon = {
    mt = {}
}

local properties = {
    "icon", "color"
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

function icon:set_color(color)
    color = color or "#ffffff"
    local wp = self._private
    wp.color = color
    print(string.format("path { fill: %s; }", color))
    self:set_stylesheet(string.format("path { fill: %s; }", color))
end

function icon:set_icon(icon)
    local wp = self._private
    wp.icon = icon
    self.image = icon
    self:set_color(wp.color or wp.defaults.color)
end

local function new(hot_reload)
    local widget = imagebox()
    gtable.crush(widget, icon, true)

    local wp = widget._private

    -- Setup default values
    wp.defaults = {}
    wp.defaults.color = beautiful.colors.random_accent_color()

    if hot_reload ~= false then
        capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
            if wp.color then
                wp.color = old_colorscheme_to_new_map[wp.color]
                widget:set_color(wp.color)
            elseif wp.defaults.color then
                -- TODO - Fix notif center icon not hot reloading
                local new_color = old_colorscheme_to_new_map[wp.defaults.color]
                if new_color then
                    wp.defaults.color = new_color
                else
                    wp.defaults.color = beautiful.colors.random_accent_color()
                end
                widget:set_color(wp.defaults.color)
            end
        end)
    end

    return widget
end

function icon.mt:__call(...)
    return new(...)
end

build_properties(icon, properties)

return setmetatable(icon, icon.mt)
