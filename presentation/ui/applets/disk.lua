-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local beautiful = require("beautiful")
local disk_daemon = require("daemons.hardware.disk")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local tonumber = tonumber
local ipairs = ipairs
local math = math

local disk = { }
local instance = nil

function disk:show(next_to)
    self.widget.screen = awful.screen.focused()
    self.widget:move_next_to(next_to)
    self.widget.visible = true
    self:emit_signal("visibility", true)
end

function disk:hide()
    self.widget.visible = false
    self:emit_signal("visibility", false)
end

function disk:toggle(next_to)
    if self.widget.visible then
        self:hide()
    else
        self:show(next_to)
    end
end

local function separator()
    return wibox.widget
    {
        widget = wibox.widget.separator,
        forced_width = dpi(1),
        forced_height = dpi(1),
        shape = helpers.ui.rrect(beautiful.border_radius),
        orientation = "horizontal",
        color = beautiful.colors.surface
    }
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, disk, true)

    local header = wibox.widget
    {
        layout = wibox.layout.fixed.horizontal,
        widgets.text
        {
            width = dpi(170),
            halign = "left",
            bold = true,
            color = beautiful.random_accent_color(),
            text = "Mount"
        },
        widgets.text
        {
            halign = "left",
            bold = true,
            color = beautiful.random_accent_color(),
            text = "Used"
        }
    }

    local layout = wibox.widget
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15)
    }

    disk_daemon:connect_signal("update", function(self, disks)
        layout:reset()

        for _, entry in ipairs(disks) do
            local widget = wibox.widget
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(15),
                widgets.text
                {
                    width = dpi(150),
                    halign = "left",
                    size = 12,
                    text = entry.mount,
                },
                {
                    widget = wibox.widget.progressbar,
                    forced_width = dpi(120),
                    forced_height = dpi(30),
                    shape = helpers.ui.rrect(beautiful.border_radius),
                    bar_shape = helpers.ui.rrect(beautiful.border_radius),
                    margins = dpi(10),
                    paddings = dpi(2),
                    max_value = 100,
                    value = tonumber(entry.perc),
                    background_color = beautiful.colors.surface,
                    color =
                    {
                        type = "linear",
                        from = {0, 0},
                        to = {300, 300},
                        stops = {{0, beautiful.random_accent_color()}, {0.33, beautiful.random_accent_color()},  {0.66, beautiful.random_accent_color()}}
                    },
                },
                widgets.text
                {
                    halign = "left",
                    size = 12,
                    text = math.floor(entry.used / 1024 / 1024)
                        .. "/"
                        .. math.floor(entry.size / 1024 / 1024) .. "GB("
                        .. math.floor(entry.perc) .. "%)"
                },
            }

            layout:add(widget)
        end
    end)

    ret.widget = awful.popup
    {
        bg = beautiful.colors.background,
        ontop = true,
        visible = false,
        shape = helpers.ui.rrect(beautiful.border_radius),
        widget =
        {
            widget = wibox.container.margin,
            margins = dpi(25),
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(15),
                header,
                separator(),
                layout
            },
        }
    }

    return ret
end

if not instance then
    instance = new()
end
return instance