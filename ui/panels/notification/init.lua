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
        widget = widgets.background,
        forced_height = dpi(1),
        shape = helpers.ui.rrect(),
        bg = beautiful.colors.surface
    }
end

local function new()
    notification_panel =  widgets.animated_panel {
        visible = false,
        ontop = true,
        minimum_width = dpi(550),
        maximum_width = dpi(550),
        max_height = true,
        placement = function(widget)
            awful.placement.top_right(widget, {
                honor_workarea = true,
                honor_padding = true,
                attach = true
            })
        end,
        shape = helpers.ui.rrect(),
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

    return notification_panel
end

if not instance then
    instance = new()
end
return instance
