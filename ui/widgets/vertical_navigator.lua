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

local vertical_navigator = {
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

function vertical_navigator:set_tabs(tabs)
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

function vertical_navigator:get_tabs()
    return self._private.tabs
end

local function new()
    local widget = wibox.widget {
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
    }
    gtable.crush(widget, vertical_navigator, true)

    widget._private.tabs_buttons = widget:get_children_by_id("tabs_buttons")[1]
    widget._private.tabs_stack = widget:get_children_by_id("tabs_stack")[1]

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

function vertical_navigator.mt:__call()
    return new()
end

return setmetatable(vertical_navigator, vertical_navigator.mt)
