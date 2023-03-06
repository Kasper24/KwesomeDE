local tostring = tostring
local ipairs = ipairs
local pairs = pairs
local table = table

local _table = {}

function _table.remove_value(tbl, value)
    for index, _value in ipairs(tbl) do
        if _value == value then
            table.remove(tbl, index)
            break
        end
    end
end

return _table
