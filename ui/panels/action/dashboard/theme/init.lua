-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("ui.widgets")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi

local instance = nil

local function new()
    local stack = wibox.layout.stack()
    stack:set_top_only(true)

    local widget =  widgets.animated_panel {
        ontop = true,
        visible = false,
        minimum_width = dpi(800),
        maximum_width = dpi(800),
        minimum_height = dpi(1060),
        maximum_height = dpi(1060),
        placement = function(widget)
            awful.placement.top_right(widget, {
                honor_workarea = true,
                honor_padding = true,
                attach = true,
                margins = {right = dpi(550)}
            })
        end,
        shape = helpers.ui.rrect(),
        bg = beautiful.colors.background,
        widget = wibox.widget {
            widget = wibox.container.margin,
            margins = dpi(15),
            stack
        }
    }

    stack:add(require("ui.apps.theme.main")(widget, stack))
    stack:add(require("ui.apps.theme.settings")(stack))

    return widget
end

if not instance then
    instance = new()
end
return instance
