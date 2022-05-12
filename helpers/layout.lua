local awful = require("awful")
local settings = require("services.settings")
local tonumber = tonumber

local _layout = {}

function _layout.resize_gaps(amt)
    local t = awful.screen.focused().selected_tag
    t.gap = t.gap + tonumber(amt)
    awful.layout.arrange(awful.screen.focused())
    settings:set_value("useless_gap", t.gap)
end

function _layout.resize_padding(amt)
    local s = awful.screen.focused()
    local l = s.padding.left
    local r = s.padding.right
    local t = s.padding.top
    local b = s.padding.bottom
    s.padding =
    {
        left = l + amt,
        right = r + amt,
        top = t + amt,
        bottom = b + amt
    }
    awful.layout.arrange(awful.screen.focused())
end

return _layout