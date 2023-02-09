-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local cfiwidget = require("ui.widgets.client_font_icon")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local client_thumbnail = {
    mt = {}
}

local function get_client_thumbnail(client)
    -- Thumbnails for clients with custom titlebars, i.e welcome/screenshot/record/theme manager
    -- won't work correctly since all the UI is hacked on with the titlebars which aren't included
    -- when taking a screenshot with awful.screenshot
    if client:isvisible() then
        local screenshot = awful.screenshot {
            client = client
        }
        screenshot:refresh()
        client.thumbnail = screenshot.surface
    end

    return client.thumbnail
end

local function new(client)
    local thumbnail = get_client_thumbnail(client)
    local widget = thumbnail and wibox.widget {
        layout = wibox.layout.fixed.vertical,
        client.titlebar and {
            widget = wibox.widget.imagebox,
            horizontal_fit_policy = "fit",
            vertical_fit_policy = "fit",
            image = wibox.widget.draw_to_image_surface(client.titlebar.widget, client.width, client.titlebar_size)
        } or nil,
        {
            widget = wibox.widget.imagebox,
            horizontal_fit_policy = "fit",
            vertical_fit_policy = "fit",
            image = thumbnail
        }
    } or wibox.widget {
        widget = cfiwidget,
        forced_width = dpi(300),
        forced_height = dpi(300),
        halign = "center",
        valign = "center",
        size = client.font_icon.size * 2,
        client = client
    }

    return widget
end

function client_thumbnail.mt:__call(...)
    return new(...)
end

return setmetatable(client_thumbnail, client_thumbnail.mt)
