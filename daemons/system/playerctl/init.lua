-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local gdebug = require("gears.debug")
local bling = require("external.bling")

local instance = nil

local function new()
    local _playerctl_status, Playerctl = pcall(function()
        return require("lgi").Playerctl
    end)
    if not _playerctl_status or not Playerctl then
        gdebug.print_warning(
            "Can't load Playerctl introspection. "..
            "Seems like Playerctl is not installed or `lua-lgi` was built with an incompatible Playerctl version. " ..
            "Using playerctl cli instead!"
        )
        return bling.signal.playerctl.cli {
            update_on_activity = true,
            player = {"spotify", "%any", "mopidy"},
            debounce_delay = 1
        }
    else
        return bling.signal.playerctl.lib {
            update_on_activity = true,
            player = {"spotify", "%any", "mopidy"},
            debounce_delay = 1
        }
    end
end

if not instance then
    instance = new()
end
return instance
