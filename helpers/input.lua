local awful = require("awful")
local gtimer = require("gears.timer")
local tostring = tostring
local capi = {
    mouse = mouse,
    root = root
}

local _input = {}

function _input.send_key(c, key)
    awful.spawn.with_shell("xdotool key --window " .. tostring(c.window) .. " " .. key)
end

function _input.send_key_sequence(c, seq)
    awful.spawn.with_shell("xdotool type --delay 5 --window " .. tostring(c.window) .. " " .. seq)
end

function _input.tap_or_drag(args)
    local old_coords = capi.mouse.coords()
    gtimer {
        timeout = 0.2,
        call_now = false,
        autostart = true,
        single_shot = true,
        callback = function()
            local new_coords = capi.mouse.coords()
            if new_coords.x ~= old_coords.x or new_coords.y ~= old_coords.y then
                args.on_drag()
            else
                args.on_tap()
            end
        end
    }
end

return _input
