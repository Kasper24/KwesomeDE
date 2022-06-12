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

local redshift = { }
local instance = nil

local UPDATE_INTERVAL = 1

local state = -1

function redshift:turn_on()
    helpers.run.check_if_running("redshift", nil,
    function()
        awful.spawn.with_shell("redshift -l 0:0 -t 4500:4500 -r &>/dev/null &")
        settings:set_value("blue_light", true)
    end)
end

function redshift:turn_off()
    helpers.run.check_if_running("redshift", function()
        awful.spawn.with_shell("redshift -x && pkill redshift && killall redshift")
        settings:set_value("blue_light", false)
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
        if settings:get_value("blue_light") == true then
            ret:turn_on()
        elseif settings:get_value("blue_light") == false then
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