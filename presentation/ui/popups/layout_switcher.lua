-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gtable = require("gears.table")
local wibox = require("wibox")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi

local instance = nil

local function new()
    local ret = {}

    awful.keygrabber
    {
        start_callback = function()
            ret.widget.visible = true
        end,
        stop_callback = function()
            ret.widget.visible = false
        end,
        export_keybindings = true,
        stop_event = "release",
        stop_key = { "Escape", "Super_L", "Super_R", "Mod4" },
        keybindings =
        {
            {
                {"Mod4", "Shift"},
                " ",
                function()
                    awful.layout.set(gtable.cycle_value(ret.layout_list.layouts, ret.layout_list.current_layout, -1), nil)
                end
            },
            {
                {"Mod4", "Mod1"},
                " ",
                function()
                    awful.layout.set(gtable.cycle_value(ret.layout_list.layouts, ret.layout_list.current_layout, 1), nil)
                end
            }
        }
    }

    ret.layout_list = awful.widget.layoutlist
    {
        source = awful.widget.layoutlist.source.default_layouts,
        base_layout = wibox.widget
        {
            layout = wibox.layout.grid.vertical,
            spacing = dpi(15),
            forced_num_cols = 4,
        },
        widget_template =
        {
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
                    forced_width = dpi(70),
                }
            }
        }
    }

    ret.widget = awful.popup
    {
        placement = awful.placement.centered,
        ontop = true,
        visible = false,
        shape = helpers.ui.rrect(beautiful.border_radius),
        bg = beautiful.colors.background,
        widget = wibox.widget
        {
            widget = wibox.container.margin,
            margins = dpi(25),
            ret.layout_list
        },
    }

    return ret
end

if not instance then
    instance = new()
end
return instance