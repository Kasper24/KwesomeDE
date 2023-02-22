-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local helpers = require("helpers")

local redshift = {}
local instance = nil

function redshift:turn_on(skip_check)
    local function turn_on()
        awful.spawn.with_shell("redshift -l 0:0 -t 4500:4500 -r &>/dev/null &")
        helpers.settings["redshift"] = true
    end

    if skip_check ~= true then
        helpers.run.is_running("redshift", function(is_running)
            if is_running == false then
                turn_on()
            end
        end)
    else
        turn_on()
    end
end

function redshift:turn_off(skip_check)
    local function turn_off()
        awful.spawn.with_shell("redshift -x && pkill redshift && killall redshift")
        helpers.settings["redshift"] = false
    end

    if skip_check ~= true then
        helpers.run.is_running("redshift", function(is_running)
            if is_running == true then
                turn_off()
            end
        end)
    else
        turn_off()
    end
end

function redshift:toggle()
    helpers.run.is_running("redshift", function(is_running)
        if is_running == true then
            self:turn_off(true)
        else
            self:turn_on(true)
        end
    end)
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, redshift, true)

    ret._private = {}
    ret._private.state = -1

    gtimer.delayed_call(function()
        if helpers.settings["redshift"] == true then
            ret:turn_on()
        elseif helpers.settings["redshift"] == false then
            -- ret:turn_off()
        end

        gtimer.poller {
            timeout = 5,
            callback = function()
                helpers.run.is_running("redshift", function(is_running)
                    if is_running == true and ret._private.state ~= true then
                        ret:emit_signal("update", true)
                        ret._private.state = true
                    end
                    if is_running == false and ret._private.state ~= false then
                        ret:emit_signal("update", false)
                        ret._private.state = false
                    end
                end)
            end
        }
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance
