-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local twidget = require("presentation.ui.widgets.text")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local client_thumbnail = { mt = {} }

local function get_client_thumbnail(client)
    local screenshot = awful.screenshot {
        client = client,
    }
    screenshot:refresh()

    -- Thumbnails for clients with custom titlebars, i.e welcome/screenshot/record/theme manager
    -- won't work correctly since all the UI is hacked on with the titlebars which aren't included
    -- when taking a screenshot with awful.screenshot
    if client:isvisible() and client.custom_titlebar ~= true then

        client.thumbnail = screenshot.surface
    end

    if client.thumbnail == nil then
        return { font_icon = beautiful.get_font_icon_for_app_name(client.class) }
    else
        return { thumbnail = client.thumbnail }
    end
end

local function new(client, color)
    local thumbnail = get_client_thumbnail(client)
    local widget = thumbnail.thumbnail and
        wibox.widget {
            widget = wibox.widget.imagebox,
            horizontal_fit_policy = "fit",
            vertical_fit_policy = "fit",
            image = thumbnail.thumbnail
        } or
        twidget {
            forced_width = dpi(300),
            forced_height = dpi(300),
            halign = "center",
            valign = "center",
            color = color or beautiful.random_accent_color(),
            font = thumbnail.font_icon.font,
            size = 50,
            text = thumbnail.font_icon.icon
        }

	return widget
end

function client_thumbnail.mt:__call(...)
    return new(...)
end

return setmetatable(client_thumbnail, client_thumbnail.mt)