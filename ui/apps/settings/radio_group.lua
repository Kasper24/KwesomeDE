-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local radio_group = {
    mt = {}
}

local function new(args)
    args = args or {}

    local title = wibox.widget {
        widget = widgets.text,
        size = 15,
        text = args.title
    }

    local widget = wibox.widget {
        widget = widgets.radio_group.vertical,
        on_select = function(id)
            args.on_select(id)
        end,
        values = args.values
    }

    return wibox.widget {
        layout = wibox.layout.fixed.vertical,
        forced_height = args.forced_height,
        spacing = dpi(15),
        title,
        widget
    }
end

function radio_group.mt:__call(args)
    return new(args)
end

return setmetatable(radio_group, radio_group.mt)