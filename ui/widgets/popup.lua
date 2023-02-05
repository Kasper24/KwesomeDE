-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local setmetatable = setmetatable
local capi = {
    awesome = awesome
}

local background = {
    mt = {}
}

local function new(args)
    local widget = awful.popup(args)

    local bg = args.bg

    capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
        bg = old_colorscheme_to_new_map[bg]
        widget.bg = bg
    end)

    return widget
end

function background.mt:__call(...)
    return new(...)
end

return setmetatable(background, background.mt)
