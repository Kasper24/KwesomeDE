-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local theme_daemon = require("daemons.system.theme")
local setmetatable = setmetatable
local capi = {
    awesome = awesome
}

local wallpaper = {
    mt = {}
}

local function new()
    local widget = wibox.widget {
        widget = wibox.widget.imagebox,
        resize = true,
        horizontal_fit_policy = "fit",
        vertical_fit_policy = "fit",
        image = theme_daemon:get_wallpaper()
    }

    capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
        widget.image = theme_daemon:get_wallpaper()
    end)

    return widget
end

function wallpaper.mt:__call(...)
    return new(...)
end

return setmetatable(wallpaper, wallpaper.mt)
