-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gshape = require("gears.shape")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local cpu_popup = require("ui.panels.action.info.cpu")
local ram_popup = require("ui.panels.action.info.ram")
local disk_popup = require("ui.panels.action.info.disk")
local audio_popup = require("ui.panels.action.info.audio")
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
local ipairs = ipairs

local info = {
    mt = {}
}

local function progress_bar(icon, on_release)
    local progress_bar = wibox.widget  {
        widget = widgets.progressbar,
        forced_width = dpi(450),
        forced_height = dpi(10),
        shape = helpers.ui.rrect(beautiful.border_radius),
        max_value = 100,
        bar_shape = helpers.ui.rrect(beautiful.border_radius),
        background_color = beautiful.colors.surface,
        color = icon.color
    }

    local icon = wibox.widget {
        widget = widgets.text,
        forced_width = dpi(40),
        forced_height = dpi(40),
        halign = "center",
        size = 15,
        icon = icon
    }

    local widget = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15),
        icon,
        {
            widget = wibox.container.place,
            valign = "center",
            progress_bar,
        }
    }

    if on_release ~= nil then
        local arrow = wibox.widget {
            widget = widgets.button.text.normal,
            forced_width = dpi(40),
            forced_height = dpi(40),
            size = 15,
            icon = beautiful.icons.chevron.right,
            text_normal_bg = beautiful.colors.on_background,
            on_release = function()
                on_release()
            end
        }
        widget:add(arrow)
        progress_bar.forced_width = dpi(390)
    end

    function widget:set_value(value)
        progress_bar.value = value
    end

    function widget:set_icon(new_icon)
        icon:set_icon(new_icon)
    end

    return widget
end

local function slider(icon, on_release)
    local slider = wibox.widget  {
        widget = widgets.slider,
        forced_width = dpi(390),
        forced_height = dpi(10),
        max_value = 100,
        bar_shape = helpers.ui.rrect(beautiful.border_radius),
        bar_color = beautiful.colors.surface,
        bar_active_color = icon.color,
        handle_color = beautiful.colors.on_background,
        handle_shape = function(cr, width, height)
            return gshape.rounded_bar(cr, 10, 35)
        end
    }

    local icon = wibox.widget {
        widget = widgets.text,
        forced_width = dpi(40),
        forced_height = dpi(40),
        halign = "center",
        size = 15,
        icon = icon
    }

    local arrow = wibox.widget {
        widget = widgets.button.text.normal,
        forced_width = dpi(40),
        forced_height = dpi(40),
        size = 15,
        icon = beautiful.icons.chevron.right,
        text_normal_bg = beautiful.colors.on_background,
        on_release = function()
            on_release()
        end
    }

    local widget = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15),
        icon,
        {
            widget = wibox.container.place,
            valign = "center",
            slider,
        },
        arrow
    }

    function widget:set_value(value)
        slider.value = value
    end

    function widget:set_icon(new_icon)
        icon:set_icon(new_icon)
    end

    return widget
end

local function cpu()
    local widget = progress_bar(beautiful.icons.microchip, function()
        cpu_popup:toggle()
    end)

    cpu_daemon:connect_signal("update::slim", function(self, value)
        widget:set_value(value)
    end)

    return widget
end

local function ram()
    local widget = progress_bar(beautiful.icons.memory, function()
        ram_popup:toggle()
    end)

    ram_daemon:connect_signal("update",
        function(self, total, used, free, shared, buff_cache, available, total_swap, used_swap, free_swap)

            local used_ram_percentage = math.floor((used / total) * 100)
            widget:set_value(used_ram_percentage)
        end)

    return widget
end

local function disk()
    local widget = progress_bar(beautiful.icons.disc_drive, function()
        disk_popup:toggle()
    end)

    disk_daemon:connect_signal("update", function(self, disks)
        for _, entry in ipairs(disks) do
            if entry.mount == "/" then
                widget:set_value(tonumber(entry.perc))
            end
        end
    end)

    return widget
end

local function temperature()
    local widget = progress_bar(beautiful.icons.thermometer.full)

    temperature_daemon:connect_signal("update", function(self, value)
        if value == nil then
            widget:set_icon(beautiful.icons.thermometer.quarter)
            widget:set_value(10)
        else
            if value == 0 then
                widget:set_icon(beautiful.icons.thermometer.quarter)
            elseif value <= 33 then
                widget:set_icon(beautiful.icons.thermometer.half)
            elseif value <= 66 then
                widget:set_icon(beautiful.icons.thermometer.three_quarter)
            elseif value > 66 then
                widget:set_icon(beautiful.icons.thermometer.full)
            end

            widget:set_value(value)
        end
    end)

    return widget
end

local function brightness()
    local widget = progress_bar(beautiful.icons.brightness)

    brightness_daemon:connect_signal("update", function(self, value)
        if value >= 0 then
            widget:set_value(value)
        end
    end)

    return widget
end

local function audio()
    local widget = slider(beautiful.icons.volume.off, function()
        audio_popup:toggle()
    end)

    pactl_daemon:connect_signal("default_sinks_updated", function(self, device)
        widget:set_value(device.volume)

        if device.mute or device.volume == 0 then
            widget:set_icon(beautiful.icons.volume.off)
        elseif device.volume <= 33 then
            widget:set_icon(beautiful.icons.volume.low)
        elseif device.volume <= 66 then
            widget:set_icon(beautiful.icons.volume.normal)
        elseif device.volume > 66 then
            widget:set_icon(beautiful.icons.volume.high)
        end
    end)

    return widget
end

local function new()
    return wibox.widget {
        layout = wibox.layout.flex.vertical,
        spacing = dpi(15),
        cpu(),
        ram(),
        disk(),
        audio(),
        temperature(),
        brightness(),
    }
end

function info.mt:__call()
    return new()
end

return setmetatable(info, info.mt)
