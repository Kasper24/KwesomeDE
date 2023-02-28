-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gtable = require("gears.table")
local gshape = require("gears.shape")
local wibox = require("wibox")
local twidget = require("ui.widgets.text")
local tbwidget = require("ui.widgets.button.text")
local bwidget = require("ui.widgets.background")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable
local os = os

local calendar = {
    mt = {}
}

local accent_color = beautiful.colors.random_accent_color()

local function day_name_widget(name)
    return wibox.widget {
        widget = twidget,
        forced_width = dpi(35),
        forced_height = dpi(35),
        halign = "center",
        size = 15,
        bold = true,
        color = beautiful.colors.on_background,
        text = name
    }
end

local function date_widget(self, index)
    local text = wibox.widget {
        widget = twidget,
        halign = "center",
        size = 15,
    }

    local widget = wibox.widget {
        widget = bwidget,
        forced_width = dpi(35),
        forced_height = dpi(35),
        shape = gshape.circle,
        text
    }

    self:connect_signal(index .. "::updated", function(self, date, is_current, is_another_month)
        text:set_text(date)

        if is_current == true then
            widget.bg = accent_color
            text:set_color(beautiful.colors.background_no_opacity)
        elseif is_another_month == true then
            widget.bg = beautiful.colors.transparent
            text:set_color(beautiful.colors.on_background_dark)
        else
            widget.bg = beautiful.colors.transparent
            text:set_color(beautiful.colors.on_background)
        end
    end)

    return widget
end

function calendar:set_date(date)
    self._private.date = date

    local first_day = os.date("*t", os.time {
        year = date.year,
        month = date.month,
        day = 1
    })
    local last_day = os.date("*t", os.time {
        year = date.year,
        month = date.month + 1,
        day = 0
    })
    local month_days = last_day.day

    local time = os.time {
        year = date.year,
        month = date.month,
        day = 1
    }
    self:get_children_by_id("current_month_button")[1]:set_text(os.date("%B", time))
    self:get_children_by_id("current_year_button")[1]:set_text(os.date("%Y", time))

    local index = 1
    local days_to_add_at_month_start = first_day.wday - 1
    local days_to_add_at_month_end = 42 - last_day.day - days_to_add_at_month_start

    local previous_month_last_day = os.date("*t", os.time {
        year = date.year,
        month = date.month,
        day = 0
    }).day
    for day = previous_month_last_day - days_to_add_at_month_start, previous_month_last_day - 1, 1 do
        self:emit_signal(index .. "::updated", day, false, true)
        index = index + 1
    end

    local current_date = os.date("*t")
    for day = 1, month_days do
        local is_current = day == current_date.day and date.month == current_date.month and date.year == current_date.year
        self:emit_signal(index .. "::updated", day, is_current, false)
        index = index + 1
    end

    for day = 1, days_to_add_at_month_end do
        self:emit_signal(index .. "::updated", day, false, true)
        index = index + 1
    end
end

function calendar:set_date_current()
    self:set_date(os.date("*t"))
end

function calendar:set_month_current()
    local date = os.date("*t")
    self:set_date({
        year = self._private.date.year,
        month = date.month,
        day = self._private.date.day
    })
end

function calendar:set_year_current()
    local date = os.date("*t")
    self:set_date({
        year = date.year,
        month = self._private.date.month,
        day = self._private.date.day
    })
end

function calendar:change_year(increment)
    local new_calendar_year = self._private.date.year + increment
    self:set_date({
        year = new_calendar_year,
        month = self._private.date.month,
        day = self._private.date.day
    })
end

function calendar:change_month(increment)
    local new_calendar_month = self._private.date.month + increment
    self:set_date({
        year = self._private.date.year,
        month = new_calendar_month,
        day = self._private.date.day
    })
end

local function new()
    local widget = nil

    widget = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        {
            layout = wibox.layout.align.horizontal,
            forced_height = dpi(40),
            {
                layout = wibox.layout.align.horizontal,
                {
                    widget = tbwidget.normal,
                    forced_width = dpi(35),
                    text_normal_bg = beautiful.colors.on_background,
                    icon = beautiful.icons.caret.left,
                    size = 15,
                    on_release = function()
                        widget:change_month(-1)
                    end
                },
                {
                    widget = tbwidget.normal,
                    forced_width = dpi(120),
                    id = "current_month_button",
                    text_normal_bg = beautiful.colors.on_background,
                    size = 15,
                    text = os.date("%B"),
                    on_release = function()
                        widget:set_month_current()
                    end
                },
                {
                    widget = tbwidget.normal,
                    forced_width = dpi(35),
                    text_normal_bg = beautiful.colors.on_background,
                    icon = beautiful.icons.caret.right,
                    size = 15,
                    on_release = function()
                        widget:change_month(1)
                    end
                },
            },
            nil,
            {
                layout = wibox.layout.align.horizontal,
                {
                    widget = tbwidget.normal,
                    forced_width = dpi(35),
                    text_normal_bg = beautiful.colors.on_background,
                    icon = beautiful.icons.caret.left,
                    size = 15,
                    on_release = function()
                        widget:change_year(-1)
                    end
                },
                {
                    widget = tbwidget.normal,
                    forced_width = dpi(120),
                    id = "current_year_button",
                    text_normal_bg = beautiful.colors.on_background,
                    size = 15,
                    text = os.date("%Y"),
                    on_release = function()
                        widget:set_year_current()
                    end
                },
                {
                    widget = tbwidget.normal,
                    forced_width = dpi(35),
                    text_normal_bg = beautiful.colors.on_background,
                    icon = beautiful.icons.caret.right,
                    size = 15,
                    on_release = function()
                        widget:change_year(1)
                    end
                },
            }
        },
        {
            layout = wibox.layout.grid,
            id = "days",
            forced_num_rows = 6,
            forced_num_cols = 7,
            spacing = dpi(15),
            expand = true,
            day_name_widget("Su"),
            day_name_widget("Mo"),
            day_name_widget("Tu"),
            day_name_widget("We"),
            day_name_widget("Th"),
            day_name_widget("Fr"),
            day_name_widget("Sa")
        }
    }

    gtable.crush(widget, calendar, true)

    for day = 1, 42 do
        widget:get_children_by_id("days")[1]:add(date_widget(widget, day))
    end
    widget:set_date_current()

    return widget
end

function calendar.mt:__call(...)
    return new(...)
end

return setmetatable(calendar, calendar.mt)
