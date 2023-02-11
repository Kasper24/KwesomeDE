-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local capi = {
    screen = screen
}

local instance = nil

local path = ...
local header = require(path .. ".header")
local dashboard = require(path .. ".dashboard")
local info = require(path .. ".info")
local media = require(path .. ".media")

local function seperator()
    return wibox.widget {
        widget = widgets.background,
        forced_height = dpi(1),
        shape = helpers.ui.rrect(beautiful.border_radius),
        bg = beautiful.colors.surface,
    }
end

local function new()
    action_panel = widgets.animated_panel {
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
                layout = widgets.overflow.vertical,
                spacing = dpi(25),
                scrollbar_widget = widgets.scrollbar,
                scrollbar_width = dpi(10),
                step = 50,
                header,
                seperator(),
                dashboard,
                seperator(),
                info,
                seperator(),
                media
            }
        }
    }

    return action_panel
end

if not instance then
    instance = new()
end
return instance
