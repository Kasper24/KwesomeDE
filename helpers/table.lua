local tostring = tostring
local ipairs = ipairs
local pairs = pairs
local table = table

local _table = {}

function _table.length(tbl)
    local length = 0
    for n in pairs(tbl) do
        length = length + 1
    end
    return length
end

function _table.dump(o, args)
    args = args or {}
    args.pretty = args.pretty or true
    args.depth = args.depth or 0
    args.max_depth = args.max_depth or -1
    if args.max_depth > 0 and args.depth > args.max_depth then
        return "..."
    end
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            s = s .. (args.pretty == true and "\n" or "")
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = s .. '[' .. k .. '] = ' .. _table.dump(v, args) .. ','
        end
        s = s .. (args.pretty == true and "\n" or "")
        return s .. '} '
    elseif type(o) == 'string' then
        return '"' .. o .. '"'
    else
        return tostring(o)
    end
end

function _table.remove_value(tbl, value)
    for index, _value in ipairs(tbl) do
        if _value == value then
            table.remove(tbl, index)
            break
        end
    end
end

return _table
