-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local tonumber = tonumber
local string = string

local temperature = {}
local instance = nil

local function new()
    local ret = gobject {}
    gtable.crush(ret, temperature, true)

    gtimer.poller {
        timeout = 15,
        callback = function()
            awful.spawn.easy_async("sensors", function(stdout)
                local temp = string.match(stdout, "Tctl:%s*+(%d+)")
                ret:emit_signal("update", tonumber(temp))
            end)
        end
    }

    return ret
end

if not instance then
    instance = new()
end
return instance
