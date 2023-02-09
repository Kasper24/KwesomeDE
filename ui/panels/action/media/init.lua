-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local cairo = require("lgi").cairo
local gsurface = require("gears.surface")
local gcolor = require("gears.color")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local playerctl_daemon = require("daemons.system.playerctl")
local theme_daemmon = require("daemons.system.theme")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local media = {
    mt = {}
}

local function crop_surface(ratio, surf)
    local old_w, old_h = gsurface.get_size(surf)
    local old_ratio = old_w/old_h

    if old_ratio == ratio then return surf end

    local new_h = old_h
    local new_w = old_w
    local offset_h, offset_w = 0, 0
    -- quick mafs
    if (old_ratio < ratio) then
        new_h = old_w * (1/ratio)
        offset_h = (old_h - new_h)/2
    else
        new_w = old_h * ratio
        offset_w = (old_w - new_w)/2
    end

    local out_surf = cairo.ImageSurface(cairo.Format.ARGB32, new_w, new_h)
    local cr = cairo.Context(out_surf)
    cr:set_source_surface(surf, -offset_w, -offset_h)
    cr.operator = cairo.Operator.SOURCE
    cr:paint()

    return out_surf
end

local function image_with_gradient(image)
    local in_surf = gsurface.load_uncached(image)
    local surf = crop_surface(2, in_surf)

    local cr = cairo.Context(surf)
    local w, h = gsurface.get_size(surf)
    cr:rectangle(0, 0, w, h)

    local pat_h = cairo.Pattern.create_linear(0, 0, w, 0)
    pat_h:add_color_stop_rgba(0 ,gcolor.parse_color(beautiful.colors.background))
    pat_h:add_color_stop_rgba(0.3 ,gcolor.parse_color(beautiful.colors.background .. "CC"))
    pat_h:add_color_stop_rgba(0.7 ,gcolor.parse_color(beautiful.colors.background .. "BB"))
    pat_h:add_color_stop_rgba(1 ,gcolor.parse_color(beautiful.colors.background .. "99"))
    cr:set_source(pat_h)
    cr:fill()

    return surf
end

local function art()
    local art = wibox.widget{
        widget = wibox.widget.imagebox,
        opacity = 0.6,
        horizontal_fit_policy = "fit",
        vertical_fit_policy = "fit",
        image = image_with_gradient(theme_daemmon:get_wallpaper()),
    }

    playerctl_daemon:connect_signal("metadata", function(_, title, artist, album_path, _, new, player_name)
        if album_path ~= "" then
            art.image = image_with_gradient(album_path)
        else
            art.image = image_with_gradient(theme_daemmon:get_wallpaper())
        end
    end)

    playerctl_daemon:connect_signal("no_players", function()
        art.image = image_with_gradient(theme_daemmon:get_wallpaper())
    end)

    return wibox.widget {
        layout = wibox.layout.stack,
        art,
        -- {
        --     widget = widgets.background,
        --     bg = beautiful.colors.background,
        --     opacity = 0.8
        -- },
    }
end

local function new()
    return wibox.widget {
        widget = widgets.background,
        forced_height = dpi(225),
        shape = helpers.ui.rrect(beautiful.border_radius),
        bg = beautiful.colors.background,
        {
            layout = wibox.layout.stack,
            art(),
            {
                widget = wibox.container.margin,
                margins = dpi(20),
                {
                    layout = wibox.layout.fixed.vertical,
                    spacing = dpi(10),
                    {
                        layout = wibox.layout.fixed.vertical,
                        spacing = dpi(10),
                        {
                            layout = wibox.layout.fixed.horizontal,
                            spacing = dpi(10),
                            widgets.playerctl.player_art("left"),
                            widgets.playerctl.player_name("left"),
                        },
                        widgets.playerctl.title(dpi(70), "center"),
                        widgets.playerctl.artist(dpi(70), "center"),
                    },
                    {
                        widget = wibox.container.place,
                        forced_height = dpi(25),
                        halign = "center",
                        widgets.playerctl.position_slider_length(dpi(170)),
                    },
                    {
                        widget = wibox.container.place,
                        halign = "center",
                        valign = "bottom",
                        {
                            layout = wibox.layout.fixed.horizontal,
                            spacing = dpi(15),
                            widgets.playerctl.shuffle(dpi(40), dpi(40)),
                            widgets.playerctl.previous(dpi(40), dpi(40)),
                            widgets.playerctl.play(),
                            widgets.playerctl.next(dpi(40), dpi(40)),
                            widgets.playerctl.loop(dpi(40), dpi(40)),
                        }
                    },
                },
            },
        },
    }

    -- return wibox.widget {
    --     layout = wibox.layout.fixed.horizontal,
    --     spacing = dpi(15),
    --     widgets.playerctl.art("left", "center", dpi(200), 150),
    --     {
    --         widget = wibox.container.margin,
    --         margins = {
    --             top = dpi(25)
    --         },
    --         {
    --             layout = wibox.layout.fixed.vertical,
    --             spacing = dpi(15),
    --             {
    --                 layout = wibox.layout.fixed.vertical,
    --                 spacing = dpi(10),
    --                 widgets.playerctl.title(),
    --                 widgets.playerctl.artist()
    --             },
    --             {
    --                 layout = wibox.layout.fixed.vertical,
    --                 {
    --                     layout = wibox.layout.flex.horizontal,
    --                     spacing = dpi(15),
    --                     widgets.playerctl.shuffle(dpi(40), dpi(40)),
    --                     widgets.playerctl.previous(dpi(40), dpi(40)),
    --                     widgets.playerctl.play(),
    --                     widgets.playerctl.next(dpi(40), dpi(40)),
    --                     widgets.playerctl.loop(dpi(40), dpi(40))
    --                 },
    --                 widgets.playerctl.position_slider_length(dpi(170))
    --             }
    --         }
    --     }
    -- }
end

function media.mt:__call()
    return new()
end

return setmetatable(media, media.mt)
