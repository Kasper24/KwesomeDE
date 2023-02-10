-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gtable = require("gears.table")
local wibox = require("wibox")
local beautiful = require("beautiful")
local theme_daemon = require("daemons.system.theme")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable
local capi = {
    awesome = awesome,
    mouse = mouse
}

local elevated_button_normal = {
    mt = {}
}

local properties = { "forced_width", "forced_height", "halign", "valign", "hover_cursor",
                    "normal_bg", "hover_bg", "press_bg", "normal_shape", "hover_shape",
                    "press_shape", "normal_border_width", "hover_border_width", "press_border_width",
                    "normal_border_color", "hover_border_color", "press_border_color", "on_hover", "on_leave",
                    "on_press", "on_release", "on_secondary_press", "on_secondary_release", "on_scroll_up",
                    "on_scroll_down"}

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

function elevated_button_normal:effect(instant)
    local wp = self._private
    local on_prefix = wp.state and "on_" or ""
    local key = on_prefix .. wp.mode .. "_"

    local bg = wp[key .. "bg"] or wp.defaults[key .. "bg"]
    local shape = wp[key .. "shape"] or wp.defaults[key .. "shape"]
    local border_width = wp[key .. "border_width"] or wp.defaults[key .. "border_width"]
    local border_color = wp[key .. "border_color"] or wp.defaults[key .. "border_color"]

    if instant == true then
        self.animation:stop()
        self.bg = bg
        self.border_width = border_width
        self.border_color = border_color
        self.animation.pos = {
            color = helpers.color.hex_to_rgb(bg),
            border_width = border_width,
            border_color = helpers.color.hex_to_rgb(border_color)
        }
    else
        self.animation:set{
            color = helpers.color.hex_to_rgb(bg),
            border_width = border_width,
            border_color = helpers.color.hex_to_rgb(border_color)
        }
    end
    self.shape = shape
end

function elevated_button_normal:set_child(child)
    local child_widget = wibox.widget {
        widget = wibox.container.place,
        halign = self._private.halign or "center",
        valign = self._private.valign or "center",
        {
            widget = wibox.container.margin,
            margins = dpi(10),
            child
        }
    }
    self._private.child = child
    self:set_widget(child_widget)
end

function elevated_button_normal:get_child()
    return self._private.child
end

function elevated_button_normal:set_halign(halign)
    self._private.halign = halign
    if self._private.widget then
        self._private.widget:set_halign(halign)
    end
end

function elevated_button_normal:set_valign(valign)
    self._private.valign = valign
    if self._private.widget then
        self._private.widget:set_valign(valign)
    end
end

function elevated_button_normal:set_normal_bg(normal_bg)
    local wp = self._private
    wp.normal_bg = normal_bg
    wp.defaults.hover_bg = helpers.color.button_color(normal_bg, 0.1)
    wp.defaults.press_bg = helpers.color.button_color(normal_bg, 0.2)
    self:effect(true)
end

function elevated_button_normal:set_normal_shape(normal_shape)
    local wp = self._private
    wp.normal_shape = normal_shape
    wp.defaults.hover_shape = normal_shape
    wp.defaults.press_shape = normal_shape
    self:effect(true)
end

function elevated_button_normal:set_normal_border_width(normal_border_width)
    local wp = self._private
    wp.normal_border_width = normal_border_width
    wp.defaults.hover_border_width = normal_border_width
    wp.defaults.press_border_width = normal_border_width
    self:effect(true)
end

function elevated_button_normal:set_normal_border_color(normal_border_color)
    local wp = self._private
    wp.normal_border_color = normal_border_color
    wp.defaults.hover_border_color = normal_border_color
    wp.defaults.press_border_color = normal_border_color
    self:effect(true)
end

local function new(is_state)
    local widget = wibox.container.background()
    gtable.crush(widget, elevated_button_normal, true)

    local wp = widget._private
    wp.mode = "normal"

    wp.defaults = {}

    -- Setup default values
    wp.defaults.hover_cursor = beautiful.hover_cursor

    wp.defaults.normal_bg = beautiful.colors.background
    wp.defaults.hover_bg = helpers.color.button_color(wp.defaults.normal_bg, 0.1)
    wp.defaults.press_bg = helpers.color.button_color(wp.defaults.normal_bg, 0.2)

    wp.defaults.normal_shape = helpers.ui.rrect(beautiful.border_radius)
    wp.defaults.hover_shape = wp.defaults.normal_shape
    wp.defaults.press_shape = wp.defaults.normal_shape

    wp.defaults.normal_border_width = 0
    wp.defaults.hover_border_width = wp.defaults.normal_border_width
    wp.defaults.press_border_width = wp.defaults.normal_border_width

    wp.defaults.normal_border_color = beautiful.colors.transparent
    wp.defaults.hover_border_color = wp.defaults.normal_border_color
    wp.defaults.press_border_color = wp.defaults.normal_border_color

    wp.on_hover = nil
    wp.on_leave = nil
    wp.on_press = nil
    wp.on_release = nil
    wp.on_secondary_press = nil
    wp.on_secondary_release = nil
    wp.on_scroll_up = nil
    wp.on_scroll_down = nil

    -- Color/Border animations
    widget.animation = helpers.animation:new{
        easing = helpers.animation.easing.linear,
        duration = 0.2,
        update = function(self, pos)
            if pos.color then
                widget.bg = helpers.color.rgb_to_hex(pos.color)
            end
            if pos.border_width then
                widget.border_width = pos.border_width
            end
            if pos.border_color then
                widget.border_color = helpers.color.rgb_to_hex(pos.border_color)
            end
        end
    }

    widget:connect_signal("mouse::enter", function(self, find_widgets_result)
        local wibox = capi.mouse.current_wibox
        if wibox then
            wibox.cursor = wp.hover_cursor or wp.defaults.hover_cursor
        end

        wp.mode = "hover"
        self:effect()
        widget:emit_signal("event", "hover")

        if wp.on_hover ~= nil then
            wp.on_hover(self, find_widgets_result)
        end
    end)

    widget:connect_signal("mouse::leave", function(self, find_widgets_result)
        if widget.button ~= nil then
            widget:emit_signal("event", "release")
        end

        local wibox = capi.mouse.current_wibox
        if wibox then
            wibox.cursor = "left_ptr"
        end

        wp.mode = "normal"
        self:effect()
        widget:emit_signal("event", "leave")

        if wp.on_leave ~= nil then
            wp.on_leave(self, find_widgets_result)
        end
    end)

    if is_state ~= true then
        widget:connect_signal("button::press", function(self, lx, ly, button, mods, find_widgets_result)
            if helpers.table.contains(mods, "Mod4") then
                return
            end

            widget.button = button

            if button == 1 then
                wp.mode = "press"
                self:effect()
                widget:emit_signal("event", "press")

                if wp.on_press ~= nil then
                    wp.on_press(self, lx, ly, button, mods, find_widgets_result)
                end
            elseif button == 3 then
                if wp.on_secondary_press ~= nil then
                    wp.mode = "press"
                    self:effect()
                    widget:emit_signal("event", "secondary_press")
                    wp.on_secondary_press(self, lx, ly, button, mods, find_widgets_result)
                end
            elseif button == 4 then
                if wp.on_scroll_up ~= nil then
                    wp.on_scroll_up(self, lx, ly, button, mods, find_widgets_result)
                end
            elseif button == 5 then
                if wp.on_scroll_down ~= nil then
                    wp.on_scroll_down(self, lx, ly, button, mods, find_widgets_result)
                end
            end
        end)

        widget:connect_signal("button::release", function(self, lx, ly, button, mods, find_widgets_result)
            widget.button = nil

            if button == 1 then
                wp.mode = "normal"
                self:effect()
                widget:emit_signal("event", "release")

                if wp.on_release ~= nil then
                    wp.on_release(self, lx, ly, button, mods, find_widgets_result)
                end
            elseif button == 3 then
                if wp.on_secondary_release ~= nil then
                    wp.mode = "normal"
                    self:effect()
                    widget:emit_signal("event", "secondary_release")
                    wp.on_secondary_release(self, lx, ly, button, mods, find_widgets_result)
                end
            end
        end)
    end

    widget:effect(true)

    capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
        wp.normal_bg = old_colorscheme_to_new_map[wp.normal_bg] or
                        old_colorscheme_to_new_map[wp.defaults.normal_bg]
        wp.hover_bg = old_colorscheme_to_new_map[wp.hover_bg] or
                        old_colorscheme_to_new_map[wp.defaults.hover_bg] or
                        helpers.color.button_color(wp.normal_bg, 0.1)
        wp.press_bg = old_colorscheme_to_new_map[wp.press_bg] or
                        old_colorscheme_to_new_map[wp.defaults.press_bg] or
                        helpers.color.button_color(wp.normal_bg, 0.2)

        widget:effect(true)
    end)

    return widget
end

function elevated_button_normal.mt:__call(...)
    return new(...)
end

build_properties(elevated_button_normal, properties)

return setmetatable(elevated_button_normal, elevated_button_normal.mt)
