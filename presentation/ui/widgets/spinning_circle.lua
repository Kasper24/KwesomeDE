-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local gtable = require("gears.table")
local wibox = require("wibox")
local beautiful = require("beautiful")
local animation = require("services.animation")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local spinning_circle = { mt = {} }

function spinning_circle:start()
    self._private.anim:start()
end

function spinning_circle:abort()
    self._private.anim:stop()
end

local function new(args)
    args = args or {}

    args.forced_width = args.forced_width or nil
    args.forced_height = args.forced_height or nil
    args.thickness = args.thickness or dpi(30)

    local widget = wibox.widget
    {
        widget = wibox.container.arcchart,
        forced_width = args.forced_width,
        forced_height =  args.forced_height,
        max_value = 100,
        min_value = 0,
        value = 30,
        thickness = args.thickness,
        rounded_edge = true,
        bg = beautiful.colors.surface,
        colors =
        {
            {
                type = "linear",
                from = {0, 0},
                to = {400, 400},
                stops = {{0, beautiful.random_accent_color()}, {0.2, beautiful.random_accent_color()}, {0.4, beautiful.random_accent_color()}, {0.6, beautiful.random_accent_color()}, {0.8, beautiful.random_accent_color()}}
            }
        },
    }
    gtable.crush(widget, spinning_circle, true)

    widget._private.anim = animation:new
    {
        target = 100,
        duration = 10,
        easing = animation.easing.linear,
        loop = true,
        update = function(self, pos)
            widget.start_angle = pos
        end
    }

    widget._private.anim:start()

    return widget
end

function spinning_circle.mt:__call(...)
    return new(...)
end

return setmetatable(spinning_circle, spinning_circle.mt)