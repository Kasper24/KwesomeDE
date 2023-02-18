-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local pwidget = require("ui.widgets.popup")
local bwidget = require("ui.widgets.background")
local wwidget = require("ui.widgets.wallpaper")
local setmetatable = setmetatable

local screen_mask = {
    mt = {}
}

local function new(screen)
    local blur = wibox.widget {
        widget = bwidget,
        bg = beautiful.colors.background_blur
    }

    return pwidget {
        screen = screen,
        placement = awful.placement.maximize,
        visible = false,
        ontop = true,
        widget = {
            widget = wibox.layout.stack,
            wwidget,
            blur
        }
    }
end

function screen_mask.mt:__call(...)
    return new(...)
end

return setmetatable(screen_mask, screen_mask.mt)
