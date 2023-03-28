-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gtable = require("gears.table")
local wibox = require("wibox")
local bwidget = require("ui.widgets.background")
local sbwidget = require("ui.widgets.scrollbar")
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

function navigator:set_tabs(tabs)
    self._private.tabs = tabs

    for group_index, group in ipairs(tabs) do
        for tab_index, entry in ipairs(group) do
            if group_index == 1 and tab_index == 1 then
                entry.button:turn_on()
            end

            self._private.tabs_buttons:add(entry.button)
            self._private.tabs_stack:add(entry.tab)
        end
        if group_index ~= #tabs then
            self._private.tabs_buttons:add(separator())
        end
    end
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

local function new()
    local widget = wibox.container.background()
    gtable.crush(widget, navigator, true)

    widget:connect_signal("tab::select", function(self, id)
        for _, tab_group in ipairs(self._private.tabs) do
            for _, tab in ipairs(tab_group) do
                if tab.id == id then
                    widget._private.tabs_stack:raise_widget(tab.tab)
                    tab.button:turn_on()
                else
                    tab.button:turn_off()
                end
            end
        end
    end)

    return widget
end

function navigator.horizontal()
    local widget = new()
    widget:set_widget_template(wibox.widget {
        layout = wibox.layout.fixed.vertical,
        fill_space = true,
        spacing = dpi(15),
        {
            layout = wibox.layout.overflow.horizontal,
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

function navigator.vertical()
    local widget = new()
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
