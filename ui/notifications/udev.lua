-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local beautiful = require("beautiful")
local naughty = require("naughty")
local udev_daemon = require("daemons.hardware.udev")

local usb_icons = {"usb-creator-gtk", "usbimager", "multibootusb", "usb-creator-kde", "usb", "usb-creator",
                   "usb-imagewriter-ng", "usb-view", "device_usb", "fedorausb", "liveusb-creator", "indicator-usb",
                   "woeusbgui-icon", "mx-live-usb-maker", "multisystem-liveusb", "mx-usb-unmounter"}

local disk_icons = {"drive-removable-media-usb", "drive-removable-media-usb-pendrive",
                    "drive-removable-media-usb-panel", "gnome-dev-removable", "gnome-dev-removable-usb",
                    "gnome-dev-removable-1394", "drive-removable-media", "removable-media", "media-removable",
                    "diskmonitor", "disk-usage-analyzer", "gdiskdump", "gnome-disks"}

udev_daemon:connect_signal("usb::added", function(self, device)
    naughty.notification {
        app_font_icon = beautiful.icons.usb,
        app_icon = usb_icons,
        app_name = "USB",
        font_icon = beautiful.icons.circle.plus,
        icon = usb_icons,
        title = device.vendor .. " " .. device.name,
        message = "Connected",
        category = "device.added"
    }
end)

udev_daemon:connect_signal("usb::removed", function(self, device)
    naughty.notification {
        app_font_icon = beautiful.icons.usb,
        app_icon = usb_icons,
        app_name = "USB",
        font_icon = beautiful.icons.circle.minus,
        icon = usb_icons,
        title = device.vendor .. " " .. device.name,
        message = "Disconnected",
        category = "device.removed"
    }
end)

udev_daemon:connect_signal("block::added", function(self, device)
    local browse = naughty.action {
        name = "Browse"
    }
    browse:connect_signal("invoked", function()
        awful.spawn("xdg-open " .. device.mount_point, false)
    end)

    naughty.notification {
        app_font_icon = beautiful.icons.usb_drive,
        app_icon = disk_icons,
        app_name = "Storage",
        font_icon = beautiful.icons.circle.plus,
        icon = disk_icons,
        title = device.name,
        message = device.partition .. ": mounted on " .. device.mount_point,
        category = "device.added",
        actions = {browse}
    }
end)

udev_daemon:connect_signal("block::removed", function(self, device)
    naughty.notification {
        app_font_icon = beautiful.icons.usb_drive,
        app_icon = disk_icons,
        app_name = "Storage",
        font_icon = beautiful.icons.circle.minus,
        icon = disk_icons,
        title = device.name,
        message = device.partition .. ": removed from " .. device.mount_point,
        category = "device.removed"
    }
end)
