-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local settings = require("services.settings")
local helpers = require("helpers")
local string = string

local corona = { }
local instance = nil

local link = "https://corona-stats.online/%s?format=json"
local path = helpers.filesystem.get_cache_dir("corona")
local DATA_PATH = path .. "data.json"

local UPDATE_INTERVAL = 60 * 60 * 12 -- 12 hours

function corona:set_country(country)
    self._private.country = country
    settings:set_value("corona.country", self._private.country)
end

function corona:get_country()
    return self._private.country
end

function corona:open_website()
    awful.spawn("xdg-open https://www.worldometers.info/coronavirus/", false)
end

function corona:refresh()
    helpers.filesystem.remote_watch(
        DATA_PATH,
        string.format(link, self._private.country),
        UPDATE_INTERVAL,
        function(content)
            if content == nil then
                self:emit_signal("error")
                return
            end

            local data = helpers.json.decode(content)
            if data == nil then
                self:emit_signal("error")
                return
            end

            self:emit_signal("corona", data)
    end)
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, corona, true)

    ret._private = {}
    ret._private.country = settings:get_value("corona.country")

    if ret._private.country ~= nil then
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