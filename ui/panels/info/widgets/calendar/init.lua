-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local gshape = require("gears.shape")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local library = require("library")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable
local capi = {
    awesome = awesome
}

local calendar = {
    mt = {}
}

local function new()
    local hour = wibox.widget {
        widget = wibox.widget.textclock,
        format = "%H",
        size = 50,
        color = beautiful.colors.on_background
    }

    local dots = wibox.widget {
        widget = wibox.container.place,
        valign = "center",
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            {
                widget = widgets.background,
                forced_width = dpi(10),
                forced_height = dpi(10),
                shape = gshape.squircle,
                bg = beautiful.colors.random_accent_color()
            },
            {
                widget = widgets.background,
                forced_width = dpi(10),
                forced_height = dpi(10),
                shape = gshape.squircle,
                bg = beautiful.colors.random_accent_color()
            },
            {
                widget = widgets.background,
                forced_width = dpi(10),
                forced_height = dpi(10),
                shape = gshape.squircle,
                bg = beautiful.colors.random_accent_color()
            }
        }
    }

    local minute = wibox.widget {
        widget = wibox.widget.textclock,
        format = "%M",
        size = 50,
        color = beautiful.colors.on_background
    }

    local time = wibox.widget {
        widget = wibox.container.place,
        halign = "center",
        {
            layout = wibox.layout.fixed.horizontal,
            spacing = dpi(15),
            hour,
            dots,
            minute
        }
    }

    local date = wibox.widget {
        widget = wibox.widget.textclock,
        format = "%A, %b, %d",
        halign = "center",
        size = 20,
        color = beautiful.colors.on_background
    }

    return wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(25),
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(5),
            time,
            date
        },
        widgets.calendar()
    }
end

function calendar.mt:__call()
    return new()
end

return setmetatable(calendar, calendar.mt)
