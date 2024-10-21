-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local cpu_daemon = require("daemons.hardware.cpu")
local ui_daemon = require("daemons.system.ui")
local library = require("library")
local dpi = beautiful.xresources.apply_dpi
local math = math

local instance = nil

local function separator()
    return wibox.widget {
        widget = widgets.background,
        forced_height = dpi(1),
        shape = library.ui.rrect(),
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
        shape = library.ui.rrect(),
        bar_shape = library.ui.rrect(),
        margins = dpi(10),
        paddings = dpi(2),
        max_value = 100,
        value = core.diff_usage,
        background_color = beautiful.colors.surface,
        color = beautiful.icons.microchip.color
    }

    core:connect_signal("update", function(self, core)
        usage:set_text(math.floor(core.diff_usage) .. "%")
        usage_progressbar.value = core.diff_usage
    end)

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
        widget = widgets.button.normal,
        forced_width = dpi(50),
        forced_height = dpi(50),
        on_release = function()
            awful.spawn("kill -9 " .. process.pid, false)
            process:emit_signal("removed")
        end,
        {
            widget = widgets.text,
            size = 15,
            icon = beautiful.icons.xmark,
        }
    }

    process:dynamic_connect_signal("update", function(self, process)
        name:set_text(process.comm)
        cpu_usage:set_text(process.cpu)
        ram_usage:set_text(process.mem)
    end)

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        pid,
        name,
        cpu_usage,
        ram_usage,
        dismiss
    }
end

local function cores()
    local header = wibox.widget {
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

    local layout = wibox.widget {
        layout = wibox.layout.overflow.vertical,
        spacing = dpi(15),
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(10),
        step = 50
    }

    cpu_daemon:connect_signal("core", function(self, core)
        layout:add(core_widget(core))
    end)

    return wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(30),
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            header,
            separator(),
            layout
        }
    }
end

local function processes()
    local header = wibox.widget {
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

    local layout = wibox.widget {
        layout = wibox.layout.overflow.vertical,
        spacing = dpi(15),
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(10),
        step = 50
    }

    cpu_daemon:connect_signal("process", function(self, process)
        local widget = process_widget(process)
        layout:add(widget)

        process:connect_signal("removed", function()
            layout:remove_widgets(widget)
            process:dynamic_disconnect_signals("update")
        end)
    end)

    return wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(30),
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            header,
            separator(),
            layout
        }
    }
end

local function new()
    local navigator = wibox.widget {
        widget = widgets.navigator.horizontal,
        buttons_selected_color = beautiful.icons.volume.high.color,
        tabs = {
            {
                {
                    id = "cores",
                    title = "Cores",
                    halign = "center",
                    tab = cores()
                },
                {
                    id = "processes",
                    title = "Processes",
                    halign = "center",
                    tab = processes()
                },
            }
        }
    }

    local widget = widgets.animated_popup {
        ontop = true,
        visible = false,
        shape = library.ui.rrect(),
        maximum_width = dpi(600),
        minimum_height = dpi(800),
        maximum_height = dpi(800),
        animate_method = "width",
        hide_on_clicked_outside = true,
        placement = function(widget)
            if ui_daemon:get_bars_layout() == "vertical" then
                awful.placement.bottom_left(widget, {
                    honor_workarea = true,
                    honor_padding = true,
                    attach = true,
                    margins = { left = dpi(550)}
                })
            else
                awful.placement.bottom_right(widget, {
                    honor_workarea = true,
                    honor_padding = true,
                    attach = true,
                    margins = { right = dpi(550)}
                })
            end
        end,
        bg = beautiful.colors.background,
        widget = wibox.widget {
            widget = wibox.container.margin,
            margins = dpi(25),
            navigator
        }
    }

    widget:connect_signal("visibility", function(visible)
        if visible then
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
