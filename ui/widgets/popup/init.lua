-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local beautiful = require("beautiful")
local setmetatable = setmetatable
local capi = {
    awesome = awesome
}

local popup = {
    mt = {}
}

local function new(args)
    local widget = awful.popup(args)

    capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
        widget.bg = beautiful.colors.background
        widget:emit_signal("widget::redraw_needed")
    end)

    return widget
end

function popup.mt:__call(...)
    return new(...)
end

return setmetatable(popup, popup.mt)
