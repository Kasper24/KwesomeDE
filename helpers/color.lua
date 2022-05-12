local tonumber = tonumber
local string = string
local math = math
local type = type
local floor = math.floor
local max = math.max
local min = math.min
local pow = math.pow
local random = math.random
local abs = math.abs
local format = string.format

local _color = {}

local function round(x, p)
    local power = 10 ^ (p or 0)
    return (x * power + 0.5 - (x * power + 0.5) % 1) / power
end

-- Returns a value that is clipped to interval edges if it falls outside the interval
local function clip(num, min_num, max_num)
    return max(min(num, max_num), min_num)
end

-- Converts the given hex color to rgba
function _color.hex2rgb(color)
    color = color:gsub("#", "")
    return { r = tonumber("0x" .. color:sub(1, 2)),
             g = tonumber("0x" .. color:sub(3, 4)),
             b = tonumber("0x" .. color:sub(5, 6)),
             a = #color == 8 and tonumber("0x" .. color:sub(7, 8)) or 255 }
end

-- Converts the given rgba color to hex
function _color.rgb2hex(color)
	local r = clip(color.r or color[1], 0, 255)
	local g = clip(color.g or color[2], 0, 255)
	local b = clip(color.b or color[3], 0, 255)
	local a = clip(color.a or color[4] or 255, 0, 255)
	return "#" .. format("%02x%02x%02x%02x",
			floor(r),
			floor(g),
			floor(b),
            floor(a))
end

-- Converts the given hex color to hsv
function _color.hex2hsv(color)
    local color = _color.hex2rgb(color)
    local C_max = max(color.r, color.g, color.b)
    local C_min = min(color.r, color.g, color.b)
    local delta = C_max - C_min
    local H, S, V
    if delta == 0 then
        H = 0
    elseif C_max == color.r then
        H = 60 * (((color.g - color.b) / delta) % 6)
    elseif C_max == color.g then
        H = 60 * (((color.b - color.r) / delta) + 2)
    elseif C_max == color.b then
        H = 60 * (((color.r - color.g) / delta) + 4)
    end
    if C_max == 0 then
        S = 0
    else
        S = delta / C_max
    end
    V = C_max

    return { h = H,
             s = S * 100,
             v = V * 100 }
end

-- Converts the given hex color to hsl
function _color.hex2hsl(color)
    return _color.rgb2hsl(_color.hex2rgb(color))
end

-- Converts the given rgb color to hsl
function _color.rgb2hsl(color)
	local r = color.r or color[1]
	local g = color.g or color[2]
	local b = color.b or color[3]

	local R, G, B = r / 255, g / 255, b / 255
	local max, min = math.max(R, G, B), math.min(R, G, B)
	local l, s, h

	-- Get luminance
	l = (max + min) / 2

	-- short circuit saturation and hue if it's grey to prevent divide by 0
	if max == min then
		s = 0
		h = color.h or color[4] or 0
		return
	end

	-- Get saturation
	if l <= 0.5 then s = (max - min) / (max + min)
	else s = (max - min) / (2 - max - min)
	end

	-- Get hue
	if max == R then h = (G - B) / (max - min) * 60
	elseif max == G then h = (2.0 + (B - R) / (max - min)) * 60
	else h = (4.0 + (R - G) / (max - min)) * 60
	end

	-- Make sure it goes around if it's negative (hue is a circle)
	if h ~= 360 then h = h % 360 end

	return { h = h, s = s, l = l }
end

-- Converts the given hsl color to rgb
function _color.hsl2rgb(color)
	local h = color.h or color[1]
	local s = color.s or color[2]
	local l = color.l or color[3]

	local temp1, temp2, temp_r, temp_g, temp_b, temp_h

	-- Set the temp variables
	if l <= 0.5 then temp1 = l * (s + 1)
	else temp1 = l + s - l * s
	end

	temp2 = l * 2 - temp1

	temp_h = h / 360

	temp_r = temp_h + 1/3
	temp_g = temp_h
	temp_b = temp_h - 1/3

	-- Make sure it's between 0 and 1
	if temp_r ~= 1 then temp_r = temp_r % 1 end
	if temp_g ~= 1 then temp_g = temp_g % 1 end
	if temp_b ~= 1 then temp_b = temp_b % 1 end

	local rgb = {}

	-- Bunch of tests
	-- Once again I haven't the foggiest what any of this does
	for _, v in pairs({{temp_r, "r"}, {temp_g, "g"}, {temp_b, "b"}}) do

		if v[1] * 6 < 1 then rgb[v[2]] = temp2 + (temp1 - temp2) * v[1] * 6
		elseif v[1] * 2 < 1 then rgb[v[2]] = temp1
		elseif v[1] * 3 < 2 then rgb[v[2]] = temp2 + (temp1 - temp2) * (2/3 - v[1]) * 6
		else rgb[v[2]] = temp2
		end

	end

	return {
        r = round(rgb.r * 255),
        g = round(rgb.g * 255),
		b = round(rgb.b * 255)
    }
end

-- Converts the given hsl color to hex
function _color.hsl2hex(color)
    return _color.rgb2hex(_color.hsl2rgb(color))
end

-- Converts the given hsv color to hex
function _color.hsv2hex(H, S, V)
    S = S / 100
    V = V / 100
    if H > 360 then H = 360 end
    if H < 0 then H = 0 end
    local C = V * S
    local X = C * (1 - abs(((H / 60) % 2) - 1))
    local m = V - C
    local r_, g_, b_ = 0, 0, 0
    if H >= 0 and H < 60 then
        r_, g_, b_ = C, X, 0
    elseif H >= 60 and H < 120 then
        r_, g_, b_ = X, C, 0
    elseif H >= 120 and H < 180 then
        r_, g_, b_ = 0, C, X
    elseif H >= 180 and H < 240 then
        r_, g_, b_ = 0, X, C
    elseif H >= 240 and H < 300 then
        r_, g_, b_ = X, 0, C
    elseif H >= 300 and H < 360 then
        r_, g_, b_ = C, 0, X
    end
    local r, g, b = (r_ + m) * 255, (g_ + m) * 255, (b_ + m) * 255
    return ("#%02x%02x%02x"):format(floor(r), floor(g), floor(b))
end

--- Try to guess if a color is dark or light.
function _color.is_dark(color)
    if type(color) == "table" then
        color = _color.rgb2hex(color)
    end

    -- Try to determine if the color is dark or light
    local numeric_value = 0;
    for s in color:gmatch("[a-fA-F0-9][a-fA-F0-9]") do
        numeric_value = numeric_value + tonumber("0x"..s);
    end
    -- return (numeric_value < 383)
    return (numeric_value < 470)
end

--- Check if a color is opaque.
function _color.is_opaque(color)
    if type(color) == "string" then
        color = _color.hex2rgb(color)
    end

    return color.a < 0.01
end

-- Multiply two colors
function _color.multiply(color, amount)
    if type(color) == "string" then
        color = _color.hex2rgb(color)
    end

    return { clip(color.r * amount, 0, 255),
             clip(color.g * amount, 0, 255),
             clip(color.b * amount, 0, 255),
             255 }
end

-- Blends two colors
function _color.blend(color1, color2)
    local rgb_color1  = _color.hex2rgb(color1)
    local rgb_color2  = _color.hex2rgb(color2)

    local blended_color = {}
    blended_color.r = round(rgb_color1.r * 0.5 + rgb_color2.r * 0.5)
    blended_color.g = round(rgb_color1.g * 0.5 + rgb_color2.g * 0.5)
    blended_color.b = round(rgb_color1.b * 0.5 + rgb_color2.b * 0.5)

    return _color.rgb2hex(blended_color)
end


function _color.alter_brightness(color, amount, sat)
    sat = sat or 0

    local hsl_color = _color.hex2hsl(color)
    hsl_color.l =  max(min(hsl_color.l + amount, 1), 0)
    hsl_color.s =  max(min(hsl_color.s + sat, 1), 0)

    return _color.hsl2hex(hsl_color)
end

--- Lighten a color.
function _color.lighten(color, amount)
    amount = amount or 26
    local c = {
        r = tonumber("0x"..color:sub(2,3)),
        g = tonumber("0x"..color:sub(4,5)),
        b = tonumber("0x"..color:sub(6,7)),
    }

    c.r = c.r + amount
    c.r = c.r < 0 and 0 or c.r
    c.r = c.r > 255 and 255 or c.r
    c.g = c.g + amount
    c.g = c.g < 0 and 0 or c.g
    c.g = c.g > 255 and 255 or c.g
    c.b = c.b + amount
    c.b = c.b < 0 and 0 or c.b
    c.b = c.b > 255 and 255 or c.b

    return format("#%02x%02x%02x", c.r, c.g, c.b)
end

--- Darken a color.
function _color.darken(color, amount)
    amount = amount or 26
    return _color.lighten(color, -amount)
end

-- Lightens a given hex color by the specified amount
function _color.nice_lighten(color, amount)
    local color = _color.hex2rgb(color)
    color.r = color.r
    color.g = color.g
    color.b = color.b
    color.r = color.r + floor(2.55 * amount)
    color.g = color.g + floor(2.55 * amount)
    color.b = color.b + floor(2.55 * amount)
    color.r = color.r > 255 and 255 or color.r
    color.g = color.g > 255 and 255 or color.g
    color.b = color.b > 255 and 255 or color.b
    return ("#%02x%02x%02x"):format(color.r, color.g, color.b)
end

-- Darkens a given hex color by the specified amount
function _color.nice_darken(color, amount)
    local color = _color.hex2rgb(color)
    color.r = color.r
    color.g = color.g
    color.b = color.b
    color.r = max(0, color.r - floor(color.r * (amount / 100)))
    color.g = max(0, color.g - floor(color.g * (amount / 100)))
    color.b = max(0, color.b - floor(color.b * (amount / 100)))
    return ("#%02x%02x%02x"):format(color.r, color.g, color.b)
end

-- Calculates the relative luminance of the given color
function _color.relative_luminance(color)
    local color = _color.hex2rgb(color)
    local function from_sRGB(u)
        return u <= 0.0031308 and 25 * u / 323 or
                   pow(((200 * u + 11) / 211), 12 / 5)
    end
    return 0.2126 * from_sRGB(color.r) + 0.7152 * from_sRGB(color.g) + 0.0722 * from_sRGB(color.b)
end

function _color.saturate_color(color, amount)
    local hsl_color = _color.hex2hsl(color)
    hsl_color.s = hsl_color.s + amount
    return _color.hsl2hex(hsl_color)
end

-- Calculates the contrast ratio between the two given colors
function _color.contrast_ratio(fg, bg)
    return (_color.relative_luminance(fg) + 0.05) / (_color.relative_luminance(bg) + 0.05)
end

-- Returns true if the contrast between the two given colors is suitable
function _color.is_contrast_acceptable(fg, bg)
    return _color.contrast_ratio(fg, bg) >= 7 and true
end

-- Returns a bright-ish, saturated-ish, color of random hue
function _color.rand_hex(lb_angle, ub_angle)
    return _color.hsv2hex(random(lb_angle or 0, ub_angle or 360), 70, 90)
end

-- Rotates the hue of the given hex color by the specified angle (in degrees)
function _color.rotate_hue(color, angle)
    local color = _color.hex2hsv(color)
    angle = clip(angle or 0, 0, 360)
    color.h = (color.h + angle) % 360
    return _color.hsv2hex(color.h, color.s, color.v)
end

-- Generate base/light/dark colors for buttons
function _color.generate_color(base_color, opaque, dark, light)
    if _color.is_opaque(base_color) then
        return _color.rgb2hex(_color.multiply(base_color, opaque))
    elseif _color.is_dark(base_color) then
        return _color.rgb2hex(_color.multiply(base_color, dark))
    else
        return _color.rgb2hex(_color.multiply(base_color, light))
    end
end

return _color
