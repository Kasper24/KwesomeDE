-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local calendar = { mt = {} }

local function new()
    local hour = wibox.widget
    {
        widget = wibox.widget.textclock,
        format = "%H",
        font = beautiful.font_name .. 50,
    }

    local seperator = wibox.widget
    {
        widget = wibox.container.place,
        valign = "center",
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            {
                widget = wibox.container.background,
                forced_width = dpi(10),
                forced_height = dpi(10),
                shape = helpers.ui.rrect(2),
                bg = beautiful.random_accent_color(),
            },
            {
                widget = wibox.container.background,
                forced_width = dpi(10),
                forced_height = dpi(10),
                shape = helpers.ui.rrect(2),
                bg = beautiful.random_accent_color(),
            },
            {
                widget = wibox.container.background,
                forced_width = dpi(10),
                forced_height = dpi(10),
                shape = helpers.ui.rrect(2),
                bg = beautiful.random_accent_color(),
            }
        }
    }

    local minute = wibox.widget
    {
        widget = wibox.widget.textclock,
        format = "%M",
        font = beautiful.font_name .. 50,
    }

    local time = wibox.widget
    {
        widget = wibox.container.place,
        halign = "center",
        {
            layout = wibox.layout.fixed.horizontal,
            spacing = dpi(15),
            hour,
            seperator,
            minute
        }
    }

    local date = wibox.widget
    {
        widget = wibox.widget.textclock,
        format = "%A, %b, %d",
        align = "center",
        valign = "center",
        font = beautiful.font_name .. 20,
    }

    date.markup = helpers.ui.colorize_text(date.text, beautiful.random_accent_color())
    date:connect_signal("widget::redraw_needed", function()
        date.markup = helpers.ui.colorize_text(date.text, beautiful.random_accent_color())
    end)

    return wibox.widget
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(25),
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(5),
            time,
            date,
        },
        widgets.calendar()
    }
end

function calendar.mt:__call()
    return new()
end

return setmetatable(calendar, calendar.mt)