local hstring = require("helpers.string")
local pairs = pairs

local _table = {}

function _table.has_value(tab, val)
    for _, value in pairs(tab) do
        if val:find(hstring.case_insensitive_pattern(value)) then
            return true
        end
    end
    return false
end

function _table.length(tbl)
    local length = 0
    for n in pairs(tbl) do
      length = length + 1
    end
    return length
end

function _table.spairs(tbl)
    local length = 0
    for n in pairs(tbl) do
      length = length + 1
    end
    return length
end

return _table