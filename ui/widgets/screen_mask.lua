-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local theme_daemon = require("daemons.system.theme")
local beautiful = require("beautiful")
local setmetatable = setmetatable
local capi = {
    awesome = awesome
}

local screen_mask = {
    mt = {}
}

function screen_mask.background(screen)
    local background = wibox.widget {
        widget = wibox.widget.imagebox,
        resize = true,
        horizontal_fit_policy = "fit",
        vertical_fit_policy = "fit",
        image = theme_daemon:get_wallpaper()
    }

    local blur = wibox.widget {
        widget = wibox.container.background,
        bg = beautiful.colors.background
    }

    return awful.popup {
        type = "splash",
        screen = screen,
        placement = awful.placement.maximize,
        visible = false,
        ontop = true,
        widget = {
            widget = wibox.layout.stack,
            background,
            blur
        }
    }
end

function screen_mask.color(screen)
    local popup = awful.popup {
        type = "splash",
        screen = screen,
        placement = awful.placement.maximize,
        visible = false,
        ontop = true,
        bg = beautiful.colors.background_with_opacity
    }

    capi.awesome.connect_signal("colorscheme::changed", function( old_colorscheme_to_new_map)
        popup.bg = old_colorscheme_to_new_map[beautiful.colors.background]
    end)

    return popup
end

function screen_mask.mt:__call(...)
    return screen_mask.color(...)
end

return setmetatable(screen_mask, screen_mask.mt)
