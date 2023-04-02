local Color = require("external.lua-color")
local format = string.format
local floor = math.floor

local _color = {}

function _color.is_dark(color)
    local _, __, l = Color(color):hsl()

    return l <= 0.4
end

function _color.darken_or_lighten(color, amount)
    if _color.is_dark(color) then
        _color.lighten(color, amount)
    else
        _color.darken(color, amount)
    end
end

function _color.lighten(color, amount)
    amount = amount or 0

    local h, s, l = Color(color):hsl()
    return tostring(Color {
        h = h,
        s = s,
        l = l + amount
    })
end

function _color.darken(color, amount)
    amount = amount or 0

    local h, s, l = Color(color):hsl()
    return tostring(Color {
        h = h,
        s = s,
        l = l - amount
    })
end

function _color.change_opacity(color, opacity)
    opacity = opacity or 1
    return color .. format("%x", floor(opacity * 255))
end

return _color
