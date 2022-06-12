-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local playerctl = { mt = {} }

local function new()
    return wibox.widget
    {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15),
        widgets.playerctl.art("left", "center", dpi(200), 150),
        {
            widget = wibox.container.margin,
            margins = { top = dpi(25) },
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(15),
                {
                    layout = wibox.layout.fixed.vertical,
                    spacing = dpi(10),
                    widgets.playerctl.title(),
                    widgets.playerctl.artist(),
                },
                {
                    layout = wibox.layout.fixed.vertical,
                    {
                        layout = wibox.layout.flex.horizontal,
                        spacing = dpi(15),
                        widgets.playerctl.shuffle(dpi(40), dpi(40)),
                        widgets.playerctl.previous(dpi(40), dpi(40)),
                        widgets.playerctl.play(),
                        widgets.playerctl.next(dpi(40), dpi(40)),
                        widgets.playerctl.loop(dpi(40), dpi(40))
                    },
                    widgets.playerctl.position_slider_length(dpi(170))
                }
            }
        },
    }
end

function playerctl.mt:__call()
    return new()
end

return setmetatable(playerctl, playerctl.mt)