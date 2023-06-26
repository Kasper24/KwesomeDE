local ui_daemon = require("daemons.system.ui")

local circle = require(... .. ".circle")
local icon = require(... .. ".icon")

local taglist = {
    mt = {}
}

local function new(screen, direction)
    if ui_daemon:get_icon_taglist() then
        return icon(screen, direction)
    else
        return circle(screen, direction)
    end

end

function taglist.mt:__call(...)
    return new(...)
end

return setmetatable(taglist, taglist.mt)
