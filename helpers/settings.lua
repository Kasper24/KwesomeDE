-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local hjson = require("helpers.json")
local hfilesystem = require("helpers.filesystem")
local tostring = tostring

local settings = { }
local instance = nil

local PATH = hfilesystem.get_cache_dir("settings")
local DATA_PATH = PATH .. "data.json"

local function save(self)
    self.save_timer:again()
end

local function read(self)
    self.json_settings = {}

    -- This has to be blocking
    local content = hfilesystem.read_file_block(DATA_PATH)

    if content == nil then
        return
    end

    local data = hjson.decode(content)
    if data == nil then
        return
    end

    self.json_settings = data
end

function settings:set_value(key, value)
    local old_value = self.json_settings[key]
    if (old_value ~= nil and old_value ~= value) or (old_value == nil) or type(value) == "table" then
        if old_value ~= nil then
            print("Setting: " .. key .. " to: " .. tostring(value) .. " from:" .. tostring(old_value))
        else
            print("Setting: " .. key .. " to: " .. tostring(value))
        end
        self.json_settings[key] = value
        save(self)
    end
end

function settings:get_value(key)
    if self.json_settings ~= nil and self.json_settings[key] ~= nil then
        return self.json_settings[key]
    end

    return nil
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, settings, true)

    ret.save_timer = gtimer
    {
        timeout = 1,
        autostart = false,
        single_shot = true,
        callback = function()
            hfilesystem.save_file(
                DATA_PATH,
                hjson.encode(ret.json_settings, { indent = true })
            )
        end
    }

    read(ret)

    return ret
end

if not instance then
    instance = new()
end
return instance