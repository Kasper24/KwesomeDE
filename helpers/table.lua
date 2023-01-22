local hstring = require("helpers.string")
local tostring = tostring
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

function _table.dump(o, args)
	args = args or {}
	args.pretty = args.pretty or false
	args.depth = args.depth or 0
	args.max_depth = args.max_depth or -1
	if args.max_depth > 0 and args.depth > args.max_depth then
		return "..."
	end
	if type(o) == 'table' then
	  local s = '{ '
	  for k,v in pairs(o) do
		   s = s .. (args.pretty == true and "\n" or "")
	     if type(k) ~= 'number' then k = '"'..k..'"' end
	     s = s .. '['..k..'] = ' .. _table.dump(v, args) .. ','
	  end
		s = s .. (args.pretty == true and "\n" or "")
	  return s .. '} '
	elseif type(o) == 'string' then
		return '"'..o..'"'
	else
	  return tostring(o)
	end
end

function _table.contains(table, elem, strify)
	strify = strify or false
	for _, val in pairs(table) do
		if strify then
			val = tostring(val)
		end
		if val == elem then
			return true
		end
	end
	return false
end

function _table.contains_any(table, elems, strify)
	strify = strify or false
	for _, elem in pairs(elems) do
		if _table.contains(table, elem, strify) then
			return true
		end
	end
	return false
end

function _table.contains_all(table, elems, strify)
	strify = strify or false
	for _, elem in pairs(elems) do
		if not _table.contains(table, elem, strify) then
			return false
		end
	end
	return true
end

function _table.contains_only(table, elems, strify)
	strify = strify or false
	for _, val in pairs(table) do
    if strify then
			val = tostring(val)
		end
		if not _table.contains(elems, val) then
			return false
		end
	end
	return true
end

return _table