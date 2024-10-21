local awful = require("awful")
local ruled = require("ruled")
local gtimer = require("gears.timer")
local math = math
local max = math.max
local min = math.min
local os = os
local capi = {
    awesome = awesome,
    client = client
}

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
            return ruled.client.match(c, {
                urgent = true,
                first_tag = tag
            })
        end

        for c in awful.client.iterate(urgent_clients) do
            capi.client.focus = c
            c:raise()
        end
    end
end

function _misc.sleep(time)
    local t = os.clock()
    while os.clock() - t <= time do
        -- nothing
    end
end

return _misc
