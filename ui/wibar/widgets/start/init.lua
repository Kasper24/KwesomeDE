-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local gcolor = require("gears.color")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local app_launcher = require("ui.popups.app_launcher")
local beautiful = require("beautiful")
local library = require("library")
local dpi = beautiful.xresources.apply_dpi
local pi = math.pi
local capi = {
    awesome = awesome
}

local start = {
    mt = {}
}

local function draw()
    return function(self, __, cr, ___, height)
        cr:set_source(gcolor(self.color))
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
        pi2 = pi * 2

        if self.pos <= 0.5 then

            local tpos = t + (m - t) * self.pos
            local bpos = b - (b - m) * self.pos

            self.pos = self.pos * 2

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
            self.pos = (self.pos - 0.5) * 2

            cr:move_to(l, m - (m - l) * self.pos)
            cr:line_to(r, m + (r - m) * self.pos)

            cr:move_to(l, m + (r - m) * self.pos)
            cr:line_to(r, m - (m - l) * self.pos)

            cr:stroke()
        end
    end
end

local function new()
    local widget = wibox.widget {
        widget = wibox.widget.make_base_widget,
        forced_width = dpi(45),
        forced_height = dpi(45),
        pos = 0,
        color = beautiful.colors.on_background,
        draw = draw(),
        fit = function(_, _, _, height)
            return height, height
        end,
    }

    local button = wibox.widget {
        widget = widgets.button.state,
        on_color = beautiful.colors.surface,
        on_release = function()
            app_launcher:toggle()
        end,
        widget
    }

    local animation = library.animation:new{
        pos = {
            height = 0,
        },
        easing = library.animation.easing.linear,
        duration = 0.2,
        update = function(self, pos)
            widget.pos = pos.height
            widget:emit_signal("widget::redraw_needed")
        end
    }

    app_launcher:connect_signal("visibility", function(self, visibility)
        if visibility == true then
            button:turn_on()
            animation:set{height = 1}
        else
            button:turn_off()
            animation:set{height = 0}
        end
    end)

    capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
        animation:stop()
        widget.color = old_colorscheme_to_new_map[beautiful.colors.on_background]
        widget:emit_signal("widget::redraw_needed")
    end)

    return button
end

function start.mt:__call()
    return new()
end

return setmetatable(start, start.mt)
