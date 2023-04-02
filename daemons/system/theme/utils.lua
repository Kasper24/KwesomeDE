local gmath = require("gears.math")
local clip = require("helpers.math").clip
local Color = require("external.lua-color")
local remove = table.remove
local sqrt = math.sqrt
local huge = math.huge
local pow = math.pow

local utils = {}

function utils.blend(color1, color2)
    color1 = Color(color1)
    color2 = Color(color2)

    return tostring(Color {
        r = gmath.round(0.5 * color1.r + 0.5 * color2.r),
        g = gmath.round(0.5 * color1.g + 0.5 * color2.g),
        b = gmath.round(0.5 * color1.b + 0.5 * color2.b)
    })
end

function utils.saturate_color(color, amount)
    local h, s, v = Color(color):hsv()
    return tostring(Color {
        h = h,
        s = clip(amount, 0, 1),
        v = v
    })
end

function utils.alter_brightness(color, amount, sat)
    sat = sat or 0

    local h, s, l = Color(color):hsl()

    return tostring(Color {
        h = h,
        s = clip(s + sat, 0, 1),
        v = clip(l + amount, 0, 1)
    })
end

function utils.lighten(color, amount)
    color = Color(color)

    color.r = gmath.round(color.r + (255 - color.r) * amount)
    color.g = gmath.round(color.g + (255 - color.g) * amount)
    color.b = gmath.round(color.b + (255 - color.b) * amount)

    return tostring(color)
end

function utils.darken(color, amount)
    color = Color(color)

    color.r = gmath.round(color.r * (1 - amount))
    color.g = gmath.round(color.g * (1 - amount))
    color.b = gmath.round(color.b * (1 - amount))

    return tostring(color)
end

function utils.relative_luminance(color)
    local function from_sRGB(u)
        return u <= 0.0031308 and 25 * u / 323 or pow(((200 * u + 11) / 211), 12 / 5)
    end

    color = Color(color)

    return 0.2126 * from_sRGB(color.r) + 0.7152 * from_sRGB(color.g) + 0.0722 * from_sRGB(color.b)
end

function utils.contrast_ratio(fg, bg)
    return (utils.relative_luminance(fg) + 0.05) / (utils.relative_luminance(bg) + 0.05)
end

function utils.is_contrast_acceptable(fg, bg)
    return utils.contrast_ratio(fg, bg) >= 7 and true
end

function utils.distance(hex_src, hex_tgt)
    local color_1 = Color(hex_src)
    local color_2 = Color(hex_tgt)
    return sqrt((color_2.r - color_1.r) ^ 2 + (color_2.g - color_1.g) ^ 2 + (color_2.b - color_1.b) ^ 2)
end

function utils.closet_color(colors, reference)
    local minDistance = huge
    local closest
    local closestIndex

    for i, color in ipairs(colors) do
        local d = utils.distance(color, reference)
        if d < minDistance then
            minDistance = d
            closest = color
            closestIndex = i
        end
    end

    remove(colors, closestIndex)

    return closest
end

return utils