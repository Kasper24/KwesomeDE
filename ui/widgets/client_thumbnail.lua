-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gsurface = require("gears.surface")
local wibox = require("wibox")
local beautiful = require("beautiful")
local cfiwidget = require("ui.widgets.client_font_icon")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local client_thumbnail = {
    mt = {}
}

local function add_titlebar(client, preview)
    client.titlebar_preview = wibox.widget {
        widget = wibox.widget.imagebox,
        -- Prevernts the titlebar from staying too wide when the client is small
        -- 500 was choosen randmoly
        forced_width = client.width - 500,
        horizontal_fit_policy = "fit",
        vertical_fit_policy = "fit",
        image = wibox.widget.draw_to_image_surface(client.titlebar_widget.widget, client.width, client.titlebar_size)
    }

    preview:insert(1, client.titlebar_preview)
end

local function new(client)
    -- local path = "/tmp/task_preview_" .. client.window .. ".png"

    local preview_image = wibox.widget {
        widget = wibox.widget.imagebox,
        -- image = gsurface.load_uncached(path)
    }

    local preview = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        {
            widget = wibox.container.constraint,
            mode = "max",
            width = dpi(300),
            preview_image
        }
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

    -- if client:isvisible() then
    --     awful.spawn.easy_async("maim -i " .. client.window .. " " .. path, function()
    --         client.thumbnail = path
    --         preview_image:emit_signal("widget::redraw_needed")
    --     end)
    --     widget = preview
    -- end

    -- if client.thumbnail then
    --     widget = preview
    -- end

    return widget
end

function client_thumbnail.mt:__call(...)
    return new(...)
end

return setmetatable(client_thumbnail, client_thumbnail.mt)
