local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local screenshot_popup = require("presentation.ui.apps.screenshot")
local record_popup = require("presentation.ui.apps.record")
local wifi_popup = require("presentation.ui.applets.wifi")
local bluetooth_popup = require("presentation.ui.applets.bluetooth")
local beautiful = require("beautiful")
local radio_daemon = require("daemons.hardware.radio")
local network_manager_daemon = require("daemons.hardware.network_manager")
local bluetooth_daemon = require("daemons.hardware.bluetooth")
local picom_daemon = require("daemons.system.picom")
local redshift_daemon = require("daemons.system.redshift")
local pactl_daemon = require("daemons.hardware.pactl")
local record_daemon = require("daemons.system.record")
local notifications_daemon = require("daemons.system.notifications")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local system_control = { mt = {} }

local function arrow_button(icon, text, on_icon_release, on_arrow_release)
    local accent_color = beautiful.random_accent_color()

    local icon = widgets.button.text.state
    {
        forced_width = dpi(75),
        forced_height = dpi(90),
        normal_shape = helpers.ui.prrect(beautiful.border_radius, true, false, false, true),
        normal_bg = beautiful.colors.surface,
        on_normal_bg = accent_color,
        text_on_normal_bg = beautiful.colors.background,
        font = icon.font,
        text = icon.icon,
        on_release = on_icon_release
    }

    local arrow = widgets.button.text.state
    {
        forced_width = dpi(75),
        forced_height = dpi(90),
        normal_shape = helpers.ui.prrect(beautiful.border_radius, false, true, true, false),
        normal_bg = beautiful.colors.surface,
        on_normal_bg = accent_color,
        text_on_normal_bg = beautiful.colors.background,
        font = beautiful.chevron_right_icon.font,
        text = beautiful.chevron_right_icon.icon,
        on_release = on_arrow_release
    }

    local button = wibox.widget
    {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(1),
        icon,
        arrow
    }

    local name = widgets.text
    {
        halign = "center",
        size = 15,
        text = text
    }

    return wibox.widget
    {
        layout = wibox.layout.fixed.vertical,
        forced_height = dpi(130),
        spacing = dpi(15),
        turn_on = function(self, text)
            icon:turn_on()
            arrow:turn_on()
            name.markup = text
        end,
        turn_off = function(self, text)
            icon:turn_off()
            arrow:turn_off()
            name.markup = text
        end,
        button,
        name
    }
end

local function button(icon, text, on_release)
    local icon = widgets.button.text.state
    {
        forced_width = dpi(150),
        forced_height = dpi(90),
        normal_bg = beautiful.colors.surface,
        on_normal_bg = beautiful.random_accent_color(),
        text_on_normal_bg = beautiful.colors.background,
        font = icon.font,
        text = icon.icon,
        on_release = on_release
    }

    local name = widgets.text
    {
        halign = "center",
        size = 15,
        text = text
    }

    return wibox.widget
    {
        layout = wibox.layout.fixed.vertical,
        forced_height = dpi(130),
        spacing = dpi(15),
        turn_on = function(self, text)
            icon:turn_on()
            name.markup = text
        end,
        turn_off = function(self, text)
            icon:turn_off()
            name.markup = text
        end,
        icon,
        name
    }
end

local function quick_action(icon, text, on_release)
    local icon = widgets.button.text.normal
    {
        forced_width = dpi(150),
        forced_height = dpi(90),
        normal_bg = beautiful.colors.surface,
        font = icon.font,
        text = icon.icon,
        on_release = on_release
    }

    local name = widgets.text
    {
        halign = "center",
        size = 15,
        text = text
    }

    return wibox.widget
    {
        layout = wibox.layout.fixed.vertical,
        forced_height = dpi(130),
        spacing = dpi(15),
        icon,
        name
    }
end

local function wifi(action_panel)
    local widget = arrow_button
    (
        beautiful.wifi_high_icon,
        "Wi-Fi",
        function()
            network_manager_daemon:toggle_wireless_state()
        end,
        function()
            wifi_popup:toggle(action_panel.widget)
        end
    )

    network_manager_daemon:connect_signal("wireless_state", function(self, state)
        if state == true then
            widget:turn_on("Wi-Fi")
        else
            widget:turn_off("Wi-Fi")
        end
    end)

    -- local network_tooltip = awful.tooltip
    -- {
    --     objects = {widget},
    --     mode = "outside",
    --     preferred_alignments = { "middle" },
    --     margin_leftright = dpi(15),
    --     margin_topbottom = dpi(15),
    --     gaps = dpi(15),
    --     shape = helpers.ui.rrect(beautiful.border_radius),
    --     bg = beautiful.colors.background,
    --     fg = beautiful.colors.on_background,
    --     font = beautiful.font_name .. 15,
    --     text = "Loading..."
    -- }

    -- network_daemon:connect_signal("wired::disconnected", function(self)
    --     widget:turn_off("Disconnected")
    --     network_tooltip:set_markup("Network is currently disconnected")
    -- end)
    -- network_daemon:connect_signal("wired::connected", function(self, interface, healthy)
    --     if healthy then
    --         widget:turn_on(interface)
    --         network_tooltip:set_markup("Ethernet Interface: <b>" .. interface .. "</b>")
    --     else
    --         widget:turn_on("No Internet")
    --         network_tooltip:set_markup
    --         (
    --             "<b>Connected but no internet!</b>" ..
    --             "\nEthernet Interface: <b>" .. interface .. "</b>"
    --         )
    --     end

    --     widget:turn_on("Connected")
    -- end)

    -- network_daemon:connect_signal("wireless::disconnected", function(self)
    --     widget:turn_off("Wi-Fi")
    --     network_tooltip:set_markup("Network is currently disconnected")
    -- end)
    -- network_daemon:connect_signal("wireless::connected", function(self, essid, interface, strength, strength_level, bitrate, healthy)
    --     local message = "Connected to: <b>" .. (essid or "Loading...*") ..
    --     "</b>\nWireless Interface: <b>" .. interface ..
    --     "</b>\nWiFi-Strength: <b>" .. tostring(strength) .. "%" ..
    --     "</b>\nBit rate: <b>" .. tostring(bitrate) .. "</b>"

    --     if healthy then
    --         network_tooltip:set_markup(message)
    --         widget:turn_on(essid)
    --     else
    --         network_tooltip:set_markup("<b>Connected but no internet!</b>\n" .. message)
    --         widget:turn_on("No Internet")
    --     end
    -- end)
    -- network_daemon:connect_signal("wireless::connecting", function(self)
    --     widget:turn_on("Connecting")
    -- end)

    return widget
end

local function bluetooth(action_panel)
    local widget = arrow_button
    (
        beautiful.bluetooth_icon,
        "Bluetoooth",
        function()
            bluetooth_daemon:toggle()
        end,
        function()
            bluetooth_popup:toggle(action_panel.widget)
        end
    )

    bluetooth_daemon:connect_signal("state", function(self, state)
        if state == true then
            widget:turn_on("Connected")
        else
            widget:turn_off("Bluetooth")
        end
    end)

    return widget
end

local function airplane_mode()
    local widget = button
    (
        beautiful.airplane_icon,
        "Airplane Mode",
        function()
            radio_daemon:toggle()
        end
    )

    radio_daemon:connect_signal("state", function(self, state)
        if state == true then
            widget:turn_on("Airplane Mode")
        else
            widget:turn_off("Airplane Mode")
        end
    end)

    return widget
end

local function blue_light()
    local widget =  button
    (
        beautiful.lightbulb_icon,
        "Blue Light",
        function()
            redshift_daemon:toggle()
        end
    )

    redshift_daemon:connect_signal("update", function(self, state)
        if state == true then
            widget:turn_on("Blue Light")
        else
            widget:turn_off("Blue Light")
        end
    end)

    return widget
end

local function compositor()
    local widget =  button
    (
        beautiful.spraycan_icon,
        "Compositor",
        function()
            picom_daemon:toggle(true)
        end
    )

    picom_daemon:connect_signal("state", function(self, state)
        if state == true then
            widget:turn_on("Compositor")
        else
            widget:turn_off("Compositor")
        end
    end)

    return widget
end

local function dont_disturb()
    local widget = button
    (
        beautiful.suspend_icon,
        "Don't Disturb",
        function()
            notifications_daemon:toggle()
        end
    )

    notifications_daemon:connect_signal("state", function(self, state)
        if state == true then
            widget:turn_on("Don't Disturb")
        else
            widget:turn_off("Don't Disturb")
        end
    end)

    return widget
end

local function screenshot()
    local widget = quick_action
    (
        beautiful.camera_retro_icon,
        "Screenshot",
        function()
            screenshot_popup:show()
        end
    )

    return widget
end

local function microphone()
    local widget = button
    (
        beautiful.microphone_icon,
        "Microphone",
        function()
            pactl_daemon:source_toggle_mute()
        end
    )

    pactl_daemon:connect_signal("default_sources_updated", function(self, device)
        if device.mute == false then
            widget:turn_on("Microphone")
        else
            widget:turn_off("Microphone")
        end
    end)

    return widget
end

local function record()
    local widget = button
    (
        beautiful.video_icon,
        "Record",
        function()
            if record_daemon:get_is_recording() == false then
                record_popup:show()
            else
                record_daemon:stop_video()
            end
        end
    )

    record_daemon:connect_signal("started", function()
        widget:turn_on("Stop")
    end)

    record_daemon:connect_signal("ended", function()
        widget:turn_off("Record")
    end)

    return widget
end

local function new(action_panel)
    return wibox.widget
    {
        layout =  wibox.layout.fixed.vertical,
        forced_height = dpi(450),
        spacing = dpi(30),
        {
            layout = wibox.layout.flex.horizontal,
            spacing = dpi(30),
            wifi(action_panel),
            bluetooth(action_panel),
            airplane_mode()
        },
        {
            layout = wibox.layout.flex.horizontal,
            spacing = dpi(30),
            blue_light(),
            compositor(),
            dont_disturb()
        },
        {
            layout = wibox.layout.flex.horizontal,
            spacing = dpi(30),
            record(),
            screenshot(),
            microphone()
        }
    }
end

function system_control.mt:__call(action_panel)
    return new(action_panel)
end

return setmetatable(system_control, system_control.mt)