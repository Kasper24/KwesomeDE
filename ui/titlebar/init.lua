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

capi.client.connect_signal("request::titlebars", function(c)
    local color = helpers.client.get_dominant_color(c)

    -- No clue why by minimizng only works if I do it via on_release?
    local minimize = wibox.widget {
        widget = widgets.button.elevated.normal,
        forced_width = dpi(20),
        forced_height = dpi(20),
        normal_shape = gshape.isosceles_triangle,
        normal_bg = c.font_icon.color,
        hover_bg = beautiful.colors.on_background,
        press_bg = beautiful.colors.on_background,
        on_release = function(self)
            c.minimized = not c.minimized
        end
    }

    local maximize = wibox.widget {
        widget = widgets.button.elevated.normal,
        forced_width = dpi(20),
        forced_height = dpi(20),
        normal_shape = helpers.ui.rrect(beautiful.border_radius / 2),
        normal_bg = c.font_icon.color,
        hover_bg = beautiful.colors.on_background,
        press_bg = beautiful.colors.on_background,
        on_release = function(self)
            c.maximized = not c.maximized
            c:raise()
        end
    }

    local close = wibox.widget {
        widget = widgets.button.elevated.normal,
        forced_width = dpi(20),
        forced_height = dpi(20),
        normal_shape = gshape.circle,
        normal_bg = c.font_icon.color,
        hover_bg = beautiful.colors.on_background,
        press_bg = beautiful.colors.on_background,
        on_release = function()
            c:kill()
        end
    }

    c:connect_signal("focus", function()
        minimize:set_normal_bg(c.font_icon.color)
        maximize:set_normal_bg(c.font_icon.color)
        close:set_normal_bg(c.font_icon.color)
    end)

    c:connect_signal("unfocus", function()
        minimize:set_normal_bg(beautiful.colors.surface)
        maximize:set_normal_bg(beautiful.colors.surface)
        close:set_normal_bg(beautiful.colors.surface)
    end)

    c:connect_signal("property::font_icon", function()
        if c.active then
            minimize:set_normal_bg(c.font_icon.color)
            maximize:set_normal_bg(c.font_icon.color)
            close:set_normal_bg(c.font_icon.color)
        else
            minimize:set_normal_bg(beautiful.colors.surface)
            maximize:set_normal_bg(beautiful.colors.surface)
            close:set_normal_bg(beautiful.colors.surface)
        end
    end)

    local menu = widgets.client_menu(c)

    local titlebar = widgets.titlebar(c, {
        position = "top",
        size = dpi(35),
        bg = color,
        font = beautiful.font_name .. 12
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
                        c.maximized = false
                        c:activate{
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
                        c:kill()
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
                                c.maximized = false
                                c:activate{
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
                        c.floating = not c.floating
                    end
                },
                -- Side button down
                awful.button {
                    modifiers = {},
                    button = 8,
                    on_press = function()
                        c.ontop = not c.ontop
                    end
                }
            },
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(15),
                {
                    widget = widgets.client_font_icon,
                    halign = "center",
                    client = c,
                    scale = 0.8
                },
                {
                    widget = widgets.text,
                    halign = "center",
                    size = 12,
                    text = c.name,
                    color = beautiful.colors.on_background,
                }
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
                close,
                widgets.spacer.horizontal(dpi(5))
            }
        }
    }

    capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
        titlebar:set_bg(helpers.client.get_dominant_color(c))
    end)
end)
