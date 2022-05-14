local awful = require("awful")
local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local action_panel = require("presentation.ui.panels.action")
local info_panel = require("presentation.ui.panels.info")
local message_panel = require("presentation.ui.panels.message")
local app_launcher = require("presentation.ui.popups.app_launcher")
local task_preview = require("presentation.ui.popups.task_preview")
local beautiful = require("beautiful")
local network_daemon = require("daemons.hardware.network")
local bluetooth_daemon = require("daemons.hardware.bluetooth")
local pactl_daemon = require("daemons.hardware.pactl")
local upower_daemon = require("daemons.hardware.upower")
local icon_theme = require("services.icon_theme")
local animation = require("services.animation")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local string = string
local ipairs = ipairs
local capi = { awesome = awesome, root = root, screen = screen, client = client }

-- =============================================================================
--  Start button
-- =============================================================================
local function start()
    local widget = widgets.button.text.state
    {
        forced_width = dpi(60),
        margins = dpi(5),
        font = beautiful.bars_staggered_icon.font,
        size = 25,
        text = beautiful.bars_staggered_icon.icon,
        on_release = function()
            app_launcher:toggle()
        end
    }

    app_launcher:connect_signal("bling::app_launcher::visibility", function(self, visibility)
        if visibility == true then
            widget:turn_on()
        else
            widget:turn_off()
        end
    end)

    return widget
end

-- =============================================================================
--  Tag list
-- =============================================================================
local function update_taglist(self, tag)
    if #tag:clients() == 0 then
        self.indicator_animation:set(dpi(0))
    else
        self.indicator_animation:set(dpi(40))
    end

    if tag.selected then
        self.widget.children[1]:turn_on()
    else
        self.widget.children[1]:turn_off()
    end
end

local function tag_list(s)
    local taglist_icons =
    {
        beautiful.firefox_icon,
        beautiful.code_icon,
        beautiful.git_icon,
        beautiful.discord_icon,
        beautiful.spotify_icon,
        beautiful.steam_icon,
        beautiful.gamepad_alt_icon,
        beautiful.led_icon,
        beautiful.mug_saucer_icon
    }

    return awful.widget.taglist
    {
        screen = s,
        filter = awful.widget.taglist.filter.all,
        layout = { layout = wibox.layout.fixed.vertical },
        widget_template =
        {
            widget = wibox.container.margin,
            forced_width = dpi(60),
            forced_height = dpi(60),
            create_callback = function(self, tag, index, tags)
                local accent_color = beautiful.random_accent_color()

                local button = widgets.button.text.state
                {
                    size = taglist_icons[index].size,
                    font = taglist_icons[index].font,
                    text = taglist_icons[index].icon,
                    text_normal_bg = accent_color,
                    on_hover = function()
                        if #tag:clients() > 0 then
                            -- capi.awesome.emit_signal("bling::tag_preview::update", tag)
                            -- capi.awesome.emit_signal("bling::tag_preview::visibility", s, true)
                        end
                    end,
                    on_leave = function()
                        -- capi.awesome.emit_signal("bling::tag_preview::visibility", s, false)
                    end,
                    on_release = function(self, lx, ly, button, mods, find_widgets_result)
                        if button == 1 then
                            helpers.misc.tag_back_and_forth(tag.index)
                        elseif button == 3 then
                            awful.tag.viewtoggle(tag)
                        elseif button == 4 then
                            awful.tag.viewnext(tag.screen)
                        elseif button == 5 then
                            awful.tag.viewprev(tag.screen)
                        end
                    end
                }

                local indicator = wibox.widget
                {
                    widget = wibox.container.place,
                    halign = "right",
                    valign = "center",
                    {
                        widget = wibox.container.background,
                        forced_width = dpi(5),
                        shape = helpers.ui.rrect(beautiful.border_radius),
                        bg = accent_color
                    }
                }

                local stack = wibox.widget
                {
                    widget = wibox.layout.stack,
                    button,
                    indicator
                }

                self.indicator_animation = animation:new
                {
                    duration = 0.125,
                    easing = animation.easing.linear,
                    update = function(self, pos)
                        indicator.children[1].forced_height = pos
                    end
                }

                self:set_widget(stack)

                update_taglist(self, tag)
            end,
            update_callback = function(self, tag, index, tags)
                update_taglist(self, tag)
            end,
        },
    }
end

-- =============================================================================
--  Task list
-- =============================================================================
local function client_checkbox_button(client, property, text, checkbox_color)
    local button = widgets.menu.checkbox_button
    {
        checkbox_color = checkbox_color,
        text = text,
        on_press = function() client[property] = not client[property] end
    }

    client:connect_signal("property::" .. property, function()
        if client[property] then
            button:turn_on()
        else
            button:turn_off()
        end
    end)

    return button
end

local function task_list_menu(client)
    local checkbox_color = beautiful.random_accent_color()

    local maximize_menu = widgets.menu
    {
        client_checkbox_button(client, "maximized", "Maximize", checkbox_color),
        client_checkbox_button(client, "maximized_horizontal", "Maximize Horizontally", checkbox_color),
        client_checkbox_button(client, "maximized_vertical", "Maximize Vertically", checkbox_color),
    }

    local layer_menu = widgets.menu
    {
        client_checkbox_button(client, "above", "Above", checkbox_color),
        client_checkbox_button(client, "below", "Below", checkbox_color),
        client_checkbox_button(client, "ontop", "On Top", checkbox_color),
    }

    return widgets.menu
    {
        widgets.menu.button
        {
            icon = client.font_icon,
            -- image = icon_theme:get_client_icon_path(client),
            text = client.class,
            on_press = function() client:jump_to() end
        },
        widgets.menu.sub_menu_button
        {
            text = "Maximize",
            sub_menu = maximize_menu
        },
        client_checkbox_button(client, "minimized", "Minimize", checkbox_color),
        client_checkbox_button(client, "fullscreen", "Fullscreen", checkbox_color),
        client_checkbox_button(client, "sticky", "Sticky", checkbox_color),
        client_checkbox_button(client, "hidden", "Hidden", checkbox_color),
        client_checkbox_button(client, "floating", "Floating", checkbox_color),
        widgets.menu.sub_menu_button
        {
            text = "Layer",
            sub_menu = layer_menu
        },
        widgets.menu.button
        {
            text = "Close",
            on_press = function() client:kill() end
        },
    }
end

local function client_task(task_list, client, screen)
    client.font_icon = beautiful.window_icon
    for _, app in pairs(beautiful.apps) do
        if app.class == client.class then
            client.font_icon = app.icon
            break
        end
    end

    local task_list_menu = task_list_menu(client)

    -- Font icon
    local button = widgets.button.text.state
    {
        on_by_default = capi.client.focus == client,
        forced_width = dpi(65),
        forced_height = dpi(65),
        margins = dpi(5),
        valign = "center",
        size = client.font_icon.size or 20,
        font = client.font_icon.font,
        text = client.font_icon.icon,
        on_hover = function(self)
            -- task_preview:show(client, {wibox = awful.screen.focused().top_wibar, widget = self, offset = { y = 100}})
        end,
        on_leave = function()
            -- task_preview:hide()
        end,
        on_release = function()
            if client.minimized == false then
                if capi.client.focus == client then
                    client.minimized = true
                else
                    capi.client.focus = client
                    client:raise()
                end
            else
                client.minimized = false
            end
            if client:tags() and client:tags()[1] then
                client:tags()[1]:view_only()
            else
                client:tags({awful.screen.focused().selected_tag})
            end
        end,
        on_secondary_press = function(self)
            task_preview:hide()
            task_list_menu:toggle{
                wibox = awful.screen.focused().top_wibar,
                widget = self,
                offset = { y = 100 },
            }
        end
    }

    -- Real client icon (make this an option to choose from?)
    -- commented out for now
    -- local button = widgets.button.image.state
    -- {
    --     on_by_default = capi.client.focus == client,
    --     forced_width = dpi(50),
    --     forced_height = dpi(50),
    --     margins = dpi(5),
    --     image_valign = "top",
    --     image = icon_theme:get_client_icon_path(client),
    --     on_hover = function(self)
    --         -- task_preview:show(client, {wibox = awful.screen.focused().top_wibar, widget = self, offset = { y = 100}})
    --     end,
    --     on_leave = function()
    --         -- task_preview:hide()
    --     end,
    --     on_release = function()
    --         if client.minimized == false then
    --             if capi.client.focus == client then
    --                 client.minimized = true
    --             else
    --                 capi.client.focus = client
    --                 client:raise()
    --             end
    --         else
    --             client.minimized = false
    --         end
    --         if client:tags() and client:tags()[1] then
    --             client:tags()[1]:view_only()
    --         else
    --             client:tags({awful.screen.focused().selected_tag})
    --         end
    --     end,
    --     on_secondary_press = function(self)
    --         task_preview:hide()
    --         task_list_menu:toggle{
    --             wibox = awful.screen.focused().top_wibar,
    --             widget = self,
    --             offset = { y = 100 },
    --         }
    --     end
    -- }

    local indicator = wibox.widget
    {
        widget = wibox.container.place,
        valign = "bottom",
        {
            widget = wibox.container.background,
            forced_width = capi.client.focus == client and dpi(50) or dpi(20),
            forced_height = dpi(5),
            shape = helpers.ui.rrect(beautiful.border_radius),
            bg = beautiful.random_accent_color(),
        }
    }

    local indicator_animation = animation:new
    {
		pos = capi.client.focus == client and dpi(50) or dpi(20),
        duration = 0.125,
        easing = animation.easing.linear,
        update = function(self, pos)
            indicator.children[1].forced_width = pos
        end
    }

    local widget = wibox.widget
    {
        widget = wibox.layout.stack,
        button,
        indicator
    }

    client.remove_from_tasklist = function() task_list:remove_widgets(widget) end

    client:connect_signal("property::class", function()
        button:set_image(icon_theme:get_client_icon_path(client))
    end)

    client:connect_signal("focus", function()
        button:turn_on()
        indicator_animation:set(dpi(50))
    end)

    client:connect_signal("unfocus", function()
        button:turn_off()
        indicator_animation:set(dpi(20))
    end)

    client:connect_signal("swapped", function()
        if awful.client.getmaster() == client then
            if task_list:remove_widgets(widget) == true then
                task_list:insert(1, widget)
            end
        end
    end)

    client:connect_signal("unmanage", function()
        task_list:remove_widgets(widget)
    end)

    if awful.client.getmaster() == client then
        task_list:insert(1, widget)
    else
        task_list:add(widget)
    end

    client.current_task_list = task_list
    client.current_task_widget = widget
end

local function task_list(s)
    local task_list = wibox.widget
    {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(20)
    }

    for _, __ in ipairs(s.tags) do
        local tag_task_list = wibox.widget
        {
            layout = wibox.layout.flex.horizontal,
            spacing = dpi(15),
        }
        task_list:add(tag_task_list)
    end

    for _, c in ipairs(capi.client.get()) do
        client_task(task_list.children[c.first_tag.index], c, s)
    end

    capi.client.connect_signal("tagged", function(c, t)
        if c.current_task_list and c.current_task_widget then
            c.current_task_list:remove_widgets(c.current_task_widget)
            c.current_task_list = nil
            c.current_task_widget = nil
        end

        client_task(task_list.children[t.index], c, s)
    end)

    return task_list
end

-- =============================================================================
--  Tray
-- =============================================================================
local function system_tray()
    local system_tray = wibox.widget
    {
        widget = wibox.container.constraint,
        strategy = "max",
        width = dpi(0),
        {
            widget = wibox.container.margin,
            margins = { left = dpi(15), top = dpi(20) },
            {
                widget = wibox.widget.systray,
                base_size = dpi(25)
            }
        }
    }

    local system_tray_animation = animation:new
    {
        easing = animation.easing.linear,
        duration = 0.125,
        update = function(self, pos)
            system_tray.width = pos
        end
    }

    local arrow = widgets.button.text.state
    {
        forced_width = dpi(50),
        forced_height = dpi(50),
        margins = dpi(5),
        font = beautiful.chevron_circle_left_icon.font,
        text = beautiful.chevron_circle_left_icon.icon,
        on_turn_on = function(self)
            system_tray_animation:set(400)
            self:set_text(beautiful.chevron_circle_right_icon.icon)
        end,
        on_turn_off = function(self)
            system_tray_animation:set(0)
            self:set_text(beautiful.chevron_circle_left_icon.icon)
        end,
    }

    return wibox.widget
    {
        layout = wibox.layout.fixed.horizontal,
        arrow,
        system_tray
    }
end

local function network()
    local widget = widgets.text
    {
        halign = "center",
        size = 17,
        color = beautiful.random_accent_color(),
        font = beautiful.wifi_off_icon.font,
        text = beautiful.wifi_off_icon.icon,
    }

    network_daemon:connect_signal("network_state", function(self, state)
        if state then
            widget:set_text(beautiful.wifi_low_icon.icon)
        else
            widget:set_text(beautiful.wifi_off_icon.icon)
        end
    end)

    network_daemon:connect_signal("wireless_state", function(self, state)
        if state then
            widget:set_text(beautiful.wifi_low_icon.icon)
        else
            widget:set_text(beautiful.wifi_off_icon.icon)
        end
    end)

    network_daemon:connect_signal("access_point::connected", function(self, ssid, strength)
        if strength < 33 then
            widget:set_text(beautiful.wifi_low_icon.icon)
        elseif strength >= 33 then
            widget:set_text(beautiful.wifi_medium_icon.icon)
        elseif strength >= 66 then
            widget:set_text(beautiful.wifi_high_icon.icon)
        end
    end)

    return widget
end

local function bluetooth()
    local widget = widgets.text
    {
        halign = "center",
        size = 17,
        color = beautiful.random_accent_color(),
        font = beautiful.bluetooth_icon.font,
        text = beautiful.bluetooth_icon.icon,
    }

    bluetooth_daemon:connect_signal("state", function(self, state)
        if state == true then
            widget:set_text(beautiful.bluetooth_icon.icon)
        else
            widget:set_text(beautiful.bluetooth_off_icon.icon)
        end
    end)

    return widget
end

local function volume()
    local widget = widgets.text
    {
        halign = "center",
        size = 17,
        color = beautiful.random_accent_color(),
        font = beautiful.volume_normal_icon.font,
        text = beautiful.volume_normal_icon.icon,
    }

    pactl_daemon:connect_signal("default_sinks_updated", function(self, device)
        if device.mute or device.volume == 0 then
            widget:set_text(beautiful.volume_off_icon.icon)
        elseif device.volume <= 33 then
            widget:set_text(beautiful.volume_low_icon.icon)
        elseif device.volume <= 66 then
            widget:set_text(beautiful.volume_normal_icon.icon)
        elseif device.volume > 66 then
            widget:set_text(beautiful.volume_high_icon.icon)
        end
    end)

    return widget
end

local function custom_tray()
    local layout = wibox.widget
    {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(20),
        network(),
        bluetooth(),
        volume()
    }

    local startup = true
    upower_daemon:connect_signal("battery::update", function()
        if startup == true then
            layout:add(widgets.battery_icon())
            startup = false
        end
    end)

    local widget = widgets.button.elevated.state
    {
        margins = dpi(5),
        on_release = function()
            action_panel:toggle()
        end,
        child = layout
    }

    action_panel:connect_signal("visibility", function(self, visibility)
        if visibility == true then
            widget:turn_on()
        else
            widget:turn_off()
        end
    end)

    return widget
end

local function tray()
    return wibox.widget
    {
        layout = wibox.layout.fixed.horizontal,
        system_tray(),
        custom_tray(),
    }
end

-- =============================================================================
--  Time
-- =============================================================================
local function time()
    local accent_color = beautiful.random_accent_color()
    local clock = wibox.widget
    {
        widget = wibox.widget.textclock,
        format = "%d %b %H:%M",
        align = "center",
        valign = "center",
        font = beautiful.font_name .. 14,
    }

    clock.markup = helpers.ui.colorize_text(clock.text, accent_color)
    clock:connect_signal("widget::redraw_needed", function()
        clock.markup = helpers.ui.colorize_text(clock.text, accent_color)
    end)

    local widget = widgets.button.elevated.state
    {
        normal_bg = string.sub(beautiful.colors.background, 1, 7) .. "00",
        margins = dpi(5),
        on_release = function()
            info_panel:toggle()
        end,
        child = clock
    }

    info_panel:connect_signal("visibility", function(self, visibility)
        if visibility == true then
            widget:turn_on()
        else
            widget:turn_off()
        end
    end)

    return widget
end

-- =============================================================================
--  Messages center button
-- =============================================================================
local function messages_button()
    local widget =  widgets.button.text.state
    {
        forced_width = dpi(50),
        forced_height = dpi(50),
        margins = dpi(5),
        font = beautiful.envelope_icon.font,
        text = beautiful.envelope_icon.icon,
        on_release = function()
            message_panel:toggle()
        end
    }

    message_panel:connect_signal("visibility", function(self, visibility)
        if visibility == true then
            widget:turn_on()
        else
            widget:turn_off()
        end
    end)

    return widget
end

-- =============================================================================
--  Wibar
-- =============================================================================
capi.screen.connect_signal("request::desktop_decoration", function(s)
    if s.top_wibar then
        s.top_wibar.visible = false
    end
    if s.left_wibar then
        s.left_wibar.visible = false
    end

    -- Using popup instead of the wibar widget because it has some edge case bugs with detecting mouse input correctly
    s.top_wibar = awful.popup
    {
        screen = s,
        type = "dock",
        maximum_height = dpi(65),
        minimum_width = s.geometry.width,
        maximum_width = s.geometry.width,
        buttons =
        {
            awful.button({ }, 1, function ()
                capi.awesome.emit_signal("lmb::pressed")
            end),
            awful.button({ }, 3, function ()
                capi.awesome.emit_signal("rmb::pressed")
            end)
        },
        widget =
        {
            layout = wibox.layout.align.horizontal,
            expand = "outside",
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(15),
                start(),
                task_list(s),
            },
            time(),
            {
                widget = wibox.container.place,
                halign = "right",
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = dpi(20),
                    tray(),
                    messages_button(),
                    widgets.spacer.horizontal(5)
                }
            }
        }
    }
    s.top_wibar:struts{top = dpi(65)}

    s.left_wibar = awful.popup
    {
        screen = s,
        type = "dock",
        y = 65,
        maximum_width = dpi(65),
        minimum_height = s.geometry.height,
        maximum_height = s.geometry.height,
        buttons =
        {
            awful.button({ }, 1, function ()
                capi.awesome.emit_signal("lmb::pressed")
            end),
            awful.button({ }, 3, function ()
                capi.awesome.emit_signal("rmb::pressed")
            end)
        },
        widget =
        {
            widget = wibox.container.margin,
            forced_width = dpi(65),
            tag_list(s)
        }
    }
    s.left_wibar:struts{left = dpi(65)}
end)