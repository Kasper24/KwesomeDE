--[[
lua-ical, utility for parsing iCalendar file format written in Lua
Copyright (C) 2016  MParolari
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

local ical = {}

local parser = {}

local wd = {SU = 0, MO = 1, TU = 2, WE = 3, TH = 4, FR = 5, SA = 6}

-- support function for deep-copy a table
local function clone (tb)
    if type(tb) ~= "table" then return tb end
    local ctb, mt = {}, getmetatable(tb)
    for k,v in pairs(tb) do
        if type(v) == "table" then ctb[k] = clone(v)
        else ctb[k] = v
        end
    end
    setmetatable(ctb, mt)
    return ctb
end

--TODO parsing period (list of dates?)
local function parse_date(v)
  if not v then return nil end
	local t, utc = {}, nil
	t.year, t.month, t.day = v:match("^(%d%d%d%d)(%d%d)(%d%d)")
	t.hour, t.min, t.sec, utc = v:match("T(%d%d)(%d%d)(%d%d)(Z?)")
  if (t.hour == nil) or (t.min == nil) or (t.sec == nil) then
    t.hour, t.min, t.sec, utc = 0,0,0,nil
  end
	for k,v in pairs(t) do t[k] = tonumber(v) end
	return os.time(t), utc
end

function parser.VEVENT(entry, k, v)
	if k == "BEGIN" then
		function entry:duration(f) return ical.duration(self, f) end
		function entry:is_in(s) return ical.is_in(self, s) end
    function entry:is_over(s) return ical.is_over(self, s) end

	elseif k:find("DTSTART") or k:find("DTEND") then
		-- get timezone id
		local tzid = k:match("TZID=([a-zA-Z-\\/]+)")
		local value = k:match("VALUE=([a-zA-Z-\\/]+)")

		if string.find(k, ";") then
			k = k:match("^(.-);")
		end

		entry[k .. "_A"] = v

    -- parsing value
    local time, utc = parse_date(v)
    if utc == 'Z' then tzid = 'UTC' end

		-- write entry
		entry[k] = time
		entry[k..'_TZID'] = tzid

	elseif k:find("RRULE") or k:find("EXRULE") then
		entry[k] = {}
		entry[k].FREQ = v:match("FREQ=([A-Z]+)")
		entry[k].WKST = v:match("WKST=([A-Z]+)")
		entry[k].UNTIL = parse_date(v:match("UNTIL=([TZ0-9]+)"))
    entry[k].COUNT = v:match("COUNT=([0-9]+)")
    entry[k].INTERVAL = v:match("INTERVAL=([0-9]+)")
		-- byday, bymonth, ecc ecc
    for byk, by in v:gmatch("(BY[A-Z]+)=([%+%-0-9A-Z,]+)") do
      entry[k][byk] = {}
      for b in by:gmatch("([%+%-0-9A-Z]+),?") do
        table.insert(entry[k][byk], b)
      end
    end
    if entry[k].UNTIL == nil and entry[k].COUNT == nil then
      return "RRULE.UNTIL or RRULE.COUNT not found"
    end

	elseif k:find("EXDATE") then
		local tzid = k:match("TZID=([a-zA-Z-\\/]+)")
		if k:find(";") then
			k = k:match("^(.-);")
		end
		if entry[k] == nil then entry[k] = {} end
		if entry[k..'_TZID'] == nil then entry[k..'_TZID'] = {} end
		-- parsing value
    local time, utc = parse_date(v)
    if utc == 'Z' then tzid = 'UTC' end

		table.insert(entry[k], time)
		table.insert(entry[k..'_TZID'], tzid)

	else
		entry[k] = v
	end

  return nil -- no problems
end

function parser.STANDARD(entry, k, v)
  if k:find("DTSTART") or k:find("RRULE") then
    local err = parser.VEVENT(entry, k, v)
    if err and err ~= "RRULE.UNTIL or RRULE.COUNT not found" then return err end
  elseif k:find("TZOFFSETFROM") or k:find("TZOFFSETTO") then
    local s, h, m = v:match("([+-])(%d%d)(%d%d)")
    if s == "+" then s = 1 else s = -1 end
    entry[k] = s*(tonumber(h)*3600 + tonumber(m)*60)
  end

  return nil -- no problems
end

parser.DAYLIGHT = parser.STANDARD

function parser.VCALENDAR(entry, k, v)
	if k == "BEGIN" then
		function entry:events() return ical.events(self) end
	else
		entry[k] = v
	end
end

function ical.new(data)
	local entry = { subs = {}, type = nil }
	local stack = {}
	local line_num = 0; -- only for check errors

	--TODO check if there's a standard or it's a workaround for google calendars only
	data = data:gsub("[\r\n]+ ", "")

	-- Parse
	for line in data:gmatch("(.-)[\r\n]+") do
		line_num = line_num + 1;
    --print(line_num)

		-- retrieve key and value
		local k,v = line:match("^(.-):(.*)$")
		if not(k and v) then
			return nil, "Parsing error, key:value format not valid at line "..line_num
		end

		-- open a new entry
		if k == "BEGIN" then
			local new_entry = { subs = {}, type = v } -- new entry
			table.insert(entry.subs, new_entry) -- insert new entry in sub-entries
			table.insert(stack, entry) -- push current entry in stack
			entry = new_entry -- current entry is now the new entry just created
		end

		-- call the parser
		if parser[entry.type] then
			local err = parser[entry.type](entry, k, v)
      if err then return nil, err end
		else
			entry[k] = v
		end

		-- close current entry
		if k == "END" then
			if entry.type ~= v then -- check end
				return nil, "Parsing error, expected END:"..entry.type.." before line "..line_num
			end
			entry = table.remove(stack) -- pop the previous entry
		end
	end

	-- Return calendar
	return entry.subs[1]
end

function ical.duration(a, f)
	if a and a.type == "VEVENT" then
		local d = os.difftime(a.DTEND, a.DTSTART)
		if f == "hour" then d = d/3600
		elseif f == "min" then d = d/60
		end
		return d
	else
		return nil
	end
end

function ical.time_compare(a, b) --TODO define better (b-a)?
	if not(a and b) then return nil end
	local d = os.difftime(a, b)
	if d < 0 then
		return -1
	elseif d > 0 then
		return 1
	elseif d == 0 then
		return 0
	end
end

local function apply_rrule(orig, tb)
  if not orig or type(tb) ~= "table" then return "Bad arguments" end
  local exdates = orig.EXDATE or {}
  local byday = orig.RRULE.BYDAY or {}
  for i=1,#byday do
    local d = byday[i]:match("[%+%-0-9]*([A-Z]+)")
    byday[i] = wd[d]
  end
  if byday then table.sort(byday) end
  -- check RRULE WEEKLY
  if orig.RRULE.FREQ == "WEEKLY" then
    -- new (current) event
    local ne = clone(orig)
    local count = 1 -- orig is the first occurrence
    local function add_days(n)
      ne.DTSTART = ne.DTSTART + n*24*3600
    --   if ne.DTEND then ne.DTEND = ne.DTEND + n*24*3600 end
    end
    local last_i = 1
    repeat
      -- if true, ne will be inserted
      local inserting = false

      -- check weekday
      local w = tonumber(os.date("%w", ne.DTSTART))
      for i = last_i, #byday do
        local diff = byday[i] - w
        if diff > 0 then
          add_days(diff)
          inserting = true
          last_i = i
          break
        elseif i == #byday then -- if diff<0 with last byday[], go to next week
          add_days(7-w)
          last_i = 1
        end
      end

      -- check EXDATE
      for i = 1, #exdates do
        if ical.time_compare(exdates[i], ne.DTSTART) == 0 then
          inserting = false
        end
      end

      -- insert
      if inserting then tb[#tb +1] = clone(ne) end

      local quit = true -- avoid infinite loop by default
      if orig.RRULE.UNTIL then
        quit = ical.time_compare(ne.DTSTART, orig.RRULE.UNTIL) >= 0
      elseif orig.RRULE.COUNT then
        if inserting then count = count +1 end
        quit = count >= orig.RRULE.COUNT
      else
        return "RRULE.UNTIL or RRULE.COUNT not found"
      end

    until quit
  end
  --TODO check other sequences
end

-- Given an entry, it returns the VEVENT sub-entries
function ical.events(cal)
	if type(cal) ~= "table" or cal.type ~= "VCALENDAR" then return nil end
	local evs = {}
	for _,e in ipairs(cal.subs) do
		if e.type == "VEVENT" then
			table.insert(evs, e)
			if e.RRULE then apply_rrule(e, evs) end
		end
	end
	return evs
end

function ical.sort_events(evs)
	table.sort(evs,
		function(a,b)
			return ical.time_compare(a.DTSTART, b.DTSTART) < 0
		end
	)
end

function ical.get_events_from_date(events, date)
	local date_events = {}
	for index, event in ipairs(events) do
		-- local event_date = tostring(event.DTSTART_A):match("(.*)T")

		print(date .. "  " .. event.DTSTART_A)

		if event.DTSTART_A == date then
			table.insert(date_events, event)
		end
	end

	return date_events
end

function ical.is_in(e, s)
	if type(e) ~= "table" or type(s) ~= "table" then return nil end
	return (ical.time_compare(e.DTSTART, s.DTSTART) >= 0) and
				 (e.DTEND == nil or (ical.time_compare(e.DTEND, s.DTEND) <= 0))
end

function ical.is_over(e, s)
	if type(e) ~= "table" or type(s) ~= "table" then return nil end
  local es_ss = ical.time_compare(e.DTSTART, s.DTSTART)
  local es_se = ical.time_compare(e.DTSTART, s.DTEND)
  local ee_ss = ical.time_compare(e.DTEND, s.DTSTART)
  local ee_se = ical.time_compare(e.DTEND, s.DTEND)
  -- if event hasn't an end
  if e.DTEND == nil then
    return (es_ss >= 0) and (es_se <= 0) -- s_start, e_start, s_end
  end
  -- else
	return ((es_ss >= 0) and (es_se <= 0)) -- s_start, e_start, s_end
      or ((ee_ss >= 0) and (ee_se <= 0)) -- s_start, e_end, s_end
      or ((es_ss <= 0) and (ee_se >= 0)) -- e_start, s_start, s_end, e_end
end

function ical.span(start, end_)
  return {DTSTART = start, DTEND = end_}
end

function ical.span_duration(start, duration)
  return ical.span(start, start + duration)
end

return ical;