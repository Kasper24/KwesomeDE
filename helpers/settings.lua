-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local Gio = require("lgi").Gio
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local filesystem = require("external.filesystem")
local json = require("external.json")
local type = type

local settings = {}
local instance = nil

local DATA_PATH = filesystem.filesystem.get_cache_dir("settings") .. "data.json"
local DEFAULT_DATA_PATH = filesystem.filesystem.get_awesome_config_dir("assets/settings") .. "data.json"

local function is_settings_file_readable()
    local gfile = Gio.File.new_for_path(DATA_PATH)
    local gfileinfo = gfile:query_info(
        "standard::type,access::can-read,time::modified",
        Gio.FileQueryInfoFlags.NONE
    )
    return gfileinfo ~= nil and gfileinfo:get_file_type() ~= "DIRECTORY" and
            gfileinfo:get_attribute_boolean("access::can-read")
end

function settings:open_setting_file()
    awful.spawn("xdg-open " ..  DATA_PATH, false)
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, settings, true)

    if is_settings_file_readable() == true then
        ret.settings = json.decode(Gio.File.new_for_path(DATA_PATH):load_contents())
    else
        ret.settings = json.decode(Gio.File.new_for_path(DEFAULT_DATA_PATH):load_contents())
    end
    ret.default_settings = json.decode(Gio.File.new_for_path(DEFAULT_DATA_PATH):load_contents())

    local file = filesystem.file.new_for_path(DATA_PATH)
    ret.save_timer = gtimer
    {
        timeout = 1,
        autostart = false,
        call_now = false,
        single_shot = true,
        callback = function()
            file:write(json.encode(ret.settings))
        end
    }

    local mt = {
        __index = function(self, key)
            if self.settings[key] == nil then
                self.settings[key] = self.default_settings[key]
            end

            local value = self.settings[key].value
            if value == nil then
                value = self.settings[key].default
            end

            if type(value) == "table" then
                value = gtable.clone(value, true)
            end
            return value
        end,
        __newindex = function(self, key, value)
            if self.settings[key] == nil then
                self.settings[key] = self.default_settings[key]
            end

            self.settings[key].value = value
            self.save_timer:again()
        end
    }

    setmetatable(ret, mt)

    return ret
end

if not instance then
    instance = new()
end
return instance
