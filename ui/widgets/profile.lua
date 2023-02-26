-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local theme_daemon = require("daemons.system.theme")
local setmetatable = setmetatable

local profile = {
    mt = {}
}

local function new()
    local widget = wibox.widget.imagebox(theme_daemon:get_profile_image())

    theme_daemon:connect_signal("profile_image", function()
        widget.image = theme_daemon:get_profile_image()
    end)

    return widget
end

function profile.mt:__call(...)
    return new(...)
end

return setmetatable(profile, profile.mt)
