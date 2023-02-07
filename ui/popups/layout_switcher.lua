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
local capi = {
    tag = tag
}

local layout_switcher = {}
local instance = nil

function layout_switcher:cycle_layouts(increase)
    local ll = self.layout_list
    local increase = increase and 1 or -1
    awful.layout.set(gtable.cycle_value(ll.layouts, ll.current_layout, increase), nil)
end

function layout_switcher:show()
    self.widget.visible = true
end

function layout_switcher:hide()
    self.widget.visible = false
end

function layout_switcher:toggle()
    if self.widget.visible == true then
        self:hide()
    else
        self:show()
    end
end

local function create_layouts_for_tag(tag, layouts)
    layouts:reset()

    for _, layout in ipairs(tag.layouts) do
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

        layouts:add(button)
    end
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, layout_switcher)

    ret.layout_list = awful.widget.layoutlist {
        source = awful.widget.layoutlist.source.default_layouts,
    }

    local layouts = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15)
    }

    capi.tag.connect_signal("property::selected", function(tag)
        create_layouts_for_tag(tag, layouts)
    end)

    create_layouts_for_tag(awful.screen.focused().selected_tag, layouts)

    ret.widget = widgets.popup {
        placement = awful.placement.centered,
        ontop = true,
        visible = false,
        shape = helpers.ui.rrect(beautiful.border_radius),
        bg = beautiful.colors.background,
        widget = wibox.widget {
            widget = wibox.container.margin,
            margins = dpi(25),
            layouts
        }
    }

    return ret
end

if not instance then
    instance = new()
end
return instance
