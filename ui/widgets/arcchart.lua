-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local setmetatable = setmetatable
local ipairs = ipairs
local capi = {
    awesome = awesome
}

local arcchart = {
    mt = {}
}

local function new()
    local widget = wibox.container.arcchart()

    capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
        widget._private.bg = old_colorscheme_to_new_map[widget._private.bg]
        for index, color in ipairs(widget._private.colors) do
            widget._private.colors[index] = old_colorscheme_to_new_map[color]
        end
    end)

    return widget
end

function arcchart.mt:__call(...)
    return new(...)
end

return setmetatable(arcchart, arcchart.mt)
