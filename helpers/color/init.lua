local Color = require("external.lua-color")
local clip = require("helpers.math").clip
local format = string.format
local floor = math.floor
local remove = table.remove
local sqrt = math.sqrt
local huge = math.huge
local pow = math.pow

local _color = {}

function _color.is_dark(color)
    local _, __, l = Color(color):hsl()
    return l <= 0.2
end

function _color.darken_or_lighten(color, amount)
    if _color.is_dark(color) then
        _color.lighten(color, amount)
    else
        _color.darken(color, amount)
    end
end

function _color.lighten(color, amount)
    local h, s, l = Color(color):hsl()
    return tostring(Color {
        h = h,
        s = s,
        l = clip(l + amount, 0, 1)
    })
end

function _color.darken(color, amount)
    local h, s, l = Color(color):hsl()
    return tostring(Color {
        h = h,
        s = s,
        l = clip(l - amount, 0, 1)
    })
end

function _color.change_saturation(color, saturation)
    local h, _, l = Color(color):hsl()
    return tostring(Color {
        h = h,
        s = clip(saturation, 0, 1),
        l = l
    })
end

function _color.saturate(color, saturation)
    local h, s, l = Color(color):hsl()
    return tostring(Color {
        h = h,
        s = clip(s + saturation, 0, 1),
        l = l
    })
end

function _color.change_opacity(color, opacity)
    local r, g, b, _ = Color(color):rgba()
    return tostring(Color {
        r = r,
        g = g,
        b = b,
        a = clip(opacity, 0, 1)
    })
end

function _color.blend(color, color2, amount)
    return tostring(Color(color):mix(Color(color2), amount or 0.5))
end

function _color.relative_luminance(color)
    local function from_sRGB(u)
        return u <= 0.0031308 and 25 * u / 323 or pow(((200 * u + 11) / 211), 12 / 5)
    end

    color = Color(color)

    return 0.2126 * from_sRGB(color.r) + 0.7152 * from_sRGB(color.g) + 0.0722 * from_sRGB(color.b)
end

function _color.contrast_ratio(fg, bg)
    return (_color.relative_luminance(fg) + 0.05) / (_color.relative_luminance(bg) + 0.05)
end

function _color.is_contrast_acceptable(fg, bg)
    return _color.contrast_ratio(fg, bg) >= 7 and true
end

function _color.distance(hex_src, hex_tgt)
    local color_1 = Color(hex_src)
    local color_2 = Color(hex_tgt)
    return sqrt((color_2.r - color_1.r) ^ 2 + (color_2.g - color_1.g) ^ 2 + (color_2.b - color_1.b) ^ 2)
end

function _color.closet_color(colors, reference)
    local minDistance = huge
    local closest
    local closestIndex

    for i, color in ipairs(colors) do
        local d = _color.distance(color, reference)
        if d < minDistance then
            minDistance = d
            closest = color
            closestIndex = i
        end
    end

    remove(colors, closestIndex)

    return closest
end

return _color
