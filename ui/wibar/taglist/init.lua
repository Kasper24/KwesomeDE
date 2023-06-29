local ui_daemon = require("daemons.system.ui")

local circle = require(... .. ".circle")
local icon = require(... .. ".icon")

local taglist = {
    mt = {}
}

local function new(screen)
    if ui_daemon:get_icon_taglist() then
        return icon(screen)
    else
        return circle(screen)
    end

end

function taglist.mt:__call(...)
    return new(...)
end

return setmetatable(taglist, taglist.mt)
