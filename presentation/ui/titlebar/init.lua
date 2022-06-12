-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local capi = { client = client }

capi.client.connect_signal("request::titlebars", function(c)
    -- No clue why by minimizng only works if I do it via on_release?
    local minimize = widgets.button.text.normal
    {
        forced_width = dpi(40),
        forced_height = dpi(40),
        text_normal_bg = beautiful.colors.cyan,
        size = 12,
        font = beautiful.triangle_icon.font,
        text = beautiful.triangle_icon.icon,
        on_release = function(self)
            c.minimized = not c.minimized
        end
    }

    local maximize = widgets.button.text.normal
    {
        forced_width = dpi(40),
        forced_height = dpi(40),
        text_normal_bg = beautiful.colors.green,
        size = 12,
        font = beautiful.square_icon.font,
        text = beautiful.square_icon.icon,
        on_release = function(self)
            c.maximized = not c.maximized
            c:raise()
        end
    }

    local close = widgets.button.text.normal
    {
        forced_width = dpi(40),
        forced_height = dpi(40),
        text_normal_bg = beautiful.colors.error,
        size = 12,
        font = beautiful.circle_icon.font,
        text = beautiful.circle_icon.icon,
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

    awful.titlebar(c,
    {
        position = "top",
        size = dpi(35),
        bg_normal = beautiful.colors.background,
        bg_focus = beautiful.colors.background,
        bg_urgent = beautiful.colors.background,
        fg_normal = beautiful.colors.on_background,
        fg_focus = beautiful.colors.on_background,
        fg_urgent = beautiful.colors.on_background,
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
                        c.maximized = false
                        c:activate { context = "mouse_click", action = "mouse_resize"}
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

require(... .. ".ncmpcpp")