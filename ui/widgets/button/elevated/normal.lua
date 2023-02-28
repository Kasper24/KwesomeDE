-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gtable = require("gears.table")
local gcolor = require("gears.color")
local wibox = require("wibox")
local bwidget = require("ui.widgets.background")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable
local ipairs = ipairs
local table = table
local math = math
local pi = math.pi
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
    "normal_bg",
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

function elevated_button_normal:build_animable_child_anims(child)
    local wp = self._private
    if child._private.text_normal_bg or child._private.text_on_normal_bg then
        table.insert(wp.animable_childs, {
            widget = child,
            original_size = child:get_size(),
            color_anim = helpers.animation:new{
                easing = helpers.animation.easing.linear,
                duration = 0.2,
                update = function(self, pos)
                    child:set_color(pos)
                end
            },
            size_anim = helpers.animation:new{
                pos = child:get_size(),
                easing = helpers.animation.easing.linear,
                duration = 0.125,
                update = function(self, pos)
                    child:set_size(pos)
                end
            }
        })
        self:effect(true)
        capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
            local wp = child._private
            wp.text_normal_bg = old_colorscheme_to_new_map[wp.text_normal_bg] or
                                    old_colorscheme_to_new_map[wp.defaults.text_normal_bg]
            wp.text_on_normal_bg = old_colorscheme_to_new_map[wp.text_on_normal_bg] or
                                    old_colorscheme_to_new_map[wp.defaults.text_on_normal_bg] or
                                    helpers.color.button_color(wp.text_normal_bg, 0.2)

            self:effect(true)
        end)
    elseif child._private.normal_bg or child._private.on_normal_bg then
        table.insert(wp.animable_childs, {
            widget = child,
            bg_anim = helpers.animation:new{
                easing = helpers.animation.easing.linear,
                duration = 0.2,
                update = function(self, pos)
                    child.bg = pos
                end
            },
        })
        self:effect(true)
        capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
            local wp = child._private
            wp.normal_bg = old_colorscheme_to_new_map[wp.normal_bg] or
                                    old_colorscheme_to_new_map[wp.defaults.normal_bg]
            wp.on_normal_bg = old_colorscheme_to_new_map[wp.on_normal_bg] or
                                    old_colorscheme_to_new_map[wp.defaults.on_normal_bg] or
                                    helpers.color.button_color(wp.normal_bg, 0.2)

            self:effect(true)
        end)
    end
end

function elevated_button_normal:effect(instant)
    local wp = self._private
    local on_prefix = wp.state and "on_" or ""
    local key = on_prefix .. wp.mode .. "_"
    local bg_key = on_prefix .. "normal" .. "_" .. "bg"

    local bg = wp[bg_key] or wp.defaults[bg_key]
    local shape = wp[key .. "shape"] or wp.defaults[key .. "shape"]
    local border_width = wp[key .. "border_width"] or wp.defaults[key .. "border_width"]
    local border_color = wp[key .. "border_color"] or wp.defaults[key .. "border_color"]

    local state_layer_opacity = 0
    if wp.mode == "hover" then
        state_layer_opacity = 0.08
    elseif wp.mode == "press" then
        state_layer_opacity = 0.12
    end

    if instant == true then
        wp.anim:stop()
        self.bg = bg
        self.border_width = border_width
        self.border_color = border_color
        wp.anim.pos = {
            bg = bg,
            border_width = border_width,
            border_color = border_color,
            state_layer_opacity = state_layer_opacity
        }
        for _, child in ipairs(wp.animable_childs) do
            if child.color_anim then
                local child_color = child.widget._private["text_" .. on_prefix .. "normal_bg"]
                child.color_anim.pos = child_color
                child.widget:set_color(child_color)
            elseif child.bg_anim then
                local child_bg = child.widget._private[on_prefix .. "normal_bg"]
                child.bg_anim.pos = child_bg
                child.widget.bg = child_bg
            end
        end
    else
        wp.anim:set{
            bg = bg,
            border_width = border_width,
            border_color = border_color,
            state_layer_opacity = state_layer_opacity
        }
        if wp.old_mode ~= "press" and wp.mode == "press" then
            self:get_ripple_layer().x = wp.lx
            self:get_ripple_layer().y = wp.ly
            wp.ripple_anim.pos = {radius = 0, opacity = 0}
            wp.ripple_anim:set({radius = wp.widget_width, opacity = 0.5})
        elseif wp.old_mode == "press" and wp.mode ~= "press" then
            wp.ripple_anim:stop()
            self:get_ripple_layer().radius = 0
            self:get_ripple_layer():emit_signal("widget::redraw_needed")
        end
        for _, child in ipairs(wp.animable_childs) do
            if child.color_anim then
                local child_color = child.widget._private["text_" .. on_prefix .. "normal" .. "_" .. "bg"]
                child.color_anim:set(child_color)
                if wp.old_mode ~= "press" and wp.mode == "press" then
                    child.size_anim:set(child.original_size / 1.5)
                elseif wp.old_mode == "press" and wp.mode ~= "press" then
                    child.size_anim:set(child.original_size)
                end
            elseif child.bg_anim then
                local child_bg = child.widget._private[on_prefix .. "normal" .. "_" .. "bg"]
                child.bg_anim:set(child_bg)
            end
        end
    end
    self.shape = shape

    if self.text_effect then
        self:text_effect(instant)
    end
end

function elevated_button_normal:set_widget(new_widget)
    local wp = self._private

    local widget = wibox.widget {
        layout = wibox.layout.stack,
        {
            widget = wibox.widget.base.make_widget,
            id = "ripple_layer",
            x = 0,
            y = 0,
            radius = 0,
            draw = function(self, __, cr, width, height)
                cr:set_source(gcolor.change_opacity(beautiful.colors.on_background, self.opacity))
                cr:translate(self.x, self.y)
                cr:arc(0, 0, self.radius, 0, pi * 2)
                cr:fill()
            end,
        },
        {
            widget = bwidget,
            id = "state_layer",
            bg = beautiful.colors.on_background,
            opacity = 0,
        },
        {
            widget = wibox.container.place,
            id = "place",
            halign = wp.halign or "center",
            valign = wp.valign or "center",
            {
                widget = wibox.container.margin,
                id = "paddings",
                margins = wp.paddings or dpi(10),
                new_widget
            }
        }
    }

    wp.widget = widget
    wp.content_widget = new_widget
    wp.ripple_layer = widget:get_children_by_id("ripple_layer")[1]
    wp.state_layer = widget:get_children_by_id("state_layer")[1]
    wp.animable_childs = {}

    if wp.color_animation == nil then
        if new_widget.all_children then
            for _, child in ipairs(new_widget.all_children) do
                self:build_animable_child_anims(child)
            end
        end
        self:build_animable_child_anims(new_widget)
    end

    self:emit_signal("property::widget")
    self:emit_signal("widget::layout_changed")
end

function elevated_button_normal:get_content_widget()
    return self._private.content_widget
end

function elevated_button_normal:get_ripple_layer()
    return self._private.ripple_layer
end

function elevated_button_normal:get_state_layer()
    return self._private.state_layer
end

function elevated_button_normal:set_halign(halign)
    self._private.halign = halign
    local widget = self:get_widget()
    if widget then
        widget:get_children_by_id("place")[1].halign = halign
    end
end

function elevated_button_normal:set_valign(valign)
    self._private.valign = valign
    local widget = self:get_widget()
    if widget then
        widget:get_children_by_id("place")[1].valign = valign
    end
end

function elevated_button_normal:set_paddings(paddings)
    self._private.paddings = paddings
    local widget = self:get_widget()
    if widget then
        widget:get_children_by_id("paddings")[1].margins = paddings
    end
end

function elevated_button_normal:set_normal_bg(normal_bg)
    local wp = self._private
    wp.normal_bg = normal_bg
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

    -- Setup default values
    wp.defaults = {}

    wp.defaults.hover_cursor = "hand2"

    wp.defaults.normal_bg = beautiful.colors.transparent

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

    wp.animable_childs = {}
    wp.anim = helpers.animation:new{
        easing = helpers.animation.easing.linear,
        duration = 0.2,
        update = function(self, pos)
            widget.bg = pos.bg
            widget.border_width = pos.border_width
            widget.border_color = pos.border_color
            widget:get_state_layer().opacity = pos.state_layer_opacity
        end
    }
    wp.ripple_anim = helpers.animation:new{
        easing = helpers.animation.easing.linear,
        duration = 0.4,
        update = function(self, pos)
            widget:get_ripple_layer().radius = pos.radius
            widget:get_ripple_layer().opacity = pos.opacity
            widget:get_ripple_layer():emit_signal("widget::redraw_needed")
        end
    }

    widget:connect_signal("mouse::enter", function(self, find_widgets_result)
        capi.root.cursor(wp.hover_cursor or wp.defaults.hover_cursor)
        local wibox = capi.mouse.current_wibox
        if wibox then
            wibox.cursor = wp.hover_cursor or wp.defaults.hover_cursor
        end

        wp.old_mode = wp.mode
        wp.mode = "hover"
        self:effect()

        if wp.on_hover ~= nil then
            wp.on_hover(self, find_widgets_result)
        end
    end)

    widget:connect_signal("mouse::leave", function(self, find_widgets_result)
        capi.root.cursor("left_ptr")
        local wibox = capi.mouse.current_wibox
        if wibox then
            wibox.cursor = "left_ptr"
        end

        wp.old_mode = wp.mode
        wp.mode = "normal"
        self:effect()

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
                wp.old_mode = wp.mode
                wp.mode = "press"
                wp.lx = lx
                wp.ly = ly
                wp.widget_width = find_widgets_result.widget_width
                self:effect()

                if wp.on_press then
                    wp.on_press(self, lx, ly, button, mods, find_widgets_result)
                end
            elseif button == 3 and (wp.on_secondary_press or wp.on_secondary_release) then
                wp.old_mode = wp.mode
                wp.mode = "press"
                wp.lx = lx
                wp.ly = ly
                wp.widget_width = find_widgets_result.widget_width
                self:effect()

                if wp.on_secondary_press then
                    wp.on_secondary_press(self, lx, ly, button, mods, find_widgets_result)
                end
            elseif button == 4 and wp.on_scroll_up then
                wp.on_scroll_up(self, lx, ly, button, mods, find_widgets_result)
            elseif button == 5 and wp.on_scroll_down then
                wp.on_scroll_down(self, lx, ly, button, mods, find_widgets_result)
            end
        end)

        widget:connect_signal("button::release", function(self, lx, ly, button, mods, find_widgets_result)
            if button == 1 then
                wp.old_mode = wp.mode
                wp.mode = "hover"
                self:effect()

                if wp.on_release then
                    wp.on_release(self, lx, ly, button, mods, find_widgets_result)
                end
            elseif button == 3 and (wp.on_secondary_release or wp.on_secondary_press) then
                wp.old_mode = wp.mode
                wp.mode = "hover"
                self:effect()

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
        wp.on_normal_bg = old_colorscheme_to_new_map[wp.on_normal_bg] or
                    old_colorscheme_to_new_map[wp.defaults.on_normal_bg] or
                    helpers.color.button_color(wp.normal_bg, 0.2)

        wp.normal_border_color = old_colorscheme_to_new_map[wp.normal_border_color] or
                                old_colorscheme_to_new_map[wp.defaults.normal_border_color]
        wp.hover_border_color = old_colorscheme_to_new_map[wp.hover_border_color] or
                                old_colorscheme_to_new_map[wp.defaults.hover_border_color]
        wp.press_border_color = old_colorscheme_to_new_map[wp.press_border_color] or
                                old_colorscheme_to_new_map[wp.defaults.press_border_color]

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
