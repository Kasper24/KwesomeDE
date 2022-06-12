-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local wibox = require("wibox")
local twidget = require("presentation.ui.widgets.text")

local setmetatable = setmetatable

local spacer = { }

function spacer.text(amount)
    local str = ""
    for i = 1, amount do str = str .. " " end

    return twidget
    {
        text = str,
    }
end

function spacer.horizontal(amount)
    return wibox.widget
    {
        layout = wibox.layout.fixed.horizontal,
        forced_width = amount,
    }
end

function spacer.vertical(amount)
    return wibox.widget
    {
        layout = wibox.layout.fixed.vertical,
        forced_height = amount,
    }
end

return setmetatable(spacer, spacer.mt)