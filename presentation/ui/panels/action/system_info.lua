-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local cpu_popup = require("presentation.ui.applets.cpu")
local ram_popup = require("presentation.ui.applets.ram")
local disk_popup = require("presentation.ui.applets.disk")
local audio_popup = require("presentation.ui.applets.audio")
local beautiful = require("beautiful")
local cpu_daemon = require("daemons.hardware.cpu")
local ram_daemon = require("daemons.hardware.ram")
local disk_daemon = require("daemons.hardware.disk")
local temperature_daemon = require("daemons.hardware.temperature")
local pactl_daemon = require("daemons.hardware.pactl")
local brightness_daemon = require("daemons.system.brightness")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable
local tostring = tostring
local ipairs = ipairs

local system_info = { mt = {} }

local function arc_widget(icon, on_release, on_scroll_up, on_scroll_down)
    local icon_widget = nil
    if on_release ~= nil then
        icon_widget = widgets.button.text.normal
        {
            halign = "center",
            valign = "center",
            size = 30,
            font = icon.font,
            text = icon.icon,
            on_release = function()
                if on_release ~= nil then
                    on_release()
                end
            end,
            on_scroll_up = function()
                if on_scroll_up ~= nil then
                    on_scroll_up()
                end
            end,
            on_scroll_down = function()
                if on_scroll_down ~= nil then
                    on_scroll_down()
                end
            end,
        }
    else
        icon_widget = widgets.text
        {
            halign = "center",
            valign = "center",
            size = 30,
            font = icon.font,
            text = icon.icon,
        }
    end

    local arc = wibox.widget
    {
        widget = wibox.container.arcchart,
        forced_width = dpi(90),
        forced_height =  dpi(90),
        max_value = 100,
        min_value = 0,
        value = 0,
        thickness = dpi(7),
        rounded_edge = true,
        bg = beautiful.colors.surface,
        colors =
        {
            {
                type = "linear",
                from = {0, 0},
                to = {400, 400},
                stops = {{0, beautiful.random_accent_color()}, {0.2, beautiful.random_accent_color()}, {0.4, beautiful.random_accent_color()}, {0.6, beautiful.random_accent_color()}, {0.8, beautiful.random_accent_color()}}
            }
        },
        icon_widget
    }

    local value_text = widgets.text
    {
        halign = "center",
        text = "0%"
    }

    local widget = wibox.widget
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        arc,
        value_text
    }

    function widget:set_value(value)
        arc.value = value
        value_text:set_text(tostring(value) .. "%")
    end

    function widget:set_icon(icon)
        icon_widget:set_text(icon)
    end

    return widget
end

local function cpu(action_panel)
    local arc = arc_widget(beautiful.microchip_icon, function()
        cpu_popup:toggle(action_panel.widget)
    end)

    cpu_daemon:connect_signal("update::slim", function(self, value)
        arc:set_value(value)
    end)

    return arc
end

local function ram(action_panel)
    local arc = arc_widget(beautiful.memory_icon, function()
        ram_popup:toggle(action_panel.widget)
    end)

    ram_daemon:connect_signal("update", function(self, total, used, free, shared, buff_cache,
        available, total_swap, used_swap, free_swap)

        local used_ram_percentage = math.floor((used / total) * 100)
        arc:set_value(used_ram_percentage)
    end)

    return arc
end

local function disk(action_panel)
    local arc = arc_widget(beautiful.disc_drive_icon, function()
        disk_popup:toggle(action_panel.widget)
    end)

    disk_daemon:connect_signal("update", function(self, disks)
        for _, entry in ipairs(disks) do
            if entry.mount == "/" then
                arc:set_value(entry.perc)
            end
        end
    end)

    return arc
end

local function temperature()
    local arc = arc_widget(beautiful.thermometer_full_icon)

    temperature_daemon:connect_signal("update", function(self, value)
        if value == nil then
            arc:set_icon(beautiful.thermometer_quarter_icon.icon)
            arc:set_value(10)
        else
            if value == 0 then
                arc:set_icon(beautiful.thermometer_quarter_icon.icon)
            elseif value <= 33 then
                arc:set_icon(beautiful.thermometer_half_icon.icon)
            elseif value <= 66 then
                arc:set_icon(beautiful.thermometer_three_quarter_icon.icon)
            elseif value > 66 then
                arc:set_icon(beautiful.thermometer_full_icon.icon)
            end

            arc:set_value(value)
        end
    end)

    return arc
end

local function brightness()
    local arc = arc_widget(beautiful.brightness_icon)

    brightness_daemon:connect_signal("update", function(self, value)
        if value >= 0 then
            arc:set_value(value)
        end
    end)

    return arc
end

local function audio(action_panel)
    local arc = arc_widget(beautiful.volume_off_icon, function()
        audio_popup:toggle(action_panel.widget)
    end,
    function()
        pactl_daemon:sink_volume_up(nil, 5)
    end,
    function()
        pactl_daemon:sink_volume_down(nil, 5)
    end)

    pactl_daemon:connect_signal("default_sinks_updated", function(self, device)
        arc:set_value(device.volume)

        if device.mute or device.volume == 0 then
            arc:set_icon(beautiful.volume_off_icon.icon)
        elseif device.volume <= 33 then
            arc:set_icon(beautiful.volume_low_icon.icon)
        elseif device.volume <= 66 then
            arc:set_icon(beautiful.volume_normal_icon.icon)
        elseif device.volume > 66 then
            arc:set_icon(beautiful.volume_high_icon.icon)
        end
    end)

    return arc
end

local function new(action_panel)
    return wibox.widget
    {
        layout =  wibox.layout.fixed.vertical,
        forced_height = dpi(300),
        spacing = dpi(30),
        {
            layout = wibox.layout.flex.horizontal,
            spacing = dpi(30),
            cpu(action_panel),
            ram(action_panel),
            disk(action_panel)
        },
        {
            layout = wibox.layout.flex.horizontal,
            spacing = dpi(30),
            temperature(),
            brightness(),
            audio(action_panel),
        }
    }
end

function system_info.mt:__call(action_panel)
    return new(action_panel)
end

return setmetatable(system_info, system_info.mt)