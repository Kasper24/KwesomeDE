-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local beautiful = require("beautiful")
local cpu_daemon = require("daemons.hardware.cpu")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local ipairs = ipairs
local math = math

local cpu = { }
local instance = nil

function cpu:show(next_to)
    cpu_daemon:set_slim(false)
    self.widget.screen = awful.screen.focused()
    self.widget:move_next_to(next_to)
    self.widget.visible = true
    self:emit_signal("visibility", true)
end

function cpu:hide()
    cpu_daemon:set_slim(true)
    self.widget.visible = false
    self:emit_signal("visibility", false)
end

function cpu:toggle(next_to)
    if self.widget.visible then
        self:hide()
    else
        self:show(next_to)
    end
end

local function separator()
    return wibox.widget
    {
        widget = wibox.widget.separator,
        forced_width = dpi(1),
        forced_height = dpi(1),
        shape = helpers.ui.rrect(beautiful.border_radius),
        orientation = "horizontal",
        color = beautiful.colors.surface
    }
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, cpu, true)

    local scrollbox = wibox.widget
    {
        layout = widgets.overflow.vertical,
        forced_height = dpi(600),
        spacing = dpi(15),
        scrollbar_widget =
        {
            widget = wibox.widget.separator,
            shape = helpers.ui.rrect(beautiful.border_radius),
        },
        scrollbar_width = dpi(10),
        step = 50,
    }

    local accent_color = beautiful.random_accent_color()
    cpu_daemon:connect_signal("update::full", function(self, cpus, processes)
        scrollbox:reset()

        if #cpus > 0 then
            local header = wibox.widget
            {
                layout  = wibox.layout.fixed.horizontal,
                spacing = dpi(15),
                widgets.text
                {
                    width = dpi(70),
                    halign = "left",
                    bold = true,
                    color = beautiful.random_accent_color(),
                    text = "Core"
                },
                widgets.text
                {
                    width = dpi(200),
                    halign = "left",
                    bold = true,
                    color = beautiful.random_accent_color(),
                    text = "Usage"
                },
            }

            scrollbox:add(header)
            scrollbox:add(separator())
        end

        for index, cpu in ipairs(cpus) do
            local widget = wibox.widget
            {
                layout  = wibox.layout.fixed.horizontal,
                spacing = dpi(15),
                widgets.text
                {
                    width = dpi(70),
                    halign = "left",
                    text = cpu.name,
                },
                widgets.text
                {
                    width = dpi(60),
                    halign = "left",
                    text = math.floor(cpu.diff_usage) .. "%",
                },
                {
                    widget = wibox.widget.progressbar,
                    forced_height = dpi(20),
                    forced_width = dpi(370),
                    shape = helpers.ui.rrect(beautiful.border_radius),
                    bar_shape = helpers.ui.rrect(beautiful.border_radius),
                    margins = dpi(10),
                    paddings = dpi(2),
                    max_value = 100,
                    value = cpu.diff_usage,
                    background_color = beautiful.colors.surface,
                    color =
                    {
                        type = "linear",
                        from = {0, 0},
                        to = {300, 300},
                        stops = {{0, beautiful.random_accent_color()}, {0.33, beautiful.random_accent_color()},  {0.66, beautiful.random_accent_color()}}
                    },
                },
            }

            scrollbox:add(widget)
        end

        if #processes > 0 then
            local header = wibox.widget
            {
                layout  = wibox.layout.fixed.horizontal,
                widgets.text
                {
                    width = dpi(110),
                    halign = "left",
                    bold = true,
                    color = beautiful.random_accent_color(),
                    text = "PID"
                },
                widgets.text
                {
                    width = dpi(210),
                    halign = "left",
                    bold = true,
                    color = beautiful.random_accent_color(),
                    text = "Name"
                },
                widgets.text
                {
                    width = dpi(90),
                    halign = "left",
                    bold = true,
                    color = beautiful.random_accent_color(),
                    text = "%CPU"
                },
                widgets.text
                {
                    width = dpi(70),
                    halign = "left",
                    bold = true,
                    color = beautiful.random_accent_color(),
                    text = "%MEM"
                },
            }

            scrollbox:add(separator())
            scrollbox:add(header)
            scrollbox:add(separator())
        end

        for index, process in ipairs(processes) do
            local widget = wibox.widget
            {
                layout  = wibox.layout.fixed.horizontal,
                widgets.text
                {
                    width = dpi(110),
                    halign = "left",
                    text = process.pid,
                },
                widgets.text
                {
                    width = dpi(210),
                    halign = "left",
                    text = process.comm,
                },
                widgets.text
                {
                    width = dpi(80),
                    halign = "left",
                    text = process.cpu,
                },
                widgets.text
                {
                    width = dpi(80),
                    halign = "left",
                    text = process.mem,
                },
                widgets.button.text.normal
                {
                    font = beautiful.xmark_icon.font,
                    size = 15,
                    text = beautiful.xmark_icon.icon,
                    text_normal_bg = accent_color,
                    on_release = function()
                        awful.spawn("kill -9 " .. process.pid, false)
                    end
                }
            }

            scrollbox:add(widget)
        end
    end)

    ret.widget = awful.popup
    {
        bg = beautiful.colors.background,
        ontop = true,
        visible = false,
        shape = helpers.ui.rrect(beautiful.border_radius),
        minimum_width = dpi(600),
        maximum_width = dpi(600),
        widget =
        {
            widget = wibox.container.margin,
            margins = dpi(25),
            scrollbox
        }
    }

    return ret
end

if not instance then
    instance = new()
end
return instance