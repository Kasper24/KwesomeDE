-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local wibox = require("wibox")
local beautiful = require("beautiful")
local ram_daemon = require("daemons.hardware.ram")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local math = math

local ram = { }
local instance = nil

function ram:show(next_to)
    self.widget.screen = awful.screen.focused()
    self.widget:move_next_to(next_to)
    self.widget.visible = true
    self:emit_signal("visibility", true)
end

function ram:hide()
    self.widget.visible = false
    self:emit_signal("visibility", false)
end

function ram:toggle(next_to)
    if self.widget.visible then
        self:hide()
    else
        self:show(next_to)
    end
end

local function getPercentage(value, total, total_swap)
    return math.floor(value / (total + total_swap) * 100 + 0.5) .. "%"
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, ram, true)

    ram_daemon:connect_signal("update", function(self, total, used, free, shared, buff_cache,
        available, total_swap, used_swap, free_swap)

        ret.widget.widget.data_list =
        {
            {"used " .. getPercentage(used + used_swap, total, total_swap), used + used_swap},
            {"free " .. getPercentage(free + free_swap, total, total_swap), free + free_swap},
            {"buff_cache " .. getPercentage(buff_cache, total, total_swap), buff_cache}
        }
    end)

    ret.widget = awful.popup
    {
        ontop = true,
        visible = false,
        offset = { y = -dpi(400) },
        shape = helpers.ui.rrect(beautiful.border_radius),
        widget =
        {
            widget = wibox.widget.piechart,
            forced_height = 200,
            forced_width = 400,
            colors =
            {
              beautiful.random_accent_color(),
              beautiful.colors.surface,
              beautiful.random_accent_color(),
            }
        }
    }

    return ret
end

if not instance then
    instance = new()
end
return instance