-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local gtable = require("gears.table")
local iwidget = require("ui.widgets.icon")
local setmetatable = setmetatable

local client_icon = {
    mt = {}
}

function client_icon:set_client(client)
    self:set_icon(client._icon)
end

local function new()
    local widget = iwidget()
    gtable.crush(widget, client_icon, true)

    return widget
end

function client_icon.mt:__call(...)
    return new()
end

return setmetatable(client_icon, client_icon.mt)
