-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
-- local awful = require("awful")
local gtable = require("gears.table")
-- local gsurface = require("gears.surface")
local wibox = require("wibox")
local beautiful = require("beautiful")
local cfiwidget = require("ui.widgets.client_font_icon")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local client_thumbnail = {
    mt = {}
}

-- function client_thumbnail:set_client(client)
    -- local fake_preview = self:get_children_by_id("fake_preview")[1]
    -- local preview = self:get_children_by_id("preview")[1]

    -- self:set_client(client)
    -- self:set_scale(2)

    -- Real previews disabled until I can stop it from hogging the RAM

    -- local titlebar_preview = wibox.widget {
    --     widget = wibox.widget.imagebox,
    --     -- Prevernts the titlebar from staying too wide when the client is small
    --     -- 500 was choosen randmoly
    --     forced_width = client.width - 500,
    --     horizontal_fit_policy = "fit",
    --     vertical_fit_policy = "fit",
    -- }

    -- local path = "/tmp/task_preview_" .. client.window .. ".png"

    -- if client.titlebar_enabled or client.custom_titlebar then
    --     titlebar_preview.image = wibox.widget.draw_to_image_surface(
    --         client.titlebar_widget.widget,
    --         client.width,
    --         client.titlebar_size
    --     )
    --     preview:insert(1, titlebar_preview)
    -- end

    -- client:connect_signal("property::titlebar_enabled", function(client)
    --     if client.titlebar_enabled then
    --         titlebar_preview.image = wibox.widget.draw_to_image_surface(
    --             client.titlebar_widget.widget,
    --             client.width,
    --             client.titlebar_size
    --         )
    --         preview:insert(1, titlebar_preview)
    --     else
    --         preview:remove(1)
    --     end
    -- end)

    -- if client:isvisible() then
    --     awful.spawn.easy_async("maim -i " .. client.window .. " " .. path, function()
    --         client.thumbnail = path
    --         preview:get_children_by_id("image")[1]:emit_signal("widget::redraw_needed")
    --         self:raise_widget(preview)
    --     end)
    -- end

    -- if client.thumbnail then
    --     self:raise_widget(preview)
    -- end
-- end

local function new()
    local widget = wibox.widget {
        widget = cfiwidget,
        id = "fake_preview",
        forced_width = dpi(300),
        forced_height = dpi(300),
        halign = "center",
        valign = "center",
        scale = 2,
    }

    -- local widget = wibox.widget {
    --     layout = wibox.layout.stack,
    --     {
    --         widget = cfiwidget,
    --         id = "fake_preview",
    --         forced_width = dpi(300),
    --         forced_height = dpi(300),
    --         halign = "center",
    --         valign = "center",
    --     },
    --     {
    --         layout = wibox.layout.fixed.vertical,
    --         id = "preview",
    --         {
    --             widget = wibox.container.constraint,
    --             mode = "max",
    --             width = dpi(300),
    --             {
    --                 widget = wibox.widget.imagebox,
    --                 id = "image",
    --             }
    --         }
    --     }
    -- }
    gtable.crush(widget, client_thumbnail, true)

    return widget
end

function client_thumbnail.mt:__call(...)
    return new(...)
end

return setmetatable(client_thumbnail, client_thumbnail.mt)
