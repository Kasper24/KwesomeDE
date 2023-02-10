-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gtimer = require("gears.timer")
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

local function add_titlebar(client, preview)
    client.titlebar_preview = wibox.widget {
        widget = wibox.widget.imagebox,
        horizontal_fit_policy = "fit",
        vertical_fit_policy = "fit",
        image = wibox.widget.draw_to_image_surface(client.titlebar_widget.widget, client.width, client.titlebar_size)
    }

    preview:insert(1, client.titlebar_preview)
end

local function new(client)
    local preview_image = wibox.widget {
        widget = wibox.widget.imagebox,
    }

    local preview = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        preview_image
    }

    local fake_preview = wibox.widget {
        widget = cfiwidget,
        forced_width = dpi(300),
        forced_height = dpi(300),
        halign = "center",
        valign = "center",
        size = client.font_icon.size * 2,
        client = client
    }

    local widget = fake_preview

    if client.titlebar_enabled or client.custom_titlebar then
        add_titlebar(client, preview)
    end

    client:connect_signal("property::titlebar_enabled", function(client)
        if client.titlebar_enabled then
            add_titlebar(client, preview)
        else
            preview:remove_widgets(client.titlebar_preview)
        end
    end)

    client:connect_signal("focus", function(client)
        if preview_image.image == nil then
            gtimer {
                timeout = 0.2,
                single_shot = true,
                autostart = true,
                call_now = false,
                callback = function()
                    preview_image.image = get_client_thumbnail(client)
                    widget = preview
                end
            }
        end
    end)

    local thumbnail = get_client_thumbnail(client)
    if thumbnail then
        preview_image.image = get_client_thumbnail(client)
        widget = preview
    end

    return widget
end

function client_thumbnail.mt:__call(...)
    return new(...)
end

return setmetatable(client_thumbnail, client_thumbnail.mt)
