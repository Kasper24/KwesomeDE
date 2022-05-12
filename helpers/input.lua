local awful = require("awful")
local gtimer = require("gears.timer")
local tostring = tostring
local capi = { root = root }

local _input = {}

function _input.send_key(c, key)
    awful.spawn.with_shell("xdotool key --window " .. tostring(c.window) .. " " .. key)
end

function _input.send_key_sequence(c, seq)
    awful.spawn.with_shell("xdotool type --delay 5 --window " .. tostring(c.window) .. " " .. seq)
end

local double_tap_timer = nil
function _input.single_double_tap(single_tap_function, double_tap_function)
    if double_tap_timer then
        double_tap_timer:stop()
        double_tap_timer = nil
        double_tap_function()
        return
    end

    double_tap_timer = gtimer.start_new(0.20, function()
        double_tap_timer = nil
        if single_tap_function then
            single_tap_function()
        end
        return false
    end)
end

function _input.fake_escape()
    capi.root.fake_input("key_press", "Escape")
    capi.root.fake_input("key_release", "Escape")
end

return _input