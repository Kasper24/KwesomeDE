-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local picker = {
    mt = {}
}

local function new(args)
    args = args or {}

    local widget = wibox.widget {
        widget = widgets.picker,
        text_input_forced_width = dpi(400),
        type = args.type,
        initial_value = args.initial_value,
        on_changed = function(text)
            args.on_changed(text)
        end
    }

    SETTINGS_APP:connect_signal("tab::select", function()
        widget:get_text_input():unfocus()
    end)

    SETTINGS_APP:get_client():connect_signal("request::unmanage", function()
        widget:get_text_input():unfocus()
    end)

    SETTINGS_APP:get_client():connect_signal("mouse::leave", function()
        widget:get_text_input():unfocus()
    end)

    SETTINGS_APP:get_client():connect_signal("unfocus", function()
        widget:get_text_input():unfocus()
    end)

    return wibox.widget {
        layout = wibox.layout.align.horizontal,
        {
            widget = widgets.text,
            forced_width = dpi(200),
            size = 15,
            text = args.title,
        },
        widget
    }
end

function picker.mt:__call(args)
    return new(args)
end

return setmetatable(picker, picker.mt)