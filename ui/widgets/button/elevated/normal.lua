-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gtable = require("gears.table")
local wibox = require("wibox")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable
local ipairs = ipairs
local capi = {
    awesome = awesome,
    root = root,
    mouse = mouse
}

local elevated_button_normal = {
    mt = {}
}

local properties = {
    "halign", "valign",
    "hover_cursor",
    "normal_bg", "hover_bg", "press_bg",
    "normal_shape", "hover_shape", "press_shape",
    "normal_border_width", "hover_border_width", "press_border_width",
    "normal_border_color", "hover_border_color", "press_border_color",
    "on_hover", "on_leave",
    "on_press", "on_release",
    "on_secondary_press", "on_secondary_release",
    "on_scroll_up", "on_scroll_down"
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

    if self.text_effect then
        self:text_effect(instant)
    end
end

function elevated_button_normal:set_widget(widget)
    local widget = wibox.widget {
        widget = wibox.container.place,
        halign = self._private.halign or "center",
        valign = self._private.valign or "center",
        {
            widget = wibox.container.margin,
            id = "paddings",
            margins = self._private.paddings or dpi(10),
            widget
        }
    }

    self._private.widget = widget
    self:emit_signal("property::widget")
    self:emit_signal("widget::layout_changed")
end

function elevated_button_normal:get_content_widget()
    return self:get_widget():get_children_by_id("paddings")[1].children[1]
end

function elevated_button_normal:set_halign(halign)
    local widget = self:get_widget()
    if widget then
        self._private.halign = halign
        widget:set_halign(halign)
    end
end

function elevated_button_normal:set_valign(valign)
    local widget = self:get_widget()
    if widget then
        self._private.valign = valign
        widget:set_valign(valign)
    end
end

function elevated_button_normal:set_paddings(paddings)
    local widget = self:get_widget()
    if widget then
        self._private.paddings = paddings
        widget:get_children_by_id("paddings")[1].margins = paddings
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
    wp.defaults.hover_cursor = "hand2"

    wp.defaults.normal_bg = beautiful.colors.transparent
    wp.defaults.hover_bg = helpers.color.button_color(wp.defaults.normal_bg, 0.1)
    wp.defaults.press_bg = helpers.color.button_color(wp.defaults.normal_bg, 0.2)

    wp.defaults.normal_shape = helpers.ui.rrect()
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
            widget.bg = helpers.color.rgb_to_hex(pos.color)
            widget.border_width = pos.border_width
            widget.border_color = helpers.color.rgb_to_hex(pos.border_color)
        end
    }

    widget:connect_signal("mouse::enter", function(self, find_widgets_result)
        capi.root.cursor(wp.hover_cursor or wp.defaults.hover_cursor)
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

        capi.root.cursor("left_ptr")
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
            if gtable.hasitem(mods, "Mod4") then
                return
            end

            if button == 1 then
                wp.mode = "press"
                self:effect()
                widget:emit_signal("event", "press")

                if wp.on_press then
                    wp.on_press(self, lx, ly, button, mods, find_widgets_result)
                end
            elseif button == 3 and (wp.on_secondary_press or wp.on_secondary_release) then
                wp.mode = "press"
                self:effect()
                widget:emit_signal("event", "secondary_press")

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
            widget.button = nil

            if button == 1 then
                wp.mode = "hover"
                self:effect()
                widget:emit_signal("event", "release")

                if wp.on_release then
                    wp.on_release(self, lx, ly, button, mods, find_widgets_result)
                end
            elseif button == 3 and (wp.on_secondary_release or wp.on_secondary_press) then
                wp.mode = "hover"
                self:effect()
                widget:emit_signal("event", "secondary_release")

                if wp.on_secondary_release then
                    wp.on_secondary_release(self, lx, ly, button, mods, find_widgets_result)
                end
            end
        end)
    end

    capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
        widget:emit_signal("widget::redraw_needed")

        wp.normal_bg = old_colorscheme_to_new_map[wp.normal_bg] or
                    old_colorscheme_to_new_map[wp.defaults.normal_bg]
        wp.hover_bg = old_colorscheme_to_new_map[wp.hover_bg] or
                    old_colorscheme_to_new_map[wp.defaults.hover_bg] or
                    helpers.color.button_color(wp.normal_bg, 0.1)
        wp.press_bg = old_colorscheme_to_new_map[wp.press_bg] or
                    old_colorscheme_to_new_map[wp.defaults.press_bg] or
                    helpers.color.button_color(wp.normal_bg, 0.2)

        wp.normal_border_color = old_colorscheme_to_new_map[wp.normal_border_color] or
                                old_colorscheme_to_new_map[wp.defaults.normal_border_color]
        wp.hover_border_color = old_colorscheme_to_new_map[wp.hover_border_color] or
                                old_colorscheme_to_new_map[wp.defaults.hover_border_color]
        wp.press_border_color = old_colorscheme_to_new_map[wp.press_border_color] or
                                old_colorscheme_to_new_map[wp.defaults.press_border_color]

        wp.on_normal_bg = old_colorscheme_to_new_map[wp.on_normal_bg] or
                        old_colorscheme_to_new_map[wp.defaults.on_normal_bg] or
                        helpers.color.button_color(wp.normal_bg, 0.2)
        wp.on_hover_bg = old_colorscheme_to_new_map[wp.on_hover_bg] or
                        old_colorscheme_to_new_map[wp.defaults.on_hover_bg] or
                        helpers.color.button_color(wp.on_normal_bg, 0.1)
        wp.on_press_bg = old_colorscheme_to_new_map[wp.on_press_bg] or
                        old_colorscheme_to_new_map[wp.defaults.on_press_bg] or
                        helpers.color.button_color(wp.on_normal_bg, 0.2)

        wp.on_normal_border_color = old_colorscheme_to_new_map[wp.on_normal_border_color] or
                                    old_colorscheme_to_new_map[wp.defaults.on_normal_border_color]
        wp.on_hover_border_color = old_colorscheme_to_new_map[wp.on_hover_border_color] or
                                    old_colorscheme_to_new_map[wp.defaults.on_hover_border_color]
        wp.on_press_border_color = old_colorscheme_to_new_map[wp.on_press_border_color] or
                                    old_colorscheme_to_new_map[wp.defaults.on_press_border_color]

        widget:effect(true)
    end)

    widget:effect(true)

    return widget
end

function elevated_button_normal.mt:__call(...)
    return new(...)
end

build_properties(elevated_button_normal, properties)

return setmetatable(elevated_button_normal, elevated_button_normal.mt)
