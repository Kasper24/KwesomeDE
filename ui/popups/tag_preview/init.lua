-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local awful = require("awful")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("ui.widgets")
local theme_daemon = require("daemons.system.theme")
local library = require("library")
local dpi = beautiful.xresources.apply_dpi
local capi = {
    screen = screen,
    client = client,
    tag = tag
}

local tag_preview = {}
local instance = nil

local function save_tag_thumbnail(tag)
    if tag.selected == true then
        local screen = awful.screen.focused()
        local geo = screen.geometry
        tag.thumbnail = library.ui.scale_image(screen.content, 300, 150, geo.width, geo.height)
    end
end

function tag_preview:show(t, args)
    args = args or {}

    args.coords = args.coords or self.coords
    args.wibox = args.wibox
    args.widget = args.widget
    args.offset = args.offset or {}

    if not args.coords and args.wibox and args.widget then
        args.coords = library.ui.get_widget_geometry_in_device_space({wibox = args.wibox}, args.widget)
    end

    self.x = args.coords.x + (args.offset.x or 0)
    self.y = args.coords.y + (args.offset.y or 0)

    save_tag_thumbnail(t)
    if t.thumbnail then
        self.widget.image = t.thumbnail
    else
        self.widget.image = self.default_thumbnail
    end
    self.visible = true
end

function tag_preview:hide()
    self.visible = false
end

function tag_preview:toggle(t, args)
    if self.visible == true then
        self:hide()
    else
        self:show(t, args)
    end
end

local function new()
    -- local default_thumbnail = library.ui.scale_image(theme_daemon:get_wallpaper_path(), 300, 150)
    -- local thumbnail = wibox.widget {
    --     widget = wibox.widget.imagebox,
    --     forced_width = dpi(300),
    --     forced_height = dpi(150),
    --     horizontal_fit_policy = "fit",
    --     vertical_fit_policy = "fit",
    --     image = default_thumbnail,
    --     default_thumbnail = default_thumbnail
    -- }

    -- local widget = widgets.popup {
    --     visible = false,
    --     ontop = true,
    --     shape = library.ui.rrect(),
    --     maximum_width = dpi(300),
    --     maximum_height = dpi(150),
    --     animate_method = "width",
    --     bg = beautiful.colors.background,
    --     widget = thumbnail
    -- }
    -- widget.default_thumbnail = library.ui.scale_image(theme_daemon:get_wallpaper_path(), 300, 150)

    -- gtable.crush(widget, tag_preview, true)

    -- capi.client.connect_signal("property::fullscreen", function(c)
    --     if c.fullscreen then
    --         widget:hide()
    --     end
    -- end)

    -- capi.client.connect_signal("focus", function(c)
    --     if c.fullscreen then
    --         widget:hide()
    --     end
    -- end)

    -- capi.tag.connect_signal("property::selected", function(t)
    --     -- Wait a little bit so it won't screenshot the previous tag
    --     gtimer.start_new(0.4, function()
    --         save_tag_thumbnail(t)
    --         return false
    --     end)
    -- end)

    -- return widget
end

if not instance then
    instance = new()
end
return instance
