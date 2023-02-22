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

local settings = {}
local instance = nil

local DATA_PATH = filesystem.filesystem.get_cache_dir("settings") .. "data.json"

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

    local path = DATA_PATH
    if is_settings_file_readable() == false then
        path = filesystem.filesystem.get_awesome_config_dir("config/settings") .. "data.json"
    end
    ret.settings = json.decode(Gio.File.new_for_path(path):load_contents())

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
            local value = self.settings[key].value or self.settings[key].default
            if type(value) == "table" then
                value = gtable.clone(value, true)
            end
            return value
        end,
        __newindex = function(self, key, value)
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
