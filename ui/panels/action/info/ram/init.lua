-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("ui.widgets")
local ram_daemon = require("daemons.hardware.ram")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local math = math

local instance = nil

local function getPercentage(value, total, total_swap)
    return math.floor(value / (total + total_swap) * 100 + 0.5) .. "%"
end

local function new()
    local chart = wibox.widget {
        widget = widgets.piechart,
        forced_height = 200,
        forced_width = 400,
        colors = {beautiful.colors.random_accent_color(), beautiful.colors.surface,
                    beautiful.colors.random_accent_color()}
    }

    local widget =  widgets.animated_panel {
        ontop = true,
        visible = false,
        minimum_width = dpi(400),
        maximum_width = dpi(400),
        placement = function(widget)
            awful.placement.bottom_right(widget, {
                honor_workarea = true,
                honor_padding = true,
                attach = true,
                margins = { bottom = 450, right = dpi(550)}
            })
        end,
        shape = helpers.ui.rrect(),
        bg = beautiful.colors.background,
        widget = chart
    }

    ram_daemon:connect_signal("update",
    function(self, total, used, free, shared, buff_cache, available, total_swap, used_swap, free_swap)
        widget.widget.data_list =
            {{"used " .. getPercentage(used + used_swap, total, total_swap), used + used_swap},
             {"free " .. getPercentage(free + free_swap, total, total_swap), free + free_swap},
             {"buff_cache " .. getPercentage(buff_cache, total, total_swap), buff_cache}}
    end)

    return widget
end

if not instance then
    instance = new()
end
return instance
