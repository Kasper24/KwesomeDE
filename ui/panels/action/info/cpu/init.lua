-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local cpu_daemon = require("daemons.hardware.cpu")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local ipairs = ipairs
local math = math

local instance = nil

local function separator()
    return wibox.widget {
        widget = widgets.background,
        forced_height = dpi(1),
        shape = helpers.ui.rrect(),
        bg = beautiful.colors.surface
    }
end

local function core_widget(core)
    local name = wibox.widget {
        widget = widgets.text,
        forced_width = dpi(70),
        halign = "left",
        text = core.name
    }

    local usage = wibox.widget {
        widget = widgets.text,
        forced_width = dpi(60),
        halign = "left",
        text = math.floor(core.diff_usage) .. "%"
    }

    local usage_progressbar = wibox.widget {
        widget = widgets.progressbar,
        forced_height = dpi(20),
        forced_width = dpi(370),
        shape = helpers.ui.rrect(),
        bar_shape = helpers.ui.rrect(),
        margins = dpi(10),
        paddings = dpi(2),
        max_value = 100,
        value = core.diff_usage,
        background_color = beautiful.colors.surface,
        color = beautiful.icons.microchip.color
    }

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15),
        name,
        usage,
        usage_progressbar
    }
end

local function process_widget(process)
    local pid = wibox.widget {
        widget = widgets.text,
        forced_width = dpi(110),
        halign = "left",
        text = process.pid
    }

    local name = wibox.widget {
        widget = widgets.text,
        forced_width = dpi(210),
        halign = "left",
        text = process.comm
    }

    local cpu_usage = wibox.widget {
        widget = widgets.text,
        forced_width = dpi(80),
        halign = "left",
        text = process.cpu
    }

    local ram_usage = wibox.widget {
        widget = widgets.text,
        forced_width = dpi(80),
        halign = "left",
        text = process.mem
    }

    local dismiss = wibox.widget {
        widget = widgets.button.text.normal,
        icon = beautiful.icons.xmark,
        size = 15,
        on_release = function()
            awful.spawn("kill -9 " .. process.pid, false)
        end
    }

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        pid,
        name,
        cpu_usage,
        ram_usage,
        dismiss
    }
end

local function widget()
    local cores_header = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15),
        {
            widget = widgets.text,
            forced_width = dpi(70),
            halign = "left",
            bold = true,
            color = beautiful.icons.microchip.color,
            text = "Core"
        },
        {
            widget = widgets.text,
            forced_width = dpi(200),
            halign = "left",
            bold = true,
            color = beautiful.icons.microchip.color,
            text = "Usage"
        }
    }

    local cores_layout = wibox.widget {
        layout = widgets.overflow.vertical,
        forced_height = dpi(300),
        spacing = dpi(15),
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(10),
        step = 50
    }

    local processes_header = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        {
            widget = widgets.text,
            forced_width = dpi(110),
            halign = "left",
            bold = true,
            color = beautiful.icons.microchip.color,
            text = "PID"
        },
        {
            widget = widgets.text,
            forced_width = dpi(210),
            halign = "left",
            bold = true,
            color = beautiful.icons.microchip.color,
            text = "Name"
        },
        {
            widget = widgets.text,
            forced_width = dpi(90),
            halign = "left",
            bold = true,
            color = beautiful.icons.microchip.color,
            text = "%CPU"
        },
        {
            widget = widgets.text,
            forced_width = dpi(70),
            halign = "left",
            bold = true,
            color = beautiful.icons.microchip.color,
            text = "%MEM"
        }
    }

    local processes_layout = wibox.widget {
        layout = widgets.overflow.vertical,
        forced_height = dpi(300),
        spacing = dpi(15),
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(10),
        step = 50
    }

    cpu_daemon:connect_signal("update::full", function(self, cores, processes)
        cores_layout:reset()
        processes_layout:reset()

        for _, core in ipairs(cores) do
            cores_layout:add(core_widget(core))
        end

        for _, process in ipairs(processes) do
            processes_layout:add(process_widget(process))
        end
    end)

    return wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(30),
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            cores_header,
            separator(),
            cores_layout
        },
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            processes_header,
            separator(),
            processes_layout
        }
    }
end

local function new()
    local widget = widgets.animated_panel {
        ontop = true,
        visible = false,
        shape = helpers.ui.rrect(),
        minimum_width = dpi(600),
        maximum_width = dpi(600),
        placement = function(widget)
            awful.placement.bottom_right(widget, {
                honor_workarea = true,
                honor_padding = true,
                attach = true,
                margins = { right = dpi(550)}
            })
        end,
        bg = beautiful.colors.background,
        widget = wibox.widget {
            widget = wibox.container.margin,
            margins = dpi(25),
            widget()
        }
    }

    widget:connect_signal("visibility", function(visibile)
        if visibile then
            cpu_daemon:set_slim(false)
        else
            cpu_daemon:set_slim(true)
        end
    end)

    return widget
end

if not instance then
    instance = new()
end
return instance
