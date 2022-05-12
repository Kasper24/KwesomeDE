local tostring = tostring
local string = string
local ipairs = ipairs
local table = table
local math = math
local os = os

local _string = {}

local hebrew_chracters =
{
    "א",
    "ב",
    "ג",
    "ד",
    "ה",
    "ו",
    "ז",
    "ח",
    "ט",
    "א",
    "ך",
    "ל",
    "מ",
    "ם",
    "נ",
    "ן",
    "ס",
    "ע",
    "פ",
    "ף",
    "צ",
    "ץ",
    "ק",
    "ר",
    "ש",
    "צ",
}
function _string.contain_right_to_left_characters(string)
    string = tostring(string)
    if string == "" or string == nil then
        return false
    end

    for _, character in ipairs(hebrew_chracters) do
        if string.match(string, character) ~= nil then
            return true
        end
    end

    return false
end

--- Converts string representation of date (2020-06-02T11:25:27Z) to date
function _string.parse_date(date_str)
    local pattern = "(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)%Z"
    local y, m, d, h, min, sec, _ = date_str:match(pattern)

    return os.time{year = y, month = m, day = d, hour = h, min = min, sec = sec}
end

--- Converts seconds to "time ago" representation, like '1 hour ago'
function _string.to_time_ago(seconds)
    local days = seconds / 86400
    if days >= 1 then
        days = math.floor(days)
        return days .. (days == 1 and " day" or " days") .. " ago"
    end

    local hours = (seconds % 86400) / 3600
    if hours >= 1 then
        hours = math.floor(hours)
        return hours .. (hours == 1 and " hour" or " hours") .. " ago"
    end

    local minutes = ((seconds % 86400) % 3600) / 60
    if minutes >= 1 then
        minutes = math.floor(minutes)
        return minutes .. (minutes == 1 and " minute" or " minutes") .. " ago"
    end

    return "Now"
end

function _string.case_insensitive_pattern(pattern)
    if pattern == "" or nil then
        return ""
    end

    -- find an optional '%' (group 1) followed by any character (group 2)
    local p = pattern:gsub("(%%?)(.)", function(percent, letter)
      if percent ~= "" or not letter:match("%a") then
        -- if the '%' matched, or `letter` is not a letter, return "as is"
        return percent .. letter
      else
        -- else, return a case-insensitive character class of the matched letter
        return string.format("[%s%s]", letter:lower(), letter:upper())
      end
    end)

    return p
end

function _string.levenshtein(str1, str2)
	local len1 = string.len(str1)
	local len2 = string.len(str2)
	local matrix = {}
	local cost = 0

    -- quick cut-offs to save time
	if (len1 == 0) then
		return len2
	elseif (len2 == 0) then
		return len1
	elseif (str1 == str2) then
		return 0
	end

    -- initialise the base matrix values
	for i = 0, len1, 1 do
		matrix[i] = {}
		matrix[i][0] = i
	end
	for j = 0, len2, 1 do
		matrix[0][j] = j
	end

    -- actual Levenshtein algorithm
	for i = 1, len1, 1 do
		for j = 1, len2, 1 do
			if (str1:byte(i) == str2:byte(j)) then
				cost = 0
			else
				cost = 1
			end

			matrix[i][j] = math.min(matrix[i-1][j] + 1, matrix[i][j-1] + 1, matrix[i-1][j-1] + cost)
		end
	end

    -- return the last value - this is the Levenshtein distance
	return matrix[len1][len2]
end

function _string.find_last(haystack, needle)
    --Set the third arg to false to allow pattern matching
    local found = haystack:reverse():find(needle:reverse(), nil, true)
    if found then
        return haystack:len() - needle:len() - found + 2
    else
        return found
    end
end

function _string.split(string, separator)
    if separator == nil then
        separator = "%s"
    end

    local t = {}
    for str in string.gmatch(string, "([^".. separator .."]+)") do
        table.insert(t, str)
    end

    return t
end

function _string.random_uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

function _string.trim(string)
    return string:gsub("^%s*(.-)%s*$", "%1")
end

function _string.day_ordinal_number(day)
	day = day or os.date("%d")

	local first_digit = string.sub(day, 0, 1)
	local last_digit = string.sub(day, -1)
	if first_digit == "0" then
	    day = last_digit
	end

	if last_digit == "1" and day ~= "11" then
	    return "st"
	elseif last_digit == "2" and day ~= "12" then
	    return "nd"
	elseif last_digit == "3" and day ~= "13" then
	    return "rd"
	else
	    return "th"
	end
end

return _string