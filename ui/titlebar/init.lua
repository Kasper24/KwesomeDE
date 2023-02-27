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
    local font_icon = wibox.widget {
        widget = widgets.client_font_icon,
        halign = "center",
        client = client,
        scale = 0.7,
        color = client.font_icon.color
    }

    local title = wibox.widget {
        widget = widgets.text,
        halign = "center",
        size = 12,
        text = client.name,
        color = beautiful.colors.on_background,
    }

    local minimize = wibox.widget {
        widget = widgets.button.elevated.state,
        forced_width = dpi(20),
        forced_height = dpi(20),
        normal_shape = gshape.isosceles_triangle,
        normal_bg = beautiful.colors.surface,
        on_normal_bg = client.font_icon.color,
        on_release = function(self)
            client.minimized = not client.minimized
        end
    }

    local maximize = wibox.widget {
        widget = widgets.button.elevated.state,
        forced_width = dpi(20),
        forced_height = dpi(20),
        normal_shape = function(cr, width, hegiht)
            gshape.rounded_rect(cr, width, hegiht, 5)
        end,
        normal_bg = beautiful.colors.surface,
        on_normal_bg = client.font_icon.color,
        on_release = function(self)
            client.maximized = not client.maximized
            client:raise()
        end
    }

    local close = wibox.widget {
        widget = widgets.button.elevated.state,
        forced_width = dpi(20),
        forced_height = dpi(20),
        normal_shape = gshape.circle,
        normal_bg = beautiful.colors.surface,
        on_normal_bg = client.font_icon.color,
        on_release = function()
            client:kill()
        end
    }

    client:connect_signal("focus", function()
        minimize:turn_on()
        maximize:turn_on()
        close:turn_on()
    end)

    client:connect_signal("unfocus", function()
        minimize:turn_off()
        maximize:turn_off()
        close:turn_off()
    end)

    local menu = widgets.client_menu(client)

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
                                menu:toggle{}
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
                font_icon,
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
                    margins = { right = 20 },
                    close
                }
            }
        }
    }

    capi.awesome.connect_signal("colorscheme::changed", function()
        titlebar:set_bg(beautiful.colors.background_no_opacity)
    end)
end)
