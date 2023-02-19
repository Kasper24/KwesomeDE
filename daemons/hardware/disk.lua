-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local table = table

local disk = {}
local instance = nil

local function new()
    local ret = gobject {}
    gtable.crush(ret, disk, true)

    ret._private = {}
    ret._private.partition = {}

    gtimer.poller {
        timeout = 1800,
        callback = function()
            awful.spawn.easy_async_with_shell("df | tail -n +2", function(stdout)
                for line in stdout:gmatch("[^\r\n$]+") do
                    local filesystem, size, used, avail, perc, mount = line:match(
                        "([%p%w]+)%s+([%d%w]+)%s+([%d%w]+)%s+([%d%w]+)%s+([%d]+)%%%s+([%p%w]+)")

                    if filesystem ~= "tmpfs" and filesystem ~= "dev" and filesystem ~= "run" then
                        local partition = gobject {}
                        partition.filesystem = filesystem
                        partition.size = size
                        partition.used = used
                        partition.avail = avail
                        partition.perc = perc
                        partition.mount = mount

                        if ret._private.partition[partition.mount] == nil then
                            ret._private.partition[partition.mount] = partition
                            ret:emit_signal("partition", partition)
                        else
                            ret._private.partition[partition.mount]:emit_signal("update", partition)
                        end
                    end
                end
            end)
        end
    }

    return ret
end

if not instance then
    instance = new()
end
return instance
