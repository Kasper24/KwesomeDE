-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gtimer = require("gears.timer")
local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local action_panel = require("presentation.ui.panels.action")
local info_panel = require("presentation.ui.panels.info")
local message_panel = require("presentation.ui.panels.message")
local app_launcher = require("presentation.ui.popups.app_launcher")
local task_preview = require("presentation.ui.popups.task_preview")
local tag_preview = require("presentation.ui.popups.tag_preview")
local beautiful = require("beautiful")
local network_daemon = require("daemons.hardware.network")
local bluetooth_daemon = require("daemons.hardware.bluetooth")
local pactl_daemon = require("daemons.hardware.pactl")
local upower_daemon = require("daemons.hardware.upower")
local favorites_daemon = require("daemons.system.favorites")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local ipairs = ipairs
local capi = { awesome = awesome, root = root, screen = screen, client = client }

-- =============================================================================
--  Start button
-- =============================================================================
local function get_draw(pos, color)
	return function(_, _, cr, _, height)
		cr:set_source_rgb(color.r / 255, color.g / 255, color.b / 255)
		cr:set_line_width(0.1 * height)

		--top, middle, bottom, left, right, radius, radius/2 pi*2
		local t, m, b, l, r, ra, ra2, pi2
		t = 0.3 * height
		m = 0.5 * height
		b = 0.7 * height
		l = 0.25 * height
		r = 0.75 * height
		ra = 0.05 * height
		ra2 = ra/2
		pi2 = math.pi * 2

		if pos <= 0.5 then

			local tpos = t+(m-t)*pos
			local bpos = b - (b - m) * pos

			pos = pos * 2

			cr:arc(l, tpos, ra, 0, pi2)
			cr:arc(r, tpos, ra, 0, pi2)
			cr:fill()

			cr:arc(l, m, ra, 0, pi2)
			cr:arc(r, m, ra, 0, pi2)
			cr:fill()

			cr:arc(l, bpos, ra, 0, pi2)
			cr:arc(r, bpos, ra, 0, pi2)
			cr:fill()

			cr:move_to(l + ra2, tpos)
			cr:line_to(r - ra2, tpos)

			cr:move_to(l + ra2, m)
			cr:line_to(r - ra2, m)

			cr:move_to(l + ra2, bpos)
			cr:line_to(r - ra2, bpos)

			cr:stroke()
		else
			pos = (pos - 0.5) * 2

			cr:move_to(l, m - (m - l) * pos)
			cr:line_to(r, m + (r - m) * pos)

			cr:move_to(l, m + (r - m) * pos)
			cr:line_to(r, m - (m - l) * pos)

			cr:stroke()
		end
	end
end

local function start()
    local on_color = helpers.color.hex_to_rgb(beautiful.random_accent_color())
    local off_color = helpers.color.hex_to_rgb(beautiful.colors.on_background)

    local widget = wibox.widget
    {

        forced_width = dpi(60),
		forced_height = dpi(60),
		draw = get_draw(0, off_color),
		fit = function(_, _, _, height) return height, height end,
		widget = wibox.widget.make_base_widget
	}

    local button = wibox.widget
    {
        widget = widgets.button.elevated.state,
        on_release = function()
            app_launcher:toggle()
        end,
        child = widget
    }

	local animation = helpers.animation:new
    {
        pos =
        {
            height = 0,
            color = off_color
        },
        easing = helpers.animation.easing.linear,
        duration = 0.2,
		update = function(self, pos)
			widget.draw = get_draw(pos.height, pos.color)
			widget:emit_signal("widget::redraw_needed")
		end
	}

    app_launcher:connect_signal("bling::app_launcher::visibility", function(self, visibility)
        if visibility == true then
            animation:set{height = 1, color = on_color}
        else
            animation:set{height = 0, color = off_color}
        end
    end)

    return button
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
        beautiful.icons.firefox,
        beautiful.icons.code,
        beautiful.icons.git,
        beautiful.icons.discord,
        beautiful.icons.spotify,
        beautiful.icons.steam,
        beautiful.icons.gamepad_alt,
        beautiful.icons.lights_holiday
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
                local button = wibox.widget
                {
                    widget = widgets.button.text.state,
                    id = "button",
                    icon = taglist_icons[index],
                    on_hover = function()
                        if #tag:clients() > 0 then
                            tag_preview:show(tag,
                            {
                                wibox = awful.screen.focused().left_wibar,
                                widget = self,
                                offset = { x = dpi(70), y = dpi(70) }
                            })
                        end
                    end,
                    on_leave = function()
                        tag_preview:hide()
                    end,
                    on_release = function(self, lx, ly, button, mods, find_widgets_result)
                        if button == 1 then
                            helpers.misc.tag_back_and_forth(tag.index)
                            tag_preview:hide()
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
                        bg = taglist_icons[index].color
                    }
                }

                local stack = wibox.widget
                {
                    widget = wibox.layout.stack,
                    button,
                    indicator
                }

                self.indicator_animation = helpers.animation:new
                {
                    duration = 0.125,
                    easing = helpers.animation.easing.linear,
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
local favorites = {}

local function favorite(layout, client, class)
    favorites[class] = true

    local menu = widgets.menu
    {
        widgets.menu.button
        {
            icon = client.font_icon,
            text = class,
            on_press = function() awful.spawn(client.command, false) end
        },
        widgets.menu.button
        {
            text = "Unpin from taskbar",
            on_press = function()
                favorites_daemon:remove_favorite({class = class})
            end
        },
    }

    local font_icon = beautiful.get_font_icon_for_app_name(class)

    local button = wibox.widget
    {
        widget = wibox.container.margin,
        margins = dpi(5),
        {
            widget = widgets.button.text.state,
            forced_width = dpi(65),
            forced_height = dpi(65),
            icon = font_icon,
            size = 20,
            on_release = function()
                menu:hide()
                awful.spawn(client.command, false)
            end,
            on_secondary_press = function(self)
                menu:toggle{
                    wibox = awful.screen.focused().top_wibar,
                    widget = self,
                    offset = { y = dpi(70) },
                }
            end
        }
    }

    favorites_daemon:connect_signal(class .. "::removed", function()
        layout:remove_widgets(button)
    end)

    capi.client.connect_signal("manage", function (c)
        if c.class == class then
            layout:remove_widgets(button)
            favorites[class] = nil
        end
    end)

    return button
end

local function client_task(favorites_layout, task_list, client)
    client.font_icon = beautiful.get_font_icon_for_app_name(client.class)
    local menu = widgets.client_menu(client)

    local button = wibox.widget
    {
        widget = wibox.container.margin,
        margins = dpi(5),
        {
            widget = widgets.button.text.state,
            id = "button",
            on_by_default = capi.client.focus == client,
            forced_width = dpi(65),
            forced_height = dpi(65),
            icon = client.font_icon,
            on_hover = function(self)
                task_preview:show(client,
                {
                    wibox = awful.screen.focused().top_wibar,
                    widget = self,
                    offset = { y = dpi(70) }
                })
            end,
            on_leave = function()
                task_preview:hide()
            end,
            on_release = function()
                task_preview:hide()
                menu:hide()

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
                menu:toggle{
                    wibox = awful.screen.focused().top_wibar,
                    widget = self,
                    offset = { y = dpi(70) },
                }
            end
        }
    }

    local indicator = wibox.widget
    {
        widget = wibox.container.place,
        valign = "bottom",
        {
            widget = wibox.container.background,
            id = "background",
            forced_width = capi.client.focus == client and dpi(50) or dpi(20),
            forced_height = dpi(5),
            shape = helpers.ui.rrect(beautiful.border_radius),
            bg = client.font_icon.color,
        }
    }

    local indicator_animation = helpers.animation:new
    {
		pos = capi.client.focus == client and dpi(50) or dpi(20),
        duration = 0.125,
        easing = helpers.animation.easing.linear,
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

    client:connect_signal("property::class", function()
        client.font_icon = beautiful.get_font_icon_for_app_name(client.class)
        button:set_icon(client.font_icon)
        indicator:set_bg(client.font_icon.color)
    end)

    client:connect_signal("focus", function()
        button:get_children_by_id("button")[1]:turn_on()
        indicator_animation:set(dpi(50))
    end)

    client:connect_signal("unfocus", function()
        button:get_children_by_id("button")[1]:turn_off()
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
        menu:hide()
        task_list:remove_widgets(widget)

        for _, c in ipairs(capi.client.get()) do
            if c.class == client.class then
                return
            end
        end

        local client_favorite = favorites_daemon:is_favorite(client.class)
        if client_favorite ~= nil and favorites[client.class] == nil then
            favorites_layout:add(favorite(favorites_layout, client_favorite, client.class))
        end
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
    local favorites = wibox.widget
    {
        layout = wibox.layout.flex.horizontal,
        spacing = dpi(15),
    }

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

    -- Wait a little bit so clients show at the correct order
    gtimer {
        timeout = 3.5,
        single_shot = true,
        call_now = false,
        autostart = true,
        callback = function()
            for _, c in ipairs(capi.client.get()) do
                client_task(favorites, task_list.children[c.first_tag.index], c)
            end

            capi.client.connect_signal("tagged", function(c, t)
                if c.current_task_list and c.current_task_widget then
                    c.current_task_list:remove_widgets(c.current_task_widget)
                    c.current_task_list = nil
                    c.current_task_widget = nil
                end

                if favorites_daemon:is_favorite(c.class) then
                    favorites:remove(c.favorite_widget)
                end

                client_task(favorites, task_list.children[t.index], c)
            end)
        end
    }

    for class, client in pairs(favorites_daemon:get_favorites()) do
        favorites:add(favorite(favorites, client, class))
    end

    return wibox.widget
    {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(20),
        favorites,
        task_list,
    }
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

    local system_tray_animation = helpers.animation:new
    {
        easing = helpers.animation.easing.linear,
        duration = 0.2,
        update = function(self, pos)
            system_tray.width = pos
        end
    }

    local arrow = wibox.widget
    {
        widget = wibox.container.margin,
        margins = dpi(5),
        {
            widget = widgets.button.text.state,
            forced_width = dpi(50),
            forced_height = dpi(50),
            icon = beautiful.icons.chevron_circle.left,
            on_turn_on = function(self)
                system_tray_animation:set(400)
                self:set_icon(beautiful.icons.chevron_circle.right)
            end,
            on_turn_off = function(self)
                system_tray_animation:set(0)
                self:set_icon(beautiful.icons.chevron_circle.left)
            end,
        }
    }

    return wibox.widget
    {
        layout = wibox.layout.fixed.horizontal,
        arrow,
        system_tray
    }
end

local function network()
    local widget = wibox.widget
    {
        widget = widgets.text,
        halign = "center",
        icon = beautiful.icons.network.wifi_off,
        size = 17,
    }

    network_daemon:connect_signal("wireless_state", function(self, state)
        if state then
            widget:set_icon(beautiful.icons.router)
        else
            widget:set_icon(beautiful.icons.network.wifi_off)
        end
    end)

    network_daemon:connect_signal("access_point::connected", function(self, ssid, strength)
        if strength < 33 then
            widget:set_icon(beautiful.icons.network.wifi_low)
        elseif strength >= 33 then
            widget:set_icon(beautiful.icons.network.wifi_medium)
        elseif strength >= 66 then
            widget:set_icon(beautiful.icons.network.wifi_high)
        end
    end)

    return widget
end

local function bluetooth()
    local widget = wibox.widget
    {
        widget = widgets.text,
        halign = "center",
        icon = beautiful.icons.bluetooth.on,
        size = 17,
    }

    bluetooth_daemon:connect_signal("state", function(self, state)
        if state == true then
            widget:set_icon(beautiful.icons.bluetooth.on)
        else
            widget:set_icon(beautiful.icons.bluetooth.off)
        end
    end)

    return widget
end

local function volume()
    local widget = wibox.widget
    {
        widget = widgets.text,
        halign = "center",
        icon = beautiful.icons.volume.normal,
        size = 17,
    }

    pactl_daemon:connect_signal("default_sinks_updated", function(self, device)
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

    local widget = wibox.widget
    {
        widget = wibox.container.margin,
        margins = dpi(5),
        {
            widget = widgets.button.elevated.state,
            id = "button",
            on_release = function()
                action_panel:toggle()
            end,
            child = layout
        }
    }

    action_panel:connect_signal("visibility", function(self, visibility)
        if visibility == true then
            widget:get_children_by_id("button")[1]:turn_on()
        else
            widget:get_children_by_id("button")[1]:turn_off()
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

    local widget = wibox.widget
    {
        widget = wibox.container.margin,
        margins = dpi(5),
        {
            widget = widgets.button.elevated.state,
            id = "button",
            on_release = function()
                info_panel:toggle()
            end,
            child = clock
        }
    }

    info_panel:connect_signal("visibility", function(self, visibility)
        if visibility == true then
            widget:get_children_by_id("button")[1]:turn_on()
        else
            widget:get_children_by_id("button")[1]:turn_off()
        end
    end)

    return widget
end

-- =============================================================================
--  Messages center button
-- =============================================================================
local function messages_button()
    local widget =  wibox.widget
    {
        widget = wibox.container.margin,
        margins = dpi(5),
        {
            widget = widgets.button.text.state,
            id = "button",
            forced_width = dpi(50),
            forced_height = dpi(50),
            icon = beautiful.icons.envelope,
            on_release = function()
                message_panel:toggle()
            end
        }
    }

    message_panel:connect_signal("visibility", function(self, visibility)
        if visibility == true then
            widget:get_children_by_id("button")[1]:turn_on()
        else
            widget:get_children_by_id("button")[1]:turn_off()
        end
    end)

    return widget
end

-- =============================================================================
--  Wibar
-- =============================================================================
capi.screen.connect_signal("request::desktop_decoration", function(s)
    -- Using popup instead of the wibar widget because it has some edge case bugs with detecting mouse input correctly
    s.top_wibar = awful.popup
    {
        screen = s,
        type = "dock",
        maximum_height = dpi(65),
        minimum_width = s.geometry.width,
        maximum_width = s.geometry.width,
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
        y = dpi(65),
        maximum_width = dpi(65),
        minimum_height = s.geometry.height,
        maximum_height = s.geometry.height,
        widget =
        {
            widget = wibox.container.margin,
            forced_width = dpi(65),
            tag_list(s)
        }
    }
    s.left_wibar:struts{left = dpi(65)}
end)