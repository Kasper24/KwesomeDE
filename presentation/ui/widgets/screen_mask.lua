-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local theme_daemon = require("daemons.system.theme")
local beautiful = require("beautiful")
local setmetatable = setmetatable

local screen_mask = { mt = {} }

function screen_mask.background(screen)
    local background = wibox.widget
    {
        widget = wibox.widget.imagebox,
        resize = true,
        horizontal_fit_policy = "fit",
        vertical_fit_policy = "fit",
        image = theme_daemon:get_wallpaper()
    }

    local blur = wibox.widget
    {
        widget = wibox.container.background,
        bg = beautiful.colors.background ,
    }

    return awful.popup
    {
        type = "splash",
        screen = screen,
        placement = awful.placement.maximize,
        visible = false,
        ontop = true,
        widget =
        {
            widget = wibox.layout.stack,
            background,
            blur,
        }
    }
end

function screen_mask.color(screen)
    return awful.popup
    {
        type = "splash",
        screen = screen,
        placement = awful.placement.maximize,
        visible = false,
        ontop = true,
        bg = beautiful.colors.background .. 80
    }
end

function screen_mask.mt:__call(...)
    return screen_mask.color(...)
end

return setmetatable(screen_mask, screen_mask.mt)