-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local bling = require("external.bling")

local instance = nil

local function new()
    return bling.signal.playerctl.lib {
        update_on_activity = true,
        player = {"spotify", "%any", "mopidy"},
        debounce_delay = 1
    }
end

if not instance then
    instance = new()
end
return instance
