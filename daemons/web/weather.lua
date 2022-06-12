-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local settings = require("services.settings")
local helpers = require("helpers")
local string = string

local weather = { }
local instance = nil

local path = helpers.filesystem.get_cache_dir("weather")
local DATA_PATH = path .. "data.json"

local UPDATE_INTERVAL = 60 * 60 * 12 -- 12 hours

function weather:set_api_key(api_key)
    self._private.api_key = api_key
    settings:set_value("weather.api_key", self._private.api_key)
end

function weather:get_api_key()
    return self._private.api_key
end

function weather:set_unit(unit)
    self._private.unit = unit
    settings:set_value("weather.unit", self._private.unit)
end

function weather:get_unit()
    return self._private.unit
end

function weather:set_coordinate_x(coordinate_x)
    self._private.coordinate_x = coordinate_x
    settings:set_value("weather.coordinate_x", self._private.coordinate_x)
end

function weather:get_coordinate_x()
    return self._private.coordinate_x
end

function weather:set_coordinate_y(coordinate_y)
    self._private.coordinate_y = coordinate_y
    settings:set_value("weather.coordinate_y", self._private.coordinate_y)
end

function weather:get_coordinate_y()
    return self._private.coordinate_y
end

function weather:refresh()
    local link = string.format("https://api.openweathermap.org/data/2.5/onecall?lat=%s&lon=%s&appid=%s&units=%s&exclude=minutely&lang=en",
        self._private.coordinate_x,
        self._private.coordinate_y,
        self._private.api_key,
        self._private.unit)

    helpers.filesystem.remote_watch(
        DATA_PATH,
        link,
        UPDATE_INTERVAL,
        function(content)
            if content == nil or content == false then
                self:emit_signal("error")
                return
            end

            local data = helpers.json.decode(content)
            if data == nil then
                self:emit_signal("error")
                return
            end

            self:emit_signal("weather", data, self._private.unit)
    end)

end

local function new()
    local ret = gobject{}
    gtable.crush(ret, weather, true)

    ret._private = {}

    -- "metric" for Celcius, "imperial" for Fahrenheit
    ret._private.unit = settings:get_value("weather.unit") or "metric"
    ret._private.api_key = settings:get_value("weather.api_key")
    ret._private.coordinate_x = settings:get_value("weather.coordinate_x")
    ret._private.coordinate_y = settings:get_value("weather.coordinate_y")

    if ret._private.api_key ~= nil and ret._private.coordinate_x ~= nil and ret._private.coordinate_y ~= nil then
        ret:refresh()
    else
        gtimer.delayed_call(function()
            ret:emit_signal("missing_credentials")
        end)
    end

    return ret
end

if not instance then
    instance = new()
end
return instance