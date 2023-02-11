-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local setmetatable = setmetatable
local capi = {
    awesome = awesome
}

local background = {
    mt = {}
}

local function new()
    local widget = wibox.container.background()

    local widget_bg = nil
    widget:connect_signal("property::bg", function(self, bg)
        widget_bg = bg
    end)

    capi.awesome.connect_signal("colorscheme::changed", function( old_colorscheme_to_new_map)
        widget.bg = old_colorscheme_to_new_map[widget_bg]
        widget:emit_signal("widget::redraw_needed")
    end)

    return widget
end

function background.mt:__call(...)
    return new(...)
end

return setmetatable(background, background.mt)
