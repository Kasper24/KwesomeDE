-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local helpers = require("helpers")
local tonumber = tonumber
local string = string

local cpu = { }
local instance = nil

local UPDATE_INTERVAL = 5

local function update(self)
    awful.spawn.easy_async_with_shell([[ grep '^cpu.' /proc/stat; ps -eo '%p|%c|%C|' -o "%mem" -o '|%a' --sort=-%cpu | head -11 | tail -n +2 ]], function(stdout)
        local cpus = {}
        local processes = {}

        local i = 1
        local j = 1
        for line in stdout:gmatch("[^\r\n]+") do
            if line:find("cpu", 1, 3) then
                if cpus[i] == nil then
                    cpus[i] = {}
                end

                local name, user, nice, system, idle, iowait, irq, softirq, steal, _, _ =
                line:match("(%w+)%s+(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)")

                local total = user + nice + system + idle + iowait + irq + softirq + steal

                local diff_idle = idle - tonumber(cpus[i]["idle_prev"] == nil and 0 or cpus[i]["idle_prev"])
                local diff_total = total - tonumber(cpus[i]["total_prev"] == nil and 0 or cpus[i]["total_prev"])
                local diff_usage = (1000 * (diff_total - diff_idle) / diff_total + 5) / 10

                cpus[i]["total_prev"] = total
                cpus[i]["idle_prev"] = idle
                cpus[i]["diff_usage"] = diff_usage
                cpus[i]["name"] = name:upper()

                i = i + 1
            else
                if processes[j] == nil then
                    processes[j] = {}
                end

                local columns = helpers.string.split(line, "|")

                processes[j].pid = columns[1]:gsub("%s+", "")
                processes[j].comm = columns[2]
                processes[j].cpu = columns[3]
                processes[j].mem = columns[4]
                processes[j].cmd = columns[5]

                j = j + 1
            end
        end

        self:emit_signal("update::full", cpus, processes)
    end)
end

local function slim_update(self)
    awful.spawn.easy_async_with_shell([[ top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}' ]], function(stdout)
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
    local ret = gobject{}
    gtable.crush(ret, cpu, true)

    ret._private = {}
    ret._private.slim = true

    gtimer { timeout = UPDATE_INTERVAL, autostart = true, call_now = true, callback = function()
        if ret._private.slim then
            slim_update(ret)
        else
            update(ret)
        end
    end}

    return ret
end

if not instance then
    instance = new()
end
return instance