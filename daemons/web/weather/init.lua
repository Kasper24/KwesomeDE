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

    return self._private.api_key or ""
end

function weather:set_unit(unit)
    self._private.unit = unit
    library.settings["openweather.unit"] = unit
    self:refresh()
end

function weather:get_unit()
    if self._private.unit == nil then
        self._private.unit = library.settings["openweather.unit"]
    end

    return self._private.unit or ""
end

function weather:set_latitude(latitude)
    self._private.latitude = latitude
    library.settings["openweather.latitude"] = latitude
    self:refresh()
end

function weather:get_latitude()
    if self._private.latitude == nil then
        self._private.latitude = library.settings["openweather.latitude"]
    end

    return self._private.latitude or ""
end

function weather:set_longitude(longitude)
    self._private.longitude = longitude
    library.settings["openweather.longitude"] = longitude
    self:refresh()
end

function weather:get_longitude()
    if self._private.longitude == nil then
        self._private.longitude = library.settings["openweather.longitude"]
    end

    return self._private.longitude or ""
end

function weather:refresh()
    if self:get_api_key() == "" or self:get_latitude() == "" or self:get_longitude() == "" or self:get_unit() == "" then
        self:emit_signal("error::missing_credentials")
        return
    end

    local link = string.format(
        "https://api.openweathermap.org/data/2.5/onecall?lat=%s&lon=%s&appid=%s&units=%s&exclude=minutely&lang=en",
        self:get_latitude(), self:get_longitude(), self:get_api_key(), self:get_unit())

        filesystem.filesystem.remote_watch(
            DATA_PATH,
            link,
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

    gtimer.delayed_call(function()
        ret:refresh()
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance
