-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("ui.widgets")
local ram_daemon = require("daemons.hardware.ram")
local ui_daemon = require("daemons.system.ui")
local library = require("library")
local dpi = beautiful.xresources.apply_dpi
local math = math

local instance = nil

local function getPercentage(value, total, total_swap)
    return math.floor(value / (total + total_swap) * 100 + 0.5) .. "%"
end

local function new()
    local chart = wibox.widget {
        widget = wibox.widget.piechart,
        forced_height = 200,
        forced_width = 400,
        colors = {beautiful.colors.random_accent_color(), beautiful.colors.surface,
                    beautiful.colors.random_accent_color()}
    }

    local widget =  widgets.animated_popup {
        ontop = true,
        visible = false,
        maximum_width = dpi(400),
        minimum_height = dpi(250),
        maximum_height = dpi(250),
        animate_method = "width",
        hide_on_clicked_outside = true,
        placement = function(widget)
            if ui_daemon:get_bars_layout() == "vertical" then
                awful.placement.bottom_left(widget, {
                    honor_workarea = true,
                    honor_padding = true,
                    attach = true,
                    margins = { bottom = dpi(450), left = dpi(550)}
                })
            else
                awful.placement.bottom_right(widget, {
                    honor_workarea = true,
                    honor_padding = true,
                    attach = true,
                    margins = { bottom = dpi(450), right = dpi(550)}
                })
            end
        end,
        shape = library.ui.rrect(),
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
