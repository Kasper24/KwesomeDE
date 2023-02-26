-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gtable = require("gears.table")
local twidget = require("ui.widgets.text")
local setmetatable = setmetatable

local client_font_icon = {
    mt = {}
}

function client_font_icon:set_client(client)
    self:set_icon(client.font_icon)
end

local function new()
    local widget = twidget()
    gtable.crush(widget, client_font_icon, true)

    return widget
end

function client_font_icon.mt:__call(...)
    return new(...)
end

return setmetatable(client_font_icon, client_font_icon.mt)
