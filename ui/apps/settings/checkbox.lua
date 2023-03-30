-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local checkbox = {
    mt = {}
}

local function new(args)
    args = args or  {}

    local title = wibox.widget {
        widget = widgets.text,
        forced_width = dpi(200),
        size = 15,
        text = args.title
    }

    local widget = wibox.widget {
        widget = widgets.checkbox,
        state = args.state,
        handle_active_color = beautiful.icons.computer.color,
        on_turn_on = function()
            args.on_turn_on()
        end,
        on_turn_off = function()
            args.on_turn_off()
        end
    }

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_height = dpi(40),
        spacing = dpi(15),
        title,
        widget
    }
end

function checkbox.mt:__call(args)
    return new(args)
end

return setmetatable(checkbox, checkbox.mt)