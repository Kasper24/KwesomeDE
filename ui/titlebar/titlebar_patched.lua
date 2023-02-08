-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local setmetatable = setmetatable

local titlebar = {
    mt = {}
}

local function new(c, args)
    local widget = awful.titlebar(c, args)

    c.titlebar = widget
    c.titlebar_size = args.size

    return widget
end

function titlebar.mt:__call(...)
    return new(...)
end

return setmetatable(titlebar, titlebar.mt)