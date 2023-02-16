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

    gtimer.poller {
        timeout = 1800,
        callback = function()
            awful.spawn.easy_async_with_shell("df | tail -n +2", function(stdout)
                local disks = {}

                for line in stdout:gmatch("[^\r\n$]+") do
                    local filesystem, size, used, avail, perc, mount = line:match(
                        "([%p%w]+)%s+([%d%w]+)%s+([%d%w]+)%s+([%d%w]+)%s+([%d]+)%%%s+([%p%w]+)")

                    if filesystem ~= "tmpfs" and filesystem ~= "dev" and filesystem ~= "run" then
                        local disk = {}
                        disk.filesystem = filesystem
                        disk.size = size
                        disk.used = used
                        disk.avail = avail
                        disk.perc = perc
                        disk.mount = mount
                        table.insert(disks, disk)
                    end
                end

                ret:emit_signal("update", disks)
            end)
        end
    }

    return ret
end

if not instance then
    instance = new()
end
return instance
