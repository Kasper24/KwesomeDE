local module = {}


--- Returns a subsection of a list.
--
-- This returns the subsection and its length.
--
-- @tparam table list The table to slice.
-- @tparam[opt=1] number first The index to start slicing at. Defaults to the first element in the table.
-- @tparam[opt=#list] number last The index to stop slicing at (inclusive). A negative number may be specified
--  to count from the end of the table. Defaults to the last element in the table.
-- @treturn table
-- @treturn number
function module.slice(list, first, last)
    local result = {}
    local count = 0
    first = first or 1
    last = last or #list
    if last < 0 then
        last = #list + last
    end

    for i = first, last do
        count = count + 1
        table.insert(result, list[i])
    end

    return result, count
end


--- Tests if all elements of a list matches the predicate.
--
-- This only takes integer indices of the provided table into account (`ipairs` semantics).
-- The function signature for the predicate is
--
--     function(value) -> bool
--
-- @tparam table list The list to iterate over.
-- @tparam function predicate The predicate to test every element against
-- @treturn bool
function module.all(list, predicate)
    for key, val in ipairs(list) do
        if not predicate(val, key) then
            return false
        end
    end

    return true
end


--- Append items from the source table to the target table.
--
-- Note that this only considers the array part of `source` (same semantics
-- as `ipairs`).
-- Nested tables are copied by reference and not recursed into.
--
-- @tparam table target The table to append values to.
-- @tparam table source The table to copy values from.
-- @treturn table The target table.
function module.append(target, source)
    for _, v in ipairs(source) do
        table.insert(target, v)
    end

    return target
end

return module
