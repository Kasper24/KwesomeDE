-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local app_launcher = require("ui.popups.app_launcher")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local capi = {
    awesome = awesome
}

local start = {
    mt = {}
}

local function draw(pos, color)
    return function(_, _, cr, _, height)
        cr:set_source_rgb(color.r / 255, color.g / 255, color.b / 255)
        cr:set_line_width(0.1 * height)

        -- top, middle, bottom, left, right, radius, radius/2 pi*2
        local t, m, b, l, r, ra, ra2, pi2
        t = 0.3 * height
        m = 0.5 * height
        b = 0.7 * height
        l = 0.25 * height
        r = 0.75 * height
        ra = 0.05 * height
        ra2 = ra / 2
        pi2 = math.pi * 2

        if pos <= 0.5 then

            local tpos = t + (m - t) * pos
            local bpos = b - (b - m) * pos

            pos = pos * 2

            cr:arc(l, tpos, ra, 0, pi2)
            cr:arc(r, tpos, ra, 0, pi2)
            cr:fill()

            cr:arc(l, m, ra, 0, pi2)
            cr:arc(r, m, ra, 0, pi2)
            cr:fill()

            cr:arc(l, bpos, ra, 0, pi2)
            cr:arc(r, bpos, ra, 0, pi2)
            cr:fill()

            cr:move_to(l + ra2, tpos)
            cr:line_to(r - ra2, tpos)

            cr:move_to(l + ra2, m)
            cr:line_to(r - ra2, m)

            cr:move_to(l + ra2, bpos)
            cr:line_to(r - ra2, bpos)

            cr:stroke()
        else
            pos = (pos - 0.5) * 2

            cr:move_to(l, m - (m - l) * pos)
            cr:line_to(r, m + (r - m) * pos)

            cr:move_to(l, m + (r - m) * pos)
            cr:line_to(r, m - (m - l) * pos)

            cr:stroke()
        end
    end
end

local function new()
    local on_color = beautiful.colors.random_accent_color()
    local off_color = beautiful.colors.on_background

    local widget = wibox.widget {
        forced_width = dpi(45),
        forced_height = dpi(60),
        draw = draw(0, helpers.color.hex_to_rgb(off_color)),
        fit = function(_, _, _, height)
            return height, height
        end,
        widget = wibox.widget.make_base_widget
    }

    local button = wibox.widget {
        widget = widgets.button.elevated.state,
        on_release = function()
            app_launcher:toggle()
        end,
        child = widget
    }

    local animation = helpers.animation:new{
        pos = {
            height = 0,
            color = helpers.color.hex_to_rgb(off_color)
        },
        easing = helpers.animation.easing.linear,
        duration = 0.2,
        update = function(self, pos)
            widget.draw = draw(pos.height, pos.color)
            widget:emit_signal("widget::redraw_needed")
        end
    }

    app_launcher:connect_signal("bling::app_launcher::visibility", function(self, visibility)
        if visibility == true then
            animation:set{
                height = 1,
                color = helpers.color.hex_to_rgb(on_color)
            }
        else
            animation:set{
                height = 0,
                color = helpers.color.hex_to_rgb(off_color)
            }
        end
    end)

    capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
        on_color = old_colorscheme_to_new_map[on_color]
        off_color = old_colorscheme_to_new_map[off_color]
        local color = animation.pos.height == 1 and on_color or off_color
        widget.draw = draw(animation.pos.height, helpers.color.hex_to_rgb(color))
    end)

    return button
end

function start.mt:__call()
    return new()
end

return setmetatable(start, start.mt)