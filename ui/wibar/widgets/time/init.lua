-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local info_panel = require("ui.panels.info")
local beautiful = require("beautiful")
local ui_daemon = require("daemons.system.ui")
local dpi = beautiful.xresources.apply_dpi
local capi = {
    awesome = awesome
}

local time = {
    mt = {}
}

local function vertical()
    return wibox.widget {
        layout = wibox.layout.fixed.vertical,
        {
            widget = wibox.widget.textclock,
            format = "%H",
            bold = true,
            size = 15,
            color = beautiful.colors.on_background,
        },
        {
            widget = wibox.widget.textclock,
            format = "%M",
            size = 14,
            color = beautiful.colors.on_background,
        },
    }
end

local function horizontal()
    return wibox.widget {
        widget = wibox.widget.textclock,
        format = "%d %b %H:%M",
        size = 14,
        color = beautiful.colors.on_background,
    }
end

local function new()
    local clock = ui_daemon:get_bars_layout() == "vertical" and vertical() or horizontal()

    local widget = wibox.widget {
        widget = wibox.container.margin,
        margins = dpi(5),
        {
            widget = widgets.button.state,
            on_color = beautiful.colors.surface,
            id = "button",
            on_release = function()
                info_panel:toggle()
            end,
            clock
        }
    }

    info_panel:connect_signal("visibility", function(self, visibility)
        if visibility == true then
            widget:get_children_by_id("button")[1]:turn_on()
        else
            widget:get_children_by_id("button")[1]:turn_off()
        end
    end)

    return widget
end

function time.mt:__call()
    return new()
end

return setmetatable(time, time.mt)
