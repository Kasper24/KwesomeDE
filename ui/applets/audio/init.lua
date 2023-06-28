-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local audio_daemon = require("daemons.hardware.audio")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi

local instance = nil

local function application_widget(application)
    local icon_image = beautiful.get_svg_icon{
        application.icon_name or application.name,
        "multimedia-audio-player"
    }

    local icon = wibox.widget {
        widget = widgets.icon,
        size = 25,
        halign = "center",
        valign = "center",
        icon = icon_image
    }

    local name = wibox.widget {
        widget = widgets.text,
        halign = "left",
        size = 15,
        text = application.name
    }

    local mute = wibox.widget {
        widget = widgets.button.state,
        forced_width = dpi(40),
        forced_height = dpi(40),
        on_by_default = application.mute,
        on_color = icon_image.color,
        halign = "right",
        on_release = function()
            application:toggle_mute()
        end,
        {
            widget = widgets.text,
            color = icon_image.color,
            on_color = beautiful.colors.on_accent,
            size = 12,
            icon = beautiful.icons.volume.off,
        }
    }

    local slider = widgets.slider {
        forced_height = dpi(20),
        value = application.volume,
        maximum = 100,
        bar_active_color = icon_image.color,
        handle_width = dpi(20),
        handle_height = dpi(20),
    }

    local widget = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        forced_height = dpi(80),
        spacing = dpi(15),
        {
            layout = wibox.layout.align.horizontal,
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(15),
                icon,
                name
            },
            nil,
            mute
        },
        {
            widget = wibox.container.margin,
            margins = { right = dpi(15) },
            slider
        }
    }

    application:connect_signal("updated", function(self)
        slider:set_value(application.volume)

        if application.mute == true then
            mute:turn_on()
        else
            mute:turn_off()
        end
    end)

    application:connect_signal("icon_name", function()
        icon:set_icon(beautiful.get_svg_icon{
            application.icon_name or application.name,
            "multimedia-audio-player"
        })
    end)

    slider:connect_signal("property::value", function(self, value, instant)
        application:set_volume(value)
    end)

    return widget
end

local function device_widget(device)
    local name = wibox.widget {
        widget = widgets.text,
        forced_width = dpi(400),
        halign = "left",
        size = 12,
        text = device.description
    }

    local mute = wibox.widget {
        widget = widgets.button.state,
        forced_width = dpi(40),
        forced_height = dpi(40),
        on_by_default = device.mute,
        on_color = beautiful.icons.volume.off.color,
        on_release = function()
            device:toggle_mute()
        end,
        {
            widget = widgets.text,
            on_color = beautiful.colors.on_accent,
            size = 12,
            icon = beautiful.icons.volume.off,
        }
    }

    local slider = widgets.slider {
        forced_height = dpi(20),
        value = device.volume,
        maximum = 100,
        handle_width = dpi(20),
        handle_height = dpi(20),
        bar_active_color = beautiful.icons.volume.off.color,
    }

    local widget = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        forced_height = dpi(80),
        spacing = dpi(15),
        {
            layout = wibox.layout.align.horizontal,
            name,
            nil,
            mute
        },
        {
            widget = wibox.container.margin,
            margins = { right = dpi(15) },
            slider
        }
    }

    slider:connect_signal("property::value", function(self, value, instant)
        device:set_volume(value)
    end)

    device:connect_signal("updated", function()
        slider:set_value(device.volume)

        if device.mute == true then
            mute:turn_on()
        else
            mute:turn_off()
        end
    end)

    return widget
end

local function sink_inputs()
    local layout = wibox.widget {
        layout = wibox.layout.overflow.vertical,
        spacing = dpi(15),
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(10),
        step = 50
    }

    audio_daemon:connect_signal("sink_inputs::added", function(self, sink_input)
        sink_input.widget = application_widget(sink_input)
        layout:add(sink_input.widget)
    end)

    audio_daemon:connect_signal("sink_inputs::removed", function(self, sink_input)
        layout:remove_widgets(sink_input.widget)
        sink_input.widget = nil
    end)

    return layout
end

local function source_outputs()
    local layout = wibox.widget {
        layout = wibox.layout.overflow.vertical,
        spacing = dpi(15),
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(10),
        step = 50
    }

    audio_daemon:connect_signal("source_outputs::added", function(self, source_output)
        source_output.widget = application_widget(source_output)
        layout:add(source_output.widget)
    end)

    audio_daemon:connect_signal("source_outputs::removed", function(self, source_output)
        layout:remove_widgets(source_output.widget)
        source_output.widget = nil
    end)

    return layout
end

local function applications()
    return wibox.widget {
        widget = widgets.navigator.horizontal,
        buttons_selected_color = beautiful.icons.volume.high.color,
        tabs = {
            {
                {
                    id = "sink_inputs",
                    title = "Sinks Inputs",
                    halign = "center",
                    tab = sink_inputs()
                },
                {
                    id = "source_outputs",
                    title = "Source Outputs",
                    halign = "center",
                    tab = source_outputs()
                },
            }
        }
    }
end

local function sinks()
    local radio_group = wibox.widget {
        widget = widgets.radio_group.vertical,
        on_select = function(id)
            audio_daemon:set_default_sink(id)
        end,
        widget_template = wibox.widget {
            layout = wibox.layout.overflow.vertical,
            id = "buttons_layout",
            spacing = dpi(15),
            scrollbar_widget = widgets.scrollbar,
            scrollbar_width = dpi(10),
            step = 50,
        }
    }

    audio_daemon:connect_signal("sinks::added", function(self, sink)
        radio_group:add_value{
            id = sink.id,
            color = beautiful.colors.background,
            check_color = beautiful.icons.volume.high.color,
            widget = device_widget(sink)
        }
    end)

    audio_daemon:connect_signal("sinks::default", function(self, sink)
        radio_group:select(sink.id)
    end)

    audio_daemon:connect_signal("sinks::removed", function(self, sink)
        radio_group:remove_value(sink.id)
    end)

    return radio_group
end

local function sources()
    local radio_group = wibox.widget {
        widget = widgets.radio_group.vertical,
        on_select = function(id)
            audio_daemon:set_default_source(id)
        end,
        widget_template = wibox.widget {
            layout = wibox.layout.overflow.vertical,
            id = "buttons_layout",
            spacing = dpi(15),
            scrollbar_widget = widgets.scrollbar,
            scrollbar_width = dpi(10),
            step = 50,
        }
    }

    audio_daemon:connect_signal("sources::added", function(self, source)
        radio_group:add_value{
            id = source.id,
            color = beautiful.colors.background,
            check_color = beautiful.icons.volume.high.color,
            widget = device_widget(source)
        }
    end)

    audio_daemon:connect_signal("sources::default", function(self, source)
        radio_group:select(source.id)
    end)

    audio_daemon:connect_signal("sources::removed", function(self, source)
        radio_group:remove_value(source.id)
    end)

    return radio_group
end

local function devices()
    return wibox.widget {
        widget = widgets.navigator.horizontal,
        buttons_selected_color = beautiful.icons.volume.high.color,
        tabs = {
            {
                {
                    id = "sinks",
                    title = "Sinks",
                    halign = "center",
                    tab = sinks()
                },
                {
                    id = "sources",
                    title = "Sources",
                    halign = "center",
                    tab = sources()
                },
            }
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
                    id = "devices",
                    title = "Devices",
                    halign = "center",
                    tab = devices()
                },
                {
                    id = "applications",
                    title = "Applications",
                    halign = "center",
                    tab = applications()
                },
            }
        }
    }

    return widgets.animated_panel {
        ontop = true,
        visible = false,
        minimum_width = dpi(600),
        maximum_width = dpi(600),
        minimum_height = dpi(800),
        maximum_height = dpi(800),
        placement = function(widget)
            awful.placement.bottom_right(widget, {
                honor_workarea = true,
                honor_padding = true,
                attach = true,
                margins = { right = dpi(550)}
            })
        end,
        shape = helpers.ui.rrect(),
        bg = beautiful.colors.background,
        widget = wibox.widget {
            widget = wibox.container.margin,
            margins = dpi(25),
            navigator
        }
    }
end

if not instance then
    instance = new()
end
return instance
