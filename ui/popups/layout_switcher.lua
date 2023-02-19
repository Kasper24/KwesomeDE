-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("ui.widgets")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local ipairs = ipairs
local capi = {
    tag = tag
}

local layout_switcher = {}
local instance = nil

function layout_switcher:cycle_layouts(increase)
    local layout = awful.screen.focused().selected_tag.layout
    local layouts = awful.screen.focused().selected_tag.layouts

    local increase = increase and 1 or -1
    awful.layout.set(gtable.cycle_value(layouts, layout, increase), nil)
end

local function layout_widget(layout, tag)
    local button = wibox.widget
    {
        widget = widgets.button.elevated.state,
        on_turn_on = function()
            tag.layout = layout
        end,
        child = {
            layout = wibox.layout.fixed.horizontal,
            forced_width = dpi(230),
            forced_height = dpi(50),
            spacing = dpi(15),
            {
                widget = wibox.widget.imagebox,
                image = beautiful["layout_" .. (layout.name or "")],
            },
            {
                widget = widgets.text,
                size = 12,
                text = layout.name
            }
        }
    }

    if tag.layout == layout then
        button:turn_on()
    else
        button:turn_off()
    end

    tag:connect_signal("property::layout", function()
        if tag.layout == layout then
            button:turn_on()
        else
            button:turn_off()
        end
    end)

    return button
end

local function new()
    local layouts = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15)
    }

    local widget = widgets.animated_popup {
        placement = awful.placement.centered,
        ontop = true,
        visible = false,
        shape = helpers.ui.rrect(),
        bg = beautiful.colors.background,
        maximum_height = dpi(700),
        widget = wibox.widget {
            widget = wibox.container.margin,
            margins = dpi(25),
            layouts
        }
    }
    gtable.crush(widget, layout_switcher)

    capi.tag.connect_signal("property::selected", function(tag)
        layouts:reset()

        for _, layout in ipairs(tag.layouts) do
            layouts:add(layout_widget(layout, tag))
        end
    end)

    local tag  = awful.screen.focused().selected_tag
    for _, layout in ipairs(tag.layouts) do
        layouts:add(layout_widget(layout, tag))
    end

    return widget
end

if not instance then
    instance = new()
end
return instance
