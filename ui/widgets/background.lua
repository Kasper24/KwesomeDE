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

    function widget:set_normal_bg(normal_bg)
        self._private.normal_bg = normal_bg
    end
    function widget:set_on_normal_bg(on_normal_bg)
        self._private.on_normal_bg = on_normal_bg
    end

    capi.awesome.connect_signal("colorscheme::changed", function( old_colorscheme_to_new_map)
        widget.bg = old_colorscheme_to_new_map[widget_bg]
        widget.border_color = old_colorscheme_to_new_map[widget.border_color]
        widget:emit_signal("widget::redraw_needed")
    end)

    return widget
end

function background.mt:__call(...)
    return new(...)
end

return setmetatable(background, background.mt)
