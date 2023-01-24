-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local lgi = require("lgi")
local Gdk = lgi.Gdk
local awful = require("awful")
local gsurface = require("gears.surface")
local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local floor = math.floor
local pairs = pairs
local capi = { client = client }

local function get_dominant_color(client)
    local color
    -- gsurface(client.content):write_to_png(
    --     "/home/mutex/nice/" .. client.class .. "_" .. client.instance .. ".png")
    local pb
    local bytes
    local tally = {}
    local content = gsurface(client.content)
    local cgeo = client:geometry()
    local x_offset = 2
    local y_offset = 2
    local x_lim = floor(cgeo.width / 2)
    for x_pos = 0, x_lim, 2 do
        for y_pos = 0, 8, 1 do
            pb = Gdk.pixbuf_get_from_surface(
                     content, x_offset + x_pos, y_offset + y_pos, 1, 1)
            bytes = pb:get_pixels()
            color = "#" ..
                        bytes:gsub(
                            ".",
                            function(c)
                        return ("%02x"):format(c:byte())
                    end)
            if not tally[color] then
                tally[color] = 1
            else
                tally[color] = tally[color] + 1
            end
        end
    end
    local mode
    local mode_c = 0
    for kolor, kount in pairs(tally) do
        if kount > mode_c then
            mode_c = kount
            mode = kolor
        end
    end
    color = mode
    return color
end

capi.client.connect_signal("request::titlebars", function(c)
    -- No clue why by minimizng only works if I do it via on_release?
    local minimize = widgets.button.text.normal
    {
        forced_width = dpi(40),
        forced_height = dpi(40),
        normal_bg = get_dominant_color(c),
        text_normal_bg = beautiful.colors.cyan,
        size = 12,
        font = beautiful.icons.triangle.font,
        text = beautiful.icons.triangle.icon,
        on_release = function(self)
            c.minimized = not c.minimized
        end
    }

    local maximize = widgets.button.text.normal
    {
        forced_width = dpi(40),
        forced_height = dpi(40),
        normal_bg = get_dominant_color(c),
        text_normal_bg = beautiful.colors.green,
        size = 12,
        font = beautiful.icons.square.font,
        text = beautiful.icons.square.icon,
        on_release = function(self)
            c.maximized = not c.maximized
            c:raise()
        end
    }

    local close = widgets.button.text.normal
    {
        forced_width = dpi(40),
        forced_height = dpi(40),
        normal_bg = get_dominant_color(c),
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

    awful.titlebar(c,
    {
        position = "top",
        size = dpi(35),
        bg_normal = get_dominant_color(c),
        bg_focus = get_dominant_color(c),
        bg_urgent = get_dominant_color(c),
        fg_normal = get_dominant_color(c),
        fg_focus = get_dominant_color(c),
        fg_urgent = get_dominant_color(c),
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