-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gshape = require("gears.shape")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local capi = {
    awesome = awesome,
    client = client
}

capi.client.connect_signal("request::titlebars", function(client)
    local icon = wibox.widget {
        widget = widgets.button.state,
        halign = "center",
        disabled = true,
        paddings = 0,
        on_by_default = capi.client.focus == client,
        color = beautiful.colors.transparent,
        on_color = beautiful.colors.transparent,
        {
            widget = widgets.icon,
            color = beautiful.colors.on_background,
            on_color = client._icon.color,
            icon = client._icon,
            size = 25,
        }
    }

    local title = wibox.widget {
        widget = widgets.text,
        halign = "center",
        size = 12,
        text = client.name,
        color = beautiful.colors.on_background,
    }

    local minimize = wibox.widget {
        widget = widgets.button.state,
        forced_width = dpi(20),
        forced_height = dpi(20),
        on_by_default = capi.client.focus == client,
        normal_shape = gshape.isosceles_triangle,
        color = beautiful.colors.surface,
        on_color = client._icon.color,
        on_release = function(self)
            client.minimized = not client.minimized
        end
    }

    local maximize = wibox.widget {
        widget = widgets.button.state,
        forced_width = dpi(20),
        forced_height = dpi(20),
        on_by_default = capi.client.focus == client,
        normal_shape = function(cr, width, hegiht)
            gshape.rounded_rect(cr, width, hegiht, 5)
        end,
        color = beautiful.colors.surface,
        on_color = client._icon.color,
        on_release = function(self)
            client.maximized = not client.maximized
            client:raise()
        end
    }

    local close = wibox.widget {
        widget = widgets.button.state,
        forced_width = dpi(20),
        forced_height = dpi(20),
        on_by_default = capi.client.focus == client,
        normal_shape = gshape.circle,
        color = beautiful.colors.surface,
        on_color = client._icon.color,
        on_release = function()
            client:kill()
        end
    }

    client:connect_signal("focus", function()
        icon:turn_on()
        minimize:turn_on()
        maximize:turn_on()
        close:turn_on()
    end)

    client:connect_signal("unfocus", function()
        icon:turn_off()
        minimize:turn_off()
        maximize:turn_off()
        close:turn_off()
    end)

    local titlebar = widgets.titlebar(client, {
        position = "top",
        size = dpi(35),
        bg = beautiful.colors.background_no_opacity,
    })
    titlebar:setup{
        layout = wibox.layout.align.horizontal,
        nil,
        {
            widget = wibox.container.place,
            halign = "center",
            buttons =
            {
                -- Move client
                awful.button {
                    modifiers = {},
                    button = 1,
                    on_press = function()
                        client.maximized = false
                        client:activate{
                            context = "mouse_click",
                            action = "mouse_move"
                        }
                    end
                },
                -- Kill client
                awful.button {
                    modifiers = {},
                    button = 2,
                    on_press = function()
                        client:kill()
                    end
                },
                -- Resize client
                awful.button {
                    modifiers = {},
                    button = 3,
                    on_press = function()
                        helpers.input.tap_or_drag {
                            on_tap = function()
                                client.menu:toggle{}
                            end,
                            on_drag = function()
                                client.maximized = false
                                client:activate{
                                    context = "mouse_click",
                                    action = "mouse_resize"
                                }
                            end
                        }
                    end
                },
                -- Side button up
                awful.button {
                    modifiers = {},
                    button = 9,
                    on_press = function()
                        client.floating = not client.floating
                    end
                },
                -- Side button down
                awful.button {
                    modifiers = {},
                    button = 8,
                    on_press = function()
                        client.ontop = not client.ontop
                    end
                }
            },
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(15),
                icon,
                title
            },
        },
        {
            widget = wibox.container.place,
            halign = "right",
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(15),
                minimize,
                maximize,
                {
                    widget = wibox.container.margin,
                    margins = { right = dpi(8) },
                    close
                }
            }
        }
    }

    capi.awesome.connect_signal("colorscheme::changed", function()
        titlebar:set_bg(beautiful.colors.background_no_opacity)
    end)
end)

require(... .. ".ncmpcpp")
