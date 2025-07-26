-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local lgi = require("lgi")
local Secret = lgi.Secret
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local library = require("library")
local filesystem = require("external.filesystem")
local json = require("external.json")
local string = string

local weather = {}
local instance = nil

local path = filesystem.filesystem.get_data_dir("weather")
local DATA_PATH = path .. "data.json"

local UPDATE_INTERVAL = 60 * 30 -- 30 mins

function weather:set_unit(unit)
	self._private.unit = unit
	library.settings["weather.unit"] = unit
	self:refresh()
end

function weather:get_unit()
	if self._private.unit == nil then
		self._private.unit = library.settings["weather.unit"]
	end

	return self._private.unit or ""
end

function weather:set_latitude(latitude)
	self._private.latitude = latitude
	library.settings["weather.latitude"] = latitude
	self:refresh()
end

function weather:get_latitude()
	if self._private.latitude == nil then
		self._private.latitude = library.settings["weather.latitude"]
	end

	return self._private.latitude or ""
end

function weather:set_longitude(longitude)
	self._private.longitude = longitude
	library.settings["weather.longitude"] = longitude
	self:refresh()
end

function weather:get_longitude()
	if self._private.longitude == nil then
		self._private.longitude = library.settings["weather.longitude"]
	end

	return self._private.longitude or ""
end

function weather:refresh()
	if self:get_latitude() == "" or self:get_longitude() == "" or self:get_unit() == "" then
		self:emit_signal("error::missing_credentials")
		return
	end

	local link = string.format(
		"https://api.open-meteo.com/v1/forecast?latitude=%s&longitude=%s&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,wind_direction_10m&hourly=temperature_2m&daily=weather_code,temperature_2m_max,temperature_2m_min,uv_index_max&temperature_unit=%s&timeformat=unixtime",
		self:get_latitude(),
		self:get_longitude(),
		self:get_unit()
	)

	filesystem.filesystem.remote_watch(DATA_PATH, link, UPDATE_INTERVAL, function(content)
		if content == nil or content == false then
			self:emit_signal("error")
			return
		end

		local data = json.decode(content)
		if data == nil then
			self:emit_signal("error")
			return
		end

		self:emit_signal("weather", data)
	end)
end

local function new()
	local ret = gobject({})
	gtable.crush(ret, weather, true)

	ret._private = {}

	gtimer.delayed_call(function()
		ret:refresh()
	end)

	return ret
end

if not instance then
	instance = new()
end
return instance
