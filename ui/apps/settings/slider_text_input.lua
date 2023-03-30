-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local slider_text_input = {
    mt = {}
}

local function new(args)
    args = args or {}

    local title = wibox.widget {
        widget = widgets.text,
        forced_width = dpi(200),
        size = 15,
        text = args.name
    }

    local widget = widgets.slider_text_input {
        slider_width = dpi(400),
        round = args.round,
        minimum = args.minimum or 0,
        maximum = args.maximum,
        value = args.value,
        bar_active_color = beautiful.icons.computer.color,
        selection_bg = beautiful.icons.computer.color
    }

    widget:connect_signal("property::value", function(self, value, instant)
        args.on_changed(value)
    end)

    SETTINGS_APP:connect_signal("tab::select", function()
        widget:get_text_input():unfocus()
    end)

    SETTINGS_APP:get_client():connect_signal("request::unmanage", function()
        widget:get_text_input():unfocus()
    end)

    SETTINGS_APP:get_client():connect_signal("unfocus", function()
        widget:get_text_input():unfocus()
    end)

    SETTINGS_APP:get_client():connect_signal("mouse::leave", function()
        widget:get_text_input():unfocus()
    end)

    return wibox.widget {
        layout = wibox.layout.align.horizontal,
        title,
        widget
    }
end

function slider_text_input.mt:__call(args)
    return new(args)
end

return setmetatable(slider_text_input, slider_text_input.mt)