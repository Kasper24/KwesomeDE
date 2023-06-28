-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local power_popup = require("ui.screens.power")
local beautiful = require("beautiful")
local upower_daemon = require("daemons.hardware.upower")
local system_daemon = require("daemons.system.system")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable
local os = os
local capi = {
    awesome = awesome
}

local playerctl = {
    mt = {}
}

local function new()
    local picture = wibox.widget {
        widget = widgets.profile,
        forced_height = dpi(150),
        forced_width = dpi(150),
    }

    local name = wibox.widget {
        widget = widgets.text,
        size = 15,
        italic = true,
        text = os.getenv("USER") .. "@" .. capi.awesome.hostname
    }

    local power_button = wibox.widget {
        widget = widgets.button.normal,
        forced_width = dpi(50),
        forced_height = dpi(50),
        on_release = function()
            power_popup:show()
        end,
        {
            widget = widgets.text,
            size = 15,
            icon = beautiful.icons.poweroff
        }
    }

    local uptime_widget = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15),
        {
            widget = widgets.text,
            icon = beautiful.icons.clock
        },
        {
            widget = widgets.text,
            id = "text",
            size = 12,
            text = "0"
        }
    }

    system_daemon:connect_signal("info", function(self, packages_count, uptime)
        uptime_widget:get_children_by_id("text")[1]:set_text(uptime)
    end)

    local packages = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15),
        {
            widget = widgets.text,
            icon = beautiful.icons.box
        },
        {
            widget = widgets.text,
            id = "text",
            size = 12,
            text = "0 Packages"
        }
    }

    system_daemon:connect_signal("info", function(self, packages_count, uptime)
        packages:get_children_by_id("text")[1]:set_text(packages_count .. " Packages")
    end)

    local battery = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(5),
        {
            widget = widgets.text,
            id = "info",
            size = 12,
            text = ""
        }
    }

    local info = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        {
            layout = wibox.layout.fixed.horizontal,
            spacing = dpi(180),
            name,
            power_button
        },
        uptime_widget,
        packages,
    }

    upower_daemon:connect_signal("battery::init", function(self, device)
        battery:insert(1, widgets.battery_icon(device, {
            forced_width = dpi(40),
            forced_height = dpi(10)
        }))
        info:insert(4, battery)
        battery:get_children_by_id("info")[1]:set_text(device.Percentage .. " % | " .. device:get_time_string())
    end)

    upower_daemon:connect_signal("battery::update", function(self, device)
        battery:get_children_by_id("info")[1]:set_text(device.Percentage .. " % | " .. device:get_time_string())
    end)

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_height = dpi(200),
        spacing = dpi(30),
        picture,
        info
    }
end

function playerctl.mt:__call()
    return new()
end

return setmetatable(playerctl, playerctl.mt)
