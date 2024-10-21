-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local helpers = require("helpers")
local filesystem = require("external.filesystem")
local json = require("external.json")
local string = string

local corona = {}
local instance = nil

local link = "https://corona-stats.online/%s?format=json"
local path = filesystem.filesystem.get_cache_dir("corona")
local DATA_PATH = path .. "data.json"

local UPDATE_INTERVAL = 60 * 30 -- 30 mins

function corona:set_country(country)
    self._private.country = country
    helpers.settings["corona.country"] = country
end

function corona:get_country()
    if self._private.country == nil then
        self._private.country = helpers.settings["corona.country"]
    end

    return self._private.country or ""
end

function corona:open_website()
    awful.spawn("xdg-open https://www.worldometers.info/coronavirus/", false)
end

function corona:refresh()
    if self:get_country() == "" then
        self:emit_signal("error::missing_credentials")
        return
    end

    filesystem.filesystem.remote_watch(
        DATA_PATH,
        string.format(link, self._private.country),
        UPDATE_INTERVAL,
        function(content)
            if content == nil then
                self:emit_signal("error")
                return
            end

            local data = json.decode(content)
            if data == nil then
                self:emit_signal("error")
                return
            end

            self:emit_signal("corona", data)
        end
    )
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, corona, true)

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
