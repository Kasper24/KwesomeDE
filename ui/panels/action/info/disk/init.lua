-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local disk_daemon = require("daemons.hardware.disk")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local tonumber = tonumber
local ipairs = ipairs
local math = math

local disk = {}
local instance = nil

function disk:show()
    self.widget.screen = awful.screen.focused()
    self.widget:move_next_to(action_panel)
    self.widget.visible = true
    self:emit_signal("visibility", true)
end

function disk:hide()
    self.widget.visible = false
    self:emit_signal("visibility", false)
end

function disk:toggle()
    if self.widget.visible then
        self:hide()
    else
        self:show()
    end
end

local function separator()
    return wibox.widget {
        widget = widgets.background,
        forced_height = dpi(1),
        shape = helpers.ui.rrect(beautiful.border_radius),
        bg = beautiful.colors.surface
    }
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, disk, true)

    local header = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        {
            widget = widgets.text,
            forced_width = dpi(170),
            halign = "left",
            bold = true,
            color = beautiful.icons.disc_drive.color,
            text = "Mount"
        },
        {
            widget = widgets.text,
            halign = "left",
            bold = true,
            color = beautiful.icons.disc_drive.color,
            text = "Used"
        }
    }

    local layout = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15)
    }

    disk_daemon:connect_signal("update", function(self, disks)
        layout:reset()

        for _, entry in ipairs(disks) do
            local widget = wibox.widget {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(15),
                {
                    widget = widgets.text,
                    forced_width = dpi(150),
                    halign = "left",
                    size = 12,
                    text = entry.mount
                },
                {
                    widget = widgets.progressbar,
                    forced_width = dpi(120),
                    forced_height = dpi(30),
                    shape = helpers.ui.rrect(beautiful.border_radius),
                    bar_shape = helpers.ui.rrect(beautiful.border_radius),
                    margins = dpi(10),
                    paddings = dpi(2),
                    max_value = 100,
                    value = tonumber(entry.perc),
                    background_color = beautiful.colors.surface,
                    color = beautiful.icons.disc_drive.color
                },
                {
                    widget = widgets.text,
                    halign = "left",
                    size = 12,
                    text = math.floor(entry.used / 1024 / 1024) .. "/" .. math.floor(entry.size / 1024 / 1024) .. "GB(" ..
                        math.floor(entry.perc) .. "%)"
                }
            }

            layout:add(widget)
        end
    end)

    ret.widget = widgets.popup {
        ontop = true,
        visible = false,
        shape = helpers.ui.rrect(beautiful.border_radius),
        bg = beautiful.colors.background,
        widget = {
            widget = wibox.container.margin,
            margins = dpi(25),
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(15),
                header,
                separator(),
                layout
            }
        }
    }

    return ret
end

if not instance then
    instance = new()
end
return instance
