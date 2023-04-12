-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gtable = require("gears.table")
local wibox = require("wibox")
local bwidget = require("ui.widgets.background")
local sbwidget = require("ui.widgets.scrollbar")
local ebwidget = require("ui.widgets.button.elevated")
local twidget = require("ui.widgets.text")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local navigator = {
    mt = {}
}

local function separator()
    return wibox.widget {
        widget = bwidget,
        forced_height = dpi(1),
        shape = helpers.ui.rrect(),
        bg = beautiful.colors.surface
    }
end

local function tab_button(navigator, tab, pos)
    local icon = tab.icon and wibox.widget {
        widget = twidget,
        size = 12,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        icon = tab.icon,
    } or nil

    local shape = nil
    if navigator._private.type == "horizontal" then
        shape = helpers.ui.prrect(false, false, false, false)
        if pos == "left" then
            shape = helpers.ui.prrect(true, false, false, true)
        elseif pos == "right" then
            shape = helpers.ui.prrect(false, true, true, false)
        end
    end

    local widget = wibox.widget {
        widget = ebwidget.state,
        halign = tab.halign or "left",
        normal_shape = shape,
        on_normal_bg = navigator._private.buttons_selected_color,
        on_release = function(self)
            navigator:select(tab.id)
        end,
        {
            layout = wibox.layout.fixed.horizontal,
            spacing = dpi(15),
            icon,
            {
                widget = twidget,
                size = 12,
                halign = "left",
                text_normal_bg = beautiful.colors.on_background,
                text_on_normal_bg = beautiful.colors.on_accent,
                text = tab.title,
            }
        }
    }

    return widget
end

function navigator:select(id)
    for _, tab_group in ipairs(self._private.tabs) do
        for _, tab in ipairs(tab_group) do
            if tab.id == id then
                self._private.tabs_stack:raise_widget(tab.tab)
                tab.button:turn_on()
                if self._private.on_select then
                    self._private.on_select(id)
                end
                self:emit_signal("select", id)
            else
                tab.button:turn_off()
            end
        end
    end
end

function navigator:set_tabs(tabs)
    self._private.tabs = tabs

    for group_index, group in ipairs(tabs) do
        for index, tab in ipairs(group) do
            local pos = nil
            if index == 1 then
                pos = "left"
            elseif index == #group then
                pos = "right"
            end

            tab.button = tab_button(self, tab, pos)
            self._private.tabs_buttons:add(tab.button)
            self._private.tabs_stack:add(tab.tab)
        end
        if group_index ~= #tabs then
            self._private.tabs_buttons:add(separator())
        end
    end

    self:select(self._private.tabs[1][1].id)
end

function navigator:get_tabs()
    return self._private.tabs
end

function navigator:set_buttons_header(header)
    self._private.tabs_buttons:insert(1, header)
end

function navigator:set_widget_template(widget_template)
    self:set_widget(widget_template)

    self._private.tabs_buttons = widget_template:get_children_by_id("tabs_buttons")[1]
    self._private.tabs_stack = widget_template:get_children_by_id("tabs_stack")[1]
end

function navigator:set_buttons_spacing(spacing)
    self._private.tabs_buttons.spacing = spacing
end

function navigator:set_buttons_selected_color(buttons_selected_color)
    self._private.buttons_selected_color = buttons_selected_color
    if self._private.tabs then
        for _, tab_group in ipairs(self._private.tabs) do
            for _, tab in ipairs(tab_group) do
                tab.button:set_on_normal_bg(buttons_selected_color)
            end
        end
    end
end

function navigator:set_on_select(on_select)
    self._private.on_select = on_select
end

local function new(type)
    local widget = wibox.container.background()
    gtable.crush(widget, navigator, true)

    widget._private.type = type

    return widget
end

function navigator.horizontal()
    local widget = new("horizontal")
    widget:set_widget_template(wibox.widget {
        layout = wibox.layout.fixed.vertical,
        fill_space = true,
        spacing = dpi(15),
        {
            layout = wibox.layout.flex.horizontal,
            id = "tabs_buttons",
            spacing = 0,
        },
        {
            widget = bwidget,
            forced_width = dpi(1),
            shape = helpers.ui.rrect(),
            bg = beautiful.colors.surface
        },
        {
            layout = wibox.layout.stack,
            id = "tabs_stack",
            top_only = true,
        }
    })

    return widget
end

function navigator.vertical()
    local widget = new("vertical")
    widget:set_widget_template(wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        fill_space = true,
        spacing = dpi(15),
        {
            layout = wibox.layout.overflow.vertical,
            forced_width = dpi(250),
            forced_height = math.huge,
            scrollbar_widget = sbwidget,
            scrollbar_width = dpi(10),
            step = 50,
            id = "tabs_buttons",
            spacing = dpi(15),
        },
        {
            widget = bwidget,
            forced_width = dpi(1),
            shape = helpers.ui.rrect(),
            bg = beautiful.colors.surface
        },
        {
            layout = wibox.layout.stack,
            id = "tabs_stack",
            top_only = true,
        }
    })
    return widget
end

function navigator.mt:__call()
    return new()
end

return setmetatable(navigator, navigator.mt)
