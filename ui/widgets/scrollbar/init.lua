-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local wibox = require("wibox")
local beautiful = require("beautiful")
local library = require("library")
local setmetatable = setmetatable
local capi = {
    awesome = awesome
}

local scrollbar = {
    mt = {}
}

local function new()
    local widget = wibox.widget {
        widget = wibox.widget.separator,
        shape = library.ui.rrect(),
        color = beautiful.colors.on_background
    }

    capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
        widget.color = beautiful.colors.on_background
    end)

    return widget
end

function scrollbar.mt:__call(...)
    return new()
end

return setmetatable(scrollbar, scrollbar.mt)
