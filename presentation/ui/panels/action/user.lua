-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local power_popup = require("presentation.ui.popups.power")
local beautiful = require("beautiful")
local upower_daemon = require("daemons.hardware.upower")
local system_daemon = require("daemons.system.system")
local package_manager_daemon = require("daemons.system.package_manager")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable
local os = os
local capi = { awesome = awesome }

local playerctl = { mt = {} }

local function new()
    local picture = wibox.widget
    {
        widget = wibox.container.background,
        shape = helpers.ui.rrect(beautiful.border_radius),
        bg = beautiful.colors.surface,
        {
            widget = wibox.widget.imagebox,
            forced_height = dpi(150),
            forced_width = dpi(150),
            valign = "center",
            clip_shape = helpers.ui.rrect(beautiful.border_radius),
            image = beautiful.profile_icon,
        }
    }

    local name = widgets.text
    {
        size = 15,
        italic = true,
        text = os.getenv("USER") ..  "@" .. capi.awesome.hostname
    }

    local power_button = widgets.button.text.normal
    {
        forced_width = dpi(50),
        forced_height = dpi(50),
        size = 15,
        font = beautiful.poweroff_icon.font,
        text = beautiful.poweroff_icon.icon,
        on_release = function()
            power_popup:show()
        end
    }

    local uptime = wibox.widget
    {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15),
        widgets.text
        {
            color = beautiful.random_accent_color(),
            font = beautiful.clock_icon.font,
            text = beautiful.clock_icon.icon,
        },
        widgets.text
        {
            size = 12,
            text = "0%",
        }
    }

    system_daemon:connect_signal("uptime", function(self, value)
        uptime.children[2]:set_text(value)
    end)

    local packages = wibox.widget
    {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15),
        widgets.text
        {
            color = beautiful.random_accent_color(),
            font = beautiful.box_icon.font,
            text = beautiful.box_icon.icon,
        },
        widgets.text
        {
            size = 12,
            text = "0 Packages",
        }
    }

    package_manager_daemon:connect_signal("update", function(self, packages_count, outdated_package_count)
        packages.children[2]:set_text(packages_count .. " Packages")
    end)

    local battery = wibox.widget
    {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15),
        widgets.battery_icon(),
        widgets.text
        {
            size = 12,
            text = "50 %",
        }
    }

    local info = wibox.widget
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        widgets.spacer.vertical(1),
        {
            layout = wibox.layout.fixed.horizontal,
            spacing = dpi(140),
            name,
            power_button
        },
        uptime,
        packages,
        widgets.spacer.vertical(1)
    }

    local startup = true
    upower_daemon:connect_signal("battery::update", function(self, device)
        if startup == true then
            info:insert(5, battery)
            startup = false
        end
        battery.children[2]:set_text(device.percentage .. " %")
    end)

    return wibox.widget
    {
        layout = wibox.layout.fixed.horizontal,
        forced_height = dpi(180),
        spacing = dpi(30),
        picture,
        info
    }
end

function playerctl.mt:__call()
    return new()
end

return setmetatable(playerctl, playerctl.mt)