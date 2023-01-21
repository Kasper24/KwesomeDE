-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local Gio = require("lgi").Gio
local GLib = require("lgi").GLib
local gobject = require("gears.object")
local gtable = require("gears.table")
local tostring = tostring

local settings = { }
local instance = nil

function settings:set_value(key, value)
    local old_value = self.settings:get_value(key)
    -- print("Setting: " .. key .. " to: " .. tostring(value) .. " from:" .. tostring(old_value.value))
    self.settings:set_value(key, GLib.Variant(old_value.type, value))
end

function settings:get_value(key)
    -- print("key: " .. tostring(key) .. " value: " .. tostring(self.settings:get_value(key).value))
    return self.settings:get_value(key).value
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, settings, true)

    local SettingsSchemaSource = Gio.SettingsSchemaSource
    local path = debug.getinfo(1).source:match("@?(.*/)") .. "../config/gschemas"
    local schema_source = SettingsSchemaSource.new_from_directory(path, SettingsSchemaSource.get_default(), false)
    local schema = schema_source.lookup(schema_source, "org.awesome.settings", false)
    ret.settings = Gio.Settings.new_full(schema)

    return ret
end

if not instance then
    instance = new()
end
return instance