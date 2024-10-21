-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local beautiful = require("beautiful")
local naughty = require("naughty")
local usb_daemon = require("daemons.hardware.usb")

local usb_icons = {"usb-creator-gtk", "usbimager", "multibootusb", "usb-creator-kde", "usb", "usb-creator",
                   "usb-imagewriter-ng", "usb-view", "device_usb", "fedorausb", "liveusb-creator", "indicator-usb",
                   "woeusbgui-icon", "mx-live-usb-maker", "multisystem-liveusb", "mx-usb-unmounter"}

usb_daemon:connect_signal("usb::added", function(self, device)
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

usb_daemon:connect_signal("usb::removed", function(self, device)
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
