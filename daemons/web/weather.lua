-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local lgi = require("lgi")
local Secret = lgi.Secret
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local helpers = require("helpers")
local filesystem = require("external.filesystem")
local json = require("external.json")
local string = string

local weather = {}
local instance = nil

local path = filesystem.filesystem.get_cache_dir("weather")
local DATA_PATH = path .. "data.json"

local UPDATE_INTERVAL = 60 * 30 -- 30 mins

function weather:set_api_key(api_key)
    Secret.password_store(
        self._private.api_key_schema,
        self._private.api_key_atrributes,
        Secret.COLLECTION_DEFAULT,
        "api key",
        api_key,
        nil,
        function(source, result, unused)
            local success = Secret.password_store_finish(result)
            if success then
                self._private.api_key = api_key
                self:refresh()
            end
        end
    )
end

function weather:get_api_key()
    if self._private.api_key == nil then
        self._private.api_key =Secret.password_lookup_sync(self._private.api_key_schema, self._private.api_key_atrributes)
    end

    return self._private.api_key
end

function weather:set_unit(unit)
    self._private.unit = unit
    helpers.settings["openweather.unit"] = unit
    self:refresh()
end

function weather:get_unit()
    return self._private.unit
end

function weather:set_latitude(latitude)
    self._private.latitude = latitude
    helpers.settings["openweather.latitude"] = latitude
    self:refresh()
end

function weather:get_latitude()
    return self._private.latitude
end

function weather:set_longitude(longitude)
    self._private.longitude = longitude
    helpers.settings["openweather.longitude"] = longitude
    self:refresh()
end

function weather:get_longitude()
    return self._private.longitude
end

function weather:refresh()
    local link = string.format(
        "https://api.openweathermap.org/data/2.5/onecall?lat=%s&lon=%s&appid=%s&units=%s&exclude=minutely&lang=en",
        self:get_latitude(), self:get_longitude(), self:get_api_key(), self:get_unit())

        filesystem.filesystem.remote_watch(
        DATA_PATH, link,
        UPDATE_INTERVAL,
        function(content)
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
        end
    )

end

local function new()
    local ret = gobject {}
    gtable.crush(ret, weather, true)

    ret._private = {}

    ret._private.api_key_atrributes =  {
        ["org.kwesomede.openweather.openweather.api-key"] = "openweather api key"
    }
    ret._private.api_key_schema = Secret.Schema.new("org.kwesomede", Secret.SchemaFlags.NONE, {
        ["org.kwesomede.openweather.openweather.api-key"] = Secret.SchemaAttributeType.STRING
    })

    ret._private.latitude = helpers.settings["openweather.latitude"]
    ret._private.longitude = helpers.settings["openweather.longitude"]
    ret._private.unit = helpers.settings["openweather.unit"]

    if ret:get_api_key() and ret:get_latitude() ~= "" and ret:get_longitude() ~= "" then
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
