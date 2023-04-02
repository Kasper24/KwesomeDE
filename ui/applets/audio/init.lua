-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local audio_daemon = require("daemons.hardware.audio")
local tasklist_daemon = require("daemons.system.tasklist")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi

local instance = nil

local function separator()
    return wibox.widget {
        widget = widgets.background,
        forced_height = dpi(1),
        shape = helpers.ui.rrect(),
        bg = beautiful.colors.surface
    }
end

local function application_widget(application)
    local font_icon = tasklist_daemon:get_font_icon(application.name)
    local accent_color = font_icon and font_icon.color or beautiful.icons.volume.high.color
    local icon = nil
    if font_icon == nil then
        icon = wibox.widget {
            widget = wibox.widget.imagebox,
            halign = "center",
            valign = "center",
            forced_height = dpi(25),
            forced_width = dpi(25),
            image = helpers.icon_theme.choose_icon{application.name, "gnome-audio", "org.pulseaudio.pavucontrol"}
        }
    else
        icon = wibox.widget {
            widget = widgets.text,
            size = font_icon.size,
            icon = font_icon
        }
    end

    local name = wibox.widget {
        widget = widgets.text,
        halign = "left",
        size = 15,
        text = application.name
    }

    local mute = wibox.widget {
        widget = widgets.button.text.state,
        forced_width = dpi(40),
        forced_height = dpi(40),
        on_by_default = application.mute,
        text_normal_bg = accent_color,
        on_normal_bg = accent_color,
        text_on_normal_bg = beautiful.colors.on_accent,
        icon = beautiful.icons.volume.off,
        size = 12,
        halign = "right",
        on_release = function()
            application:toggle_mute()
        end
    }

    local slider = widgets.slider {
        forced_height = dpi(20),
        value = application.volume,
        maximum = 100,
        bar_active_color = accent_color,
        handle_width = dpi(20),
        handle_height = dpi(20),
    }

    local widget = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        id = application.id,
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

    application:connect_signal("icon_name", function(self)
        icon.image = helpers.icon_theme.choose_icon{
            application.icon_name,
            application.name,
            "gnome-audio",
            "org.pulseaudio.pavucontrol"
        }
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
        widget = widgets.button.text.state,
        forced_width = dpi(40),
        forced_height = dpi(40),
        on_by_default = device.mute,
        on_normal_bg = beautiful.icons.volume.off.color,
        text_on_normal_bg = beautiful.colors.on_accent,
        icon = beautiful.icons.volume.off,
        size = 12,
        on_release = function()
            device:toggle_mute()
        end
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

local function applications()
    local sink_inputs_header = wibox.widget {
        widget = widgets.text,
        halign = "left",
        bold = true,
        color = beautiful.icons.volume.off.color,
        text = "Sink Inputs"
    }

    local sinks_inputs_layout = wibox.widget {
        layout = wibox.layout.overflow.vertical,
        forced_height = dpi(300),
        spacing = dpi(15),
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(10),
        step = 50
    }

    local source_outputs_header = widgets.text {
        halign = "left",
        bold = true,
        color = beautiful.icons.volume.off.color,
        text = "Source Outputs"
    }

    local source_outputs_layout = wibox.widget {
        layout = wibox.layout.overflow.vertical,
        forced_height = dpi(300),
        spacing = dpi(15),
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(10),
        step = 50
    }

    audio_daemon:connect_signal("sink_inputs::added", function(self, sink_input)
        sinks_inputs_layout:add(application_widget(sink_input))
    end)

    audio_daemon:connect_signal("source_outputs::added", function(self, source_output)
        source_outputs_layout:add(application_widget(source_output))
    end)

    audio_daemon:connect_signal("sink_inputs::removed", function(self, sink_input)
        sinks_inputs_layout:remove_widgets(sinks_inputs_layout:get_children_by_id(sink_input.id)[1])
    end)

    audio_daemon:connect_signal("source_outputs::removed", function(self, source_output)
        source_outputs_layout:remove_widgets(sinks_inputs_layout:get_children_by_id(source_output.id)[1])
    end)

    return wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(30),
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            sink_inputs_header,
            separator(),
            sinks_inputs_layout
        },
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            source_outputs_header,
            separator(),
            source_outputs_layout
        }
    }
end

local function sinks()
    local sinks_header = wibox.widget {
        widget = widgets.text,
        halign = "left",
        bold = true,
        color = beautiful.icons.volume.off.color,
        text = "Sinks"
    }

    local sinks_radio_group = wibox.widget {
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
        sinks_radio_group:add_value{
            id = sink.id,
            color = beautiful.colors.background,
            check_color = beautiful.icons.volume.high.color,
            widget = device_widget(sink)
        }
    end)

    audio_daemon:connect_signal("sinks::default", function(self, sink)
        sinks_radio_group:select(sink.id)
    end)

    audio_daemon:connect_signal("sinks::removed", function(self, id)
        sinks_radio_group:remove_value(id)
    end)

    return wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        sinks_header,
        separator(),
        sinks_radio_group
    }
end

local function sources()
    local sources_header = wibox.widget {
        widget = widgets.text,
        halign = "left",
        bold = true,
        color = beautiful.icons.volume.off.color,
        text = "Sources"
    }

    local sources_radio_group = wibox.widget {
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
        sources_radio_group:add_value{
            id = source.id,
            color = beautiful.colors.background,
            check_color = beautiful.icons.volume.high.color,
            widget = device_widget(source)
        }
    end)

    audio_daemon:connect_signal("sources::default", function(self, source)
        sources_radio_group:select(source.id)
    end)

    audio_daemon:connect_signal("sources::removed", function(self, id)
        sources_radio_group:remove_value(id)
    end)

    return wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        sources_header,
        separator(),
        sources_radio_group
    }
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
