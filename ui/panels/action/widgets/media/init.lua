-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local media = {
    mt = {}
}

local function new()
    return wibox.widget {
        widget = widgets.background,
        forced_height = dpi(225),
        shape = helpers.ui.rrect(),
        {
            layout = wibox.layout.stack,
            widgets.playerctl.art_opacity(),
            {
                widget = wibox.container.margin,
                margins = dpi(20),
                {
                    layout = wibox.layout.align.vertical,
                    {
                        layout = wibox.layout.fixed.horizontal,
                        spacing = dpi(10),
                        widgets.playerctl.player_art("left"),
                        widgets.playerctl.player_name("left"),
                    },
                    {
                        widget = wibox.container.place,
                        halign = "left",
                        valign = "center",
                        {
                            layout = wibox.layout.fixed.horizontal,
                            spacing = dpi(200),
                            {
                                layout = wibox.layout.fixed.vertical,
                                spacing = dpi(10),
                                widgets.playerctl.title(dpi(200), "left"),
                                widgets.playerctl.artist(dpi(200), "left"),
                            },
                            widgets.playerctl.play()
                        }
                    },
                    {
                        layout = wibox.layout.fixed.horizontal,
                        forced_height = dpi(40),
                        spacing = dpi(10),
                        widgets.playerctl.previous(dpi(40), dpi(40)),
                        widgets.playerctl.position_slider_length(dpi(150)),
                        widgets.playerctl.next(dpi(40), dpi(40)),
                        widgets.playerctl.shuffle(dpi(40), dpi(40)),
                        widgets.playerctl.loop(dpi(40), dpi(40)),
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
