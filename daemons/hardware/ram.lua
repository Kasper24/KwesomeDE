-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")

local ram = { }
local instance = nil

local UPDATE_INTERVAL = 5

local function new()
    local ret = gobject{}
    gtable.crush(ret, ram, true)

    gtimer { timeout = UPDATE_INTERVAL, autostart = true, call_now = true, callback = function()
        awful.spawn.easy_async([[ bash -c "LANGUAGE=en_US.UTF-8 free | grep -z Mem.*Swap.*" ]], function(stdout)
            local total, used, free, shared, buff_cache, available, total_swap, used_swap, free_swap
            total, used, free, shared, buff_cache, available, total_swap, used_swap, free_swap =
                stdout:match('(%d+)%s*(%d+)%s*(%d+)%s*(%d+)%s*(%d+)%s*(%d+)%s*Swap:%s*(%d+)%s*(%d+)%s*(%d+)')

            ret:emit_signal("update", total, used, free, shared, buff_cache,
                available, total_swap, used_swap, free_swap)
        end)
    end}

    return ret
end

if not instance then
    instance = new()
end
return instance