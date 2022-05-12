local awful = require("awful")
local gtimer = require("gears.timer")
local math = math
local os = os
local capi = { awesome = awesome, client = client }

local _misc = {}

function _misc.is_restart()
    capi.awesome.register_xproperty("is_restart", "boolean")
    local restart_detected = capi.awesome.get_xproperty("is_restart") ~= nil
    capi.awesome.set_xproperty("is_restart", true)

    return restart_detected
end

function _misc.tag_back_and_forth(tag_index)
    local s = awful.screen.focused()
    local tag = s.tags[tag_index]
    if tag then
        if tag == s.selected_tag then
            awful.tag.history.restore()
        else
            tag:view_only()
        end

        local urgent_clients = function(c)
            return awful.rules.match(c, {urgent = true, first_tag = tag})
        end

        for c in awful.client.iterate(urgent_clients) do
            capi.client.focus = c
            c:raise()
        end
    end
end

function _misc.round(number, decimals)
    local power = 10 ^ decimals
    return math.floor(number * power) / power
end

function _misc.round_by_factor(number, factor)
    return math.floor(number / factor + 0.5) * factor
end

function _misc.sleep(time)
    local t = os.clock()
    while os.clock() - t <= time do
      -- nothing
    end
end

local show = false
gtimer { timeout = 5, autostart = true, call_now = false, single_shot = true, callback = function()
    show = true
end }

function _misc.should_show_notification()
    return show
end

function _misc.convert_range(old_value, old_min, old_max, new_min, new_max)
    return ( (old_value - old_min) / (old_max - old_min) ) * (new_max - new_min) + new_min
end

return _misc