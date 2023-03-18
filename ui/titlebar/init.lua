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
        widget = widgets.button.text.state,
        halign = "center",
        disabled = true,
        paddings = 0,
        on_by_default = capi.client.focus == client,
        icon = client.font_icon,
        scale = 0.7,
        normal_bg = beautiful.colors.background,
        on_normal_bg = beautiful.colors.background,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = client.font_icon.color,
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
        on_by_default = capi.client.focus == client,
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
        on_by_default = capi.client.focus == client,
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
        on_by_default = capi.client.focus == client,
        normal_shape = gshape.circle,
        normal_bg = beautiful.colors.surface,
        on_normal_bg = client.font_icon.color,
        on_release = function()
            client:kill()
        end
    }

    client:connect_signal("focus", function()
        font_icon:turn_on()
        minimize:turn_on()
        maximize:turn_on()
        close:turn_on()
    end)

    client:connect_signal("unfocus", function()
        font_icon:turn_off()
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

require(... .. ".ncmpcpp")