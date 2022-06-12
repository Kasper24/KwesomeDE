-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gshape = require("gears.shape")
local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local beautiful = require("beautiful")
local pactl_daemon = require("daemons.hardware.pactl")
local helpers = require("helpers")
local icon_theme = require("services.icon_theme")
local dpi = beautiful.xresources.apply_dpi

local audio = { }
local instance = nil

function audio:show(next_to)
    self.widget.screen = awful.screen.focused()
    self.widget:move_next_to(next_to)
    self.widget.visible = true
    self:emit_signal("visibility", true)
end

function audio:hide()
    self.widget.visible = false
    self:emit_signal("visibility", false)
end

function audio:toggle(next_to)
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

local function application_widget(args)
    args = args or{}

    args.type = args.type or ""
    args.application = args.application or nil
    args.on_mute_press = args.on_mute_press or nil
    args.on_slider_moved = args.on_slider_moved or nil
    args.on_removed_cb = args.on_removed_cb or nil
    args.accent_color = args.accent_color or nil

    local icon = nil
    local font_icon = beautiful.get_font_icon_for_app_name(args.application.name)
    if font_icon == nil then
        icon = wibox.widget
        {
            widget = wibox.widget.imagebox,
            halign = "center",
            valign = "center",
            forced_height = dpi(25),
            forced_width = dpi(25),
            image = icon_theme:choose_icon
            {
                args.application.name,
                "gnome-audio",
                "org.pulseaudio.pavucontrol"
            }
        }
    else
        icon = widgets.text
        {
            size = 15,
            color = args.accent_color,
            font = font_icon.font,
            text = font_icon.icon
        }
    end

    local name = widgets.text
    {
        halign = "left",
        size = 15,
        text = args.application.name
    }

    local mute = widgets.button.text.state
    {
        on_by_default = args.application.mute,
        text_normal_bg = args.accent_color,
        on_normal_bg = args.accent_color,
        text_on_normal_bg = beautiful.colors.on_accent,
        font = beautiful.volume_off_icon.font,
        text = beautiful.volume_off_icon.icon,
        size = 12,
        halign = "right",
        on_press = function()
            args.on_mute_press()
        end
    }

    local slider = widgets.slider
    {
        forced_height = dpi(20),
        value = args.application.volume,
        maximum = 100,
        bar_height = 5,
        bar_shape = helpers.ui.rrect(beautiful.border_radius),
        bar_color = beautiful.colors.surface,
        bar_active_color = args.accent_color,
        handle_width = dpi(15),
        handle_color = beautiful.colors.on_background,
        handle_shape = gshape.circle,
    }

    local widget = wibox.widget
    {
        widget = wibox.container.margin,
        margins = { right = dpi(10) },
        {
            layout = wibox.layout.fixed.vertical,
            forced_height = dpi(80),
            spacing = dpi(15),
            {
                layout = wibox.layout.align.horizontal,
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = dpi(15),
                    icon,
                    name,
                },
                nil,
                mute,
            },
            slider
        }
    }

    pactl_daemon:connect_signal(args.type .. "::" .. args.application.id .. "::removed", function(self)
        args.on_removed_cb(widget)
    end)

    pactl_daemon:connect_signal(args.type .. "::" .. args.application.id .. "::icon_name", function(self, icon_name)
        icon.image = icon_theme:choose_icon
        {
            icon_name,
            args.application.name,
            "gnome-audio",
            "org.pulseaudio.pavucontrol"
        }
    end)

    pactl_daemon:connect_signal(args.type .. "::" .. args.application.id .. "::updated", function(self, application)
        slider:set_value_instant(application.volume)

        if application.mute == true then
            mute:turn_on()
        else
            mute:turn_off()
        end
    end)

    slider:connect_signal("property::value", function(self, value, instant)
        if instant == false then
            args.on_slider_moved(value)
        end
    end)

    return widget
end

local function device_widget(args)
    args = args or {}

    args.type = args.type or ""
    args.device = args.device or nil
    args.on_mute_press = args.on_mute_press or nil
    args.on_default_press = args.on_default_press or nil
    args.on_slider_moved = args.on_slider_moved or nil
    args.on_removed_cb = args.on_removed_cb or nil
    args.accent_color = args.accent_color or nil

    local name = widgets.text
    {
        width = dpi(440),
        halign = "left",
        size = 12,
        text = args.device.description
    }

    local mute = widgets.button.text.state
    {
        on_by_default = args.device.mute,
        text_normal_bg = args.accent_color,
        on_normal_bg = args.accent_color,
        text_on_normal_bg = beautiful.colors.on_accent,
        font = beautiful.volume_off_icon.font,
        text = beautiful.volume_off_icon.icon,
        size = 12,
        on_press = function()
            args.on_mute_press()
        end
    }

    local default = widgets.button.text.state
    {
        on_by_default = args.device.default,
        text_normal_bg = args.accent_color,
        on_normal_bg = args.accent_color,
        text_on_normal_bg = beautiful.colors.on_accent,
        font = beautiful.check_icon.font,
        text = beautiful.check_icon.icon,
        size = 12,
        on_press = function()
            args.on_default_press()
        end
    }

    local slider = widgets.slider
    {
        forced_height = dpi(20),
        value = args.device.volume,
        maximum = 100,
        bar_height = 5,
        bar_shape = helpers.ui.rrect(beautiful.border_radius),
        bar_color = beautiful.colors.surface,
        bar_active_color = args.accent_color,
        handle_width = dpi(15),
        handle_color = beautiful.colors.on_background,
        handle_shape = gshape.circle,
    }

    local widget = wibox.widget
    {
        widget = wibox.container.margin,
        margins = { right = dpi(10) },
        {
            layout = wibox.layout.fixed.vertical,
            forced_height = dpi(80),
            spacing = dpi(15),
            {
                layout = wibox.layout.align.horizontal,
                name,
                nil,
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = dpi(15),
                    mute,
                    default
                }
            },
            slider
        }
    }

    pactl_daemon:connect_signal(args.type .. "::" .. args.device.id .. "::removed", function(self)
        args.on_removed_cb(widget)
    end)

    pactl_daemon:connect_signal(args.type .. "::" .. args.device.id .. "::updated", function(self, device)
        slider:set_value_instant(device.volume)

        if device.default == true then
            default:turn_on()
        else
            default:turn_off()
        end
        if device.mute == true then
            mute:turn_on()
        else
            mute:turn_off()
        end
    end)

    slider:connect_signal("property::value", function(self, value, instant)
        if instant == false then
            args.on_slider_moved(value)
        end
    end)

    return widget
end

local function applications()
    local sink_inputs_accent_color = beautiful.random_accent_color()
    local sources_outputs_accent_color = beautiful.random_accent_color()

    local sink_inputs_header = widgets.text
    {
        halign = "left",
        bold = true,
        color = sink_inputs_accent_color,
        text = "Sink Inputs"
    }

    local sinks_inputs_layout = wibox.widget
    {
        layout = widgets.overflow.vertical,
        forced_height = dpi(300),
        spacing = dpi(15),
        scrollbar_widget =
        {
            widget = wibox.widget.separator,
            shape = helpers.ui.rrect(beautiful.border_radius),
        },
        scrollbar_width = dpi(10),
        step = 50,
    }

    local source_outputs_header = widgets.text
    {
        halign = "left",
        bold = true,
        color = sources_outputs_accent_color,
        text = "Source Outputs"
    }

    local source_outputs_layout = wibox.widget
    {
        layout = widgets.overflow.vertical,
        forced_height = dpi(300),
        spacing = dpi(15),
        scrollbar_widget =
        {
            widget = wibox.widget.separator,
            shape = helpers.ui.rrect(beautiful.border_radius),
        },
        scrollbar_width = dpi(10),
        step = 50,
    }

    pactl_daemon:connect_signal("sink_inputs::added", function(self, sink_input)
        sinks_inputs_layout:add(application_widget
        {
            type = "sink_inputs",
            application = sink_input,
            on_mute_press = function()
                pactl_daemon:sink_input_toggle_mute(sink_input.id)
            end,
            on_slider_moved = function(volume)
                pactl_daemon:sink_input_set_volume(sink_input.id, volume)
            end,
            on_removed_cb = function(widget)
                sinks_inputs_layout:remove_widgets(widget)
            end,
            accent_color = sink_inputs_accent_color
        })
    end)

    pactl_daemon:connect_signal("source_outputs::added", function(self, source_output)
        source_outputs_layout:add(application_widget
        {
            type = "source_output",
            application = source_output,
            on_mute_press = function()
                pactl_daemon:source_output_toggle_mute(source_output.id)
            end,
            on_slider_moved = function(volume)
                pactl_daemon:source_output_set_volume(source_output.id, volume)
            end,
            on_removed_cb = function(widget)
                source_outputs_layout:remove_widgets(widget)
            end,
            accent_color = sources_outputs_accent_color
        })
    end)

    return wibox.widget
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(30),
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            sink_inputs_header,
            separator(),
            sinks_inputs_layout,
        },
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            source_outputs_header,
            separator(),
            source_outputs_layout
        },
    }
end

local function devices()
    local sinks_accent_color = beautiful.random_accent_color()
    local sources_accent_color = beautiful.random_accent_color()

    local sinks_header = widgets.text
    {
        halign = "left",
        bold = true,
        color = sinks_accent_color,
        text = "Sinks"
    }

    local sinks_layout = wibox.widget
    {
        layout = widgets.overflow.vertical,
        forced_height = dpi(300),
        spacing = dpi(15),
        scrollbar_widget =
        {
            widget = wibox.widget.separator,
            shape = helpers.ui.rrect(beautiful.border_radius),
        },
        scrollbar_width = dpi(10),
        step = 50,
    }

    local sources_header = widgets.text
    {
        halign = "left",
        bold = true,
        color = sources_accent_color,
        text = "Sources"
    }

    local sources_layout = wibox.widget
    {
        layout = widgets.overflow.vertical,
        forced_height = dpi(300),
        spacing = dpi(15),
        scrollbar_widget =
        {
            widget = wibox.widget.separator,
            shape = helpers.ui.rrect(beautiful.border_radius),
        },
        scrollbar_width = dpi(10),
        step = 50,
    }

    pactl_daemon:connect_signal("sinks::added", function(self, sink)
        sinks_layout:add(device_widget
        {
            type = "sinks",
            device = sink,
            on_mute_press = function()
                pactl_daemon:sink_toggle_mute(sink.id)
            end,
            on_default_press = function()
                pactl_daemon:set_default_sink(sink.id)
            end,
            on_slider_moved = function(volume)
                pactl_daemon:sink_set_volume(sink.id, volume)
            end,
            on_removed_cb = function(widget)
                sinks_layout:remove_widgets(widget)
            end,
            accent_color = sinks_accent_color
        })
    end)

    pactl_daemon:connect_signal("sources::added", function(self, source)
        sources_layout:add(device_widget
        {
            type = "sources",
            device = source,
            on_mute_press = function()
                pactl_daemon:source_toggle_mute(source.id)
            end,
            on_default_press = function()
                pactl_daemon:set_default_source(source.id)
            end,
            on_slider_moved = function(volume)
                pactl_daemon:source_set_volume(source.id, volume)
            end,
            on_removed_cb = function(widget)
                sources_layout:remove_widgets(widget)
            end,
            accent_color = sources_accent_color
        })
    end)

    return wibox.widget
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(30),
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            sinks_header,
            separator(),
            sinks_layout,
        },
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            sources_header,
            separator(),
            sources_layout
        },
    }
end

local function widget()
    local accent_color = beautiful.random_accent_color()

    local _applications = applications()
    local _devices = devices()

    local content = wibox.widget
    {
        layout = wibox.layout.stack,
        top_only = true,
        _devices,
        _applications,
    }

    local devices_button = nil
    local applications_button = nil

    devices_button = widgets.button.text.state
    {
        on_by_default = true,
        size = 15,
        on_normal_bg = accent_color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        text = "Devices",
        animate_size = false,
        on_release = function()
            devices_button:turn_on()
            applications_button:turn_off()
            content:raise_widget(_devices)
        end
    }

    applications_button = widgets.button.text.state
    {
        size = 15,
        on_normal_bg = accent_color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        text = "Applications",
        animate_size = false,
        on_release = function()
            devices_button:turn_off()
            applications_button:turn_on()
            content:raise_widget(_applications)
        end
    }

    return wibox.widget
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(10),
        {
            layout = wibox.layout.flex.horizontal,
            spacing = dpi(10),
            devices_button,
            applications_button,
        },
        content
    }
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, audio, true)

    ret._private = {}

    ret.widget = awful.popup
    {
        bg = beautiful.colors.background,
        ontop = true,
        visible = false,
        minimum_width = dpi(600),
        maximum_width = dpi(600),
        shape = helpers.ui.rrect(beautiful.border_radius),
        widget =
        {
            widget = wibox.container.margin,
            margins = dpi(25),
            widget()
        }
    }

    return ret
end

if not instance then
    instance = new()
end
return instance