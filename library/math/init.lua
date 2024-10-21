local math = math
local floor = math.floor
local max = math.max
local min = math.min

local _math = {}

function _math.round(number, decimals)
    local power = 10 ^ decimals
    return floor(number * power) / power
end

function _math.round_by_factor(number, factor)
    return floor(number / factor + 0.5) * factor
end

function _math.convert_range(old_value, old_min, old_max, new_min, new_max)
    return ((old_value - old_min) / (old_max - old_min)) * (new_max - new_min) + new_min
end

function _math.clip(num, min_num, max_num)
    return max(min(num, max_num), min_num)
end

return _math