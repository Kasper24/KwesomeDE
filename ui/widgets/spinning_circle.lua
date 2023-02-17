-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gtable = require("gears.table")
local wibox = require("wibox")
local acwidget = require("ui.widgets.arcchart")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local spinning_circle = {
    mt = {}
}

function spinning_circle:start()
    self._private.anim:set()
end

function spinning_circle:stop()
    self._private.anim:stop()
end

local function new(args)
    args = args or {}

    args.forced_width = args.forced_width or nil
    args.forced_height = args.forced_height or nil
    args.thickness = args.thickness or dpi(30)
    args.run_by_default = args.run_by_default

    local widget = wibox.widget {
        widget = wibox.container.place,
        halign = "center",
        valign = "center",
        {
            widget = acwidget,
            id = "spinning_circle",
            forced_width = args.forced_width,
            forced_height = args.forced_height,
            max_value = 100,
            min_value = 0,
            value = 30,
            thickness = args.thickness,
            rounded_edge = true,
            bg = beautiful.colors.surface,
            colors = {
                beautiful.colors.random_accent_color()
            }
        }
    }
    gtable.crush(widget, spinning_circle, true)

    local spinning_circle = widget:get_children_by_id("spinning_circle")[1]

    widget._private.anim = helpers.animation:new{
        target = 100,
        duration = 10,
        easing = helpers.animation.easing.linear,
        loop = true,
        update = function(self, pos)
            spinning_circle.start_angle = pos
        end
    }

    if args.run_by_default == true or args.run_by_default == nil then
        widget._private.anim:set()
    end

    return widget
end

function spinning_circle.mt:__call(...)
    return new(...)
end

return setmetatable(spinning_circle, spinning_circle.mt)
