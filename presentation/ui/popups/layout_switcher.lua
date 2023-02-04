-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local wibox = require("wibox")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi

local layout_switcher = {}
local instance = nil

function layout_switcher:cycle_layouts(increase)
    local ll = self._private.layout_list
    local increase = increase and 1 or -1
    awful.layout.set(gtable.cycle_value(ll.layouts, ll.current_layout, increase), nil)
end

function layout_switcher:show()
    self._private.widget.visible = true
end

function layout_switcher:hide()
    self._private.widget.visible = false
end

function layout_switcher:toggle()
    if self._private.widget.visible == true then
        self:hide()
    else
        self:show()
    end
end

local function new()
    local ret = gobject {}
    ret._private = {}

    gtable.crush(ret, layout_switcher)

    ret._private = {}
    ret._private.layout_list = awful.widget.layoutlist {
        source = awful.widget.layoutlist.source.default_layouts,
        base_layout = wibox.widget {
            layout = wibox.layout.grid.vertical,
            spacing = dpi(15),
            forced_num_cols = 4
        },
        widget_template = {
            widget = wibox.container.background,
            id = "background_role",
            forced_width = dpi(70),
            forced_height = dpi(70),
            {
                widget = wibox.container.margin,
                margins = dpi(25),
                {
                    widget = wibox.widget.imagebox,
                    id = "icon_role",
                    forced_height = dpi(70),
                    forced_width = dpi(70)
                }
            }
        }
    }

    ret._private.widget = awful.popup {
        placement = awful.placement.centered,
        ontop = true,
        visible = false,
        shape = helpers.ui.rrect(beautiful.border_radius),
        bg = beautiful.colors.background,
        widget = wibox.widget {
            widget = wibox.container.margin,
            margins = dpi(25),
            ret._private.layout_list
        }
    }

    return ret
end

if not instance then
    instance = new()
end
return instance
