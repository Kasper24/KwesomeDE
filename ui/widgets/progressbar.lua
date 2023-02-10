-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local setmetatable = setmetatable
local capi = {
    awesome = awesome
}

local progressbar = {
    mt = {}
}

local function new()
    local widget = wibox.widget.progressbar()

    capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
        widget._private.background_color = old_colorscheme_to_new_map[widget._private.background_color]
        widget._private.color = old_colorscheme_to_new_map[widget._private.color]
    end)

    return widget
end

function progressbar.mt:__call(...)
    return new(...)
end

return setmetatable(progressbar, progressbar.mt)
