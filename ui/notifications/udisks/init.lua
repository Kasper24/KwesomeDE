-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local awful = require("awful")
local beautiful = require("beautiful")
local naughty = require("naughty")
local udisks_daemon = require("daemons.hardware.udisks")

local disk_icons = {"drive-removable-media-usb", "drive-removable-media-usb-pendrive",
                    "drive-removable-media-usb-panel", "gnome-dev-removable", "gnome-dev-removable-usb",
                    "gnome-dev-removable-1394", "drive-removable-media", "removable-media", "media-removable",
                    "diskmonitor", "disk-usage-analyzer", "gdiskdump", "gnome-disks"}

udisks_daemon:connect_signal("mount::added", function(self, name, mount_point)
    local browse = naughty.action {
        name = "Browse"
    }
    browse:connect_signal("invoked", function()
        awful.spawn("xdg-open " .. mount_point, false)
    end)

    naughty.notification {
        app_font_icon = beautiful.icons.usb_drive,
        app_icon = disk_icons,
        app_name = "Disks",
        font_icon = beautiful.icons.circle.plus,
        icon = disk_icons,
        title = "Mount added",
        message = name .. ": mount on " .. mount_point,
        category = "device.added",
        actions = {browse}
    }
end)

udisks_daemon:connect_signal("mount::removed", function(self, name, mount_point)
    naughty.notification {
        app_font_icon = beautiful.icons.usb_drive,
        app_icon = disk_icons,
        app_name = "Disks",
        font_icon = beautiful.icons.circle.minus,
        icon = disk_icons,
        title = "Mount removed",
        message = name .. ": unmount from " .. mount_point,
        category = "device.removed"
    }
end)
