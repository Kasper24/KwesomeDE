-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local helpers = require("helpers")

local redshift = { }
local instance = nil

local UPDATE_INTERVAL = 1

local state = -1

function redshift:turn_on()
    helpers.run.check_if_running("redshift", nil,
    function()
        awful.spawn.with_shell("redshift -l 0:0 -t 4500:4500 -r &>/dev/null &")
        helpers.settings:set_value("redshift", true)
    end)
end

function redshift:turn_off()
    helpers.run.check_if_running("redshift", function()
        awful.spawn.with_shell("redshift -x && pkill redshift && killall redshift")
        helpers.settings:set_value("redshift", false)
    end, nil)
end

function redshift:toggle()
    helpers.run.check_if_running("redshift", function()
        self:turn_off()
    end,
    function()
        self:turn_on()
    end)
end

local function is_running(self)
    helpers.run.check_if_running("redshift", function()
        if state ~= true then
            self:emit_signal("update", true)
            state = true
        end
    end,
    function()
        if state ~= false then
            self:emit_signal("update", false)
            state = false
        end
    end)
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, redshift, true)

    gtimer.delayed_call(function()
        if helpers.settings:get_value("redshift") == true then
            ret:turn_on()
        elseif helpers.settings:get_value("redshift") == false then
            -- ret:turn_off()
        end

        gtimer { timeout = UPDATE_INTERVAL, autostart = true, call_now = true, callback = function()
            is_running(ret)
        end}
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance