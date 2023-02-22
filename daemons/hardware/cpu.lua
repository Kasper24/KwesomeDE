-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gstring = require("gears.string")
local gtimer = require("gears.timer")
local tonumber = tonumber
local table = table
local pairs = pairs

local cpu = {}
local instance = nil

local function update(self)
    awful.spawn.easy_async_with_shell(
        [[ grep '^cpu.' /proc/stat; ps -eo '%p|%c|%C|' -o "%mem" -o '|%a' --sort=-%cpu | head -11 | tail -n +2 ]],
        function(stdout)
            local processes = {}

            local i = 1
            local j = 1
            for line in stdout:gmatch("[^\r\n]+") do
                if line:find("cpu", 1, 3) then
                    local core = gobject {}

                    local name, user, nice, system, idle, iowait, irq, softirq, steal, _, _ = line:match(
                        "(%w+)%s+(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)")

                    local total = user + nice + system + idle + iowait + irq + softirq + steal

                    local diff_idle = idle - tonumber(core["idle_prev"] == nil and 0 or core["idle_prev"])
                    local diff_total = total - tonumber(core["total_prev"] == nil and 0 or core["total_prev"])
                    local diff_usage = (1000 * (diff_total - diff_idle) / diff_total + 5) / 10

                    core["total_prev"] = total
                    core["idle_prev"] = idle
                    core["diff_usage"] = diff_usage
                    core["name"] = name:upper()

                    i = i + 1

                    if self._private.cores[i] == nil then
                        self._private.cores[i] = core
                        self:emit_signal("core", core)
                    else
                        self._private.cores[i]:emit_signal("update", core)
                    end
                else
                    local process = gobject {}

                    local columns = gstring.split(line, "|")

                    process.pid = columns[1]:gsub("%s+", "")
                    process.comm = columns[2]
                    process.cpu = columns[3]
                    process.mem = columns[4]
                    process.cmd = columns[5]

                    processes[process.pid] = process.pid

                    j = j + 1

                    if self._private.processes[j] == nil then
                        self._private.processes[j] = process
                        self:emit_signal("process", process)
                    else
                        self._private.processes[j]:emit_signal("update", process)
                    end
                end
            end

            for index, process in pairs(self._private.processes) do
                if processes[process.pid] == nil then
                    process:emit_signal("removed")
                    table.remove(self._private.processes, index)
                end
            end
        end)
end

local function slim_update(self)
    awful.spawn.easy_async_with_shell(
        [[ top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}' ]],
        function(stdout)
            stdout = stdout:gsub("%%", "")
            self:emit_signal("update::slim", tonumber(stdout))
        end)
end

function cpu:set_slim(slim)
    self._private.slim = slim

    if slim == true then
        slim_update(self)
    else
        update(self)
    end
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, cpu, true)

    ret._private = {}
    ret._private.cores = {}
    ret._private.processes = {}
    ret._private.slim = true

    local first_time = true

    gtimer.poller {
        timeout = 15,
        callback = function()
            if first_time then
                update(ret)
                slim_update(ret)
                first_time = false
                return
            end

            if ret._private.slim then
                update(ret)
            else
                slim_update(ret)
            end
        end
    }

    return ret
end

if not instance then
    instance = new()
end
return instance
