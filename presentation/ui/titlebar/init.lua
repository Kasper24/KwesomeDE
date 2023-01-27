-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local capi = { client = client }

capi.client.connect_signal("request::titlebars", function(c)
    local color  = helpers.client.get_dominant_color(c)

    -- No clue why by minimizng only works if I do it via on_release?
    local minimize = wibox.widget
    {
        widget = widgets.button.text.normal,
        forced_width = dpi(40),
        forced_height = dpi(40),
        normal_bg = color,
        text_normal_bg = beautiful.colors.cyan,
        size = 12,
        font = beautiful.icons.triangle.font,
        text = beautiful.icons.triangle.icon,
        on_release = function(self)
            c.minimized = not c.minimized
        end
    }

    local maximize = wibox.widget
    {
        widget = widgets.button.text.normal,
        forced_width = dpi(40),
        forced_height = dpi(40),
        normal_bg = color,
        text_normal_bg = beautiful.colors.green,
        size = 12,
        font = beautiful.icons.square.font,
        text = beautiful.icons.square.icon,
        on_release = function(self)
            c.maximized = not c.maximized
            c:raise()
        end
    }

    local close = wibox.widget
    {
        widget = widgets.button.text.normal,
        forced_width = dpi(40),
        forced_height = dpi(40),
        normal_bg = color,
        text_normal_bg = beautiful.colors.error,
        size = 12,
        font = beautiful.icons.circle.font,
        text = beautiful.icons.circle.icon,
        on_release = function()
            c:kill()
        end
    }

    c:connect_signal("focus", function()
        minimize:set_color(beautiful.colors.cyan)
        maximize:set_color(beautiful.colors.green)
        close:set_color(beautiful.colors.error)
    end)

    c:connect_signal("unfocus", function()
        minimize:set_color(beautiful.colors.surface)
        maximize:set_color(beautiful.colors.surface)
        close:set_color(beautiful.colors.surface)
    end)

    local menu = widgets.client_menu(c)

    awful.titlebar(c,
    {
        position = "top",
        size = dpi(35),
        bg_normal = color,
        bg_focus = color,
        bg_urgent = color,
        fg_normal = color,
        fg_focus = color,
        fg_urgent = color,
        font = beautiful.font_name .. 12
    }) : setup
    {
        layout = wibox.layout.align.horizontal,
        nil,
        {
            widget = awful.titlebar.widget.titlewidget(c),
            align = "center",
            font = beautiful.font_name .. 12,
            buttons =
            {
                -- Move client
                awful.button
                {
                    modifiers = {  },
                    button = 1,
                    on_press = function()
                        c.maximized = false
                        c:activate { context = "mouse_click", action = "mouse_move"  }
                    end,
                },

                -- Kill client
                awful.button
                {
                    modifiers = {  },
                    button = 2,
                    on_press = function()
                        c:kill()
                    end,
                },

                -- Resize client
                awful.button
                {
                    modifiers = {  },
                    button = 3,
                    on_press = function()
                        helpers.input.tap_or_drag
                        {on_tap = function()
                            menu:toggle{}
                        end,
                        on_drag = function()
                            c.maximized = false
                            c:activate { context = "mouse_click", action = "mouse_resize"}
                        end}
                    end,
                },

                -- Side button up
                awful.button
                {
                    modifiers = {  },
                    button = 9,
                    on_press = function()
                        c.floating = not c.floating
                    end,
                },

                -- Side button down
                awful.button
                {
                    modifiers = {  },
                    button = 8,
                    on_press = function()
                        c.ontop = not c.ontop
                    end,
                }
            }
        },
        {
            layout = wibox.layout.fixed.horizontal,
            minimize,
            maximize,
            close,
            widgets.spacer.horizontal(dpi(5)),
        }
    }
end)