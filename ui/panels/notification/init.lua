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
local capi = {
    screen = screen
}

local instance = nil

local path = ...
local top = require(path .. ".top")
local bottom = require(path .. ".bottom")

local function separator()
    return wibox.widget {
        widget = wibox.widget.separator,
        forced_width = dpi(1),
        forced_height = dpi(1),
        shape = helpers.ui.rrect(beautiful.border_radius),
        orientation = "horizontal",
        color = beautiful.colors.surface
    }
end

local function new()
    return widgets.animated_popup {
        type = "dock",
        visible = false,
        ontop = true,
        minimum_width = dpi(550),
        maximum_width = dpi(550),
        minimum_height = capi.screen.primary.workarea.height,
        maximum_height = capi.screen.primary.workarea.height,
        placement = function(widget)
            awful.placement.top_right(widget, {
                honor_workarea = true,
                honor_padding = true,
                attach = true
            })
        end,
        shape = helpers.ui.rrect(beautiful.border_radius),
        bg = beautiful.colors.background,
        widget = wibox.widget {
            widget = wibox.container.margin,
            margins = dpi(25),
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(30),
                top,
                separator(),
                bottom
            }
        }
    }
end

if not instance then
    instance = new()
end
return instance
