-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local disk_daemon = require("daemons.hardware.disk")
local ui_daemon = require("daemons.system.ui")
local library = require("library")
local dpi = beautiful.xresources.apply_dpi
local tonumber = tonumber
local ipairs = ipairs
local math = math

local instance = nil

local function separator()
    return wibox.widget {
        widget = widgets.background,
        forced_height = dpi(1),
        shape = library.ui.rrect(),
        bg = beautiful.colors.surface
    }
end

local function partition_widget(partition)
    local name = wibox.widget {
        widget = widgets.text,
        forced_width = dpi(150),
        halign = "left",
        size = 12,
        text = partition.mount
    }

    local usage_progressbar = wibox.widget {
        widget = widgets.progressbar,
        forced_width = dpi(120),
        forced_height = dpi(30),
        shape = library.ui.rrect(),
        bar_shape = library.ui.rrect(),
        margins = dpi(10),
        paddings = dpi(2),
        max_value = 100,
        value = tonumber(partition.perc),
        background_color = beautiful.colors.surface,
        color = beautiful.icons.disc_drive.color
    }

    local usage = wibox.widget {
        widget = widgets.text,
        halign = "left",
        size = 12,
        text = math.floor(partition.used / 1024 / 1024) .. "/" .. math.floor(partition.size / 1024 / 1024) .. "GB(" ..
            math.floor(partition.perc) .. "%)"
    }

    partition:connect_signal("update", function(self, partition)
        name:set_text(partition.mount)
        usage_progressbar.value = tonumber(partition.perc)
        usage:set_text(math.floor(partition.used / 1024 / 1024) .. "/" .. math.floor(partition.size / 1024 / 1024) .. "GB(" ..
            math.floor(partition.perc) .. "%)")
    end)

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15),
        name,
        usage_progressbar,
        usage
    }
end

local function new()
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

    disk_daemon:connect_signal("partition", function(self, partition)
        layout:add(partition_widget(partition))
    end)


    return widgets.animated_popup {
        ontop = true,
        visible = false,
        maximum_width = dpi(500),
        minimum_height = dpi(800),
        maximum_height = dpi(800),
        animate_method = "width",
        hide_on_clicked_outside = true,
        placement = function(widget)
            if ui_daemon:get_bars_layout() == "vertical" then
                awful.placement.bottom_left(widget, {
                    honor_workarea = true,
                    honor_padding = true,
                    attach = true,
                    margins = { left = dpi(550)}
                })
            else
                awful.placement.bottom_right(widget, {
                    honor_workarea = true,
                    honor_padding = true,
                    attach = true,
                    margins = { right = dpi(550)}
                })
            end
        end,
        shape = library.ui.rrect(),
        bg = beautiful.colors.background,
        widget = wibox.widget {
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
end

if not instance then
    instance = new()
end
return instance
