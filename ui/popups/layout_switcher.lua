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

local function layout_widget(self, layout)
    local widget = wibox.widget
    {
        widget = widgets.button.elevated.state,
        layout_name = layout.name,
        on_release = function()
            awful.screen.focused().selected_tag.layout = layout
        end,
        {
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

    if awful.screen.focused().selected_tag.layout.name == layout.name then
        widget:turn_on()
    end

    self:connect_signal("layout::selected", function(self, name)
        if layout.name == name then
            widget:turn_on()
        else
            widget:turn_off()
        end
    end)

    return widget
end

local function new()
    local widget = widgets.animated_popup {
        placement = awful.placement.centered,
        ontop = true,
        visible = false,
        shape = helpers.ui.rrect(),
        bg = beautiful.colors.background,
        maximum_height = dpi(715),
        widget = wibox.widget {
            widget = wibox.container.margin,
            margins = dpi(25),
            {
                layout = wibox.layout.fixed.vertical,
                id = "layouts",
                spacing = dpi(15)
            }
        }
    }
    gtable.crush(widget, layout_switcher)

    local layouts  = awful.screen.focused().selected_tag.layouts
    local layouts_widget = widget.widget:get_children_by_id("layouts")[1]
    for _, layout in ipairs(layouts) do
        layouts_widget:add(layout_widget(widget, layout))
    end

    capi.tag.connect_signal("property::selected", function(tag)
        widget:emit_signal("layout::selected", tag.layout.name)
    end)

    capi.tag.connect_signal("property::layout", function(tag)
        widget:emit_signal("layout::selected", tag.layout.name)
    end)

    return widget
end

if not instance then
    instance = new()
end
return instance
