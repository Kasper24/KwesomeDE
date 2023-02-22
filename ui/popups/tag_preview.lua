-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gtable = require("gears.table")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("ui.widgets")
local theme_daemon = require("daemons.system.theme")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local capi = {
    client = client,
    tag = tag
}

local tag_preview = {}
local instance = nil

local function save_tag_thumbnail(tag)
    if tag.selected == true then
        local screenshot = awful.screenshot {
            screen = awful.screen.focused()
        }
        screenshot:refresh()
        tag.thumbnail = screenshot.surface
    end
end

function tag_preview:show(t, args)
    args = args or {}

    args.coords = args.coords or self.coords
    args.wibox = args.wibox
    args.widget = args.widget
    args.offset = args.offset or {}

    if not args.coords and args.wibox and args.widget then
        args.coords = helpers.ui.get_widget_geometry(args.wibox, args.widget)
        if args.offset.x ~= nil then
            args.coords.x = args.coords.x + args.offset.x
        end
        if args.offset.y ~= nil then
            args.coords.y = args.coords.y + args.offset.y
        end

        self.x = args.coords.x
        self.y = args.coords.y
    end

    -- save_tag_thumbnail(t)
    self.widget.image = t.thumbnail or theme_daemon:get_wallpaper_surface()
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
    local thumbnail = wibox.widget {
        widget = wibox.widget.imagebox,
        forced_width = dpi(300),
        forced_height = dpi(150),
        horizontal_fit_policy = "fit",
        vertical_fit_policy = "fit",
        image = theme_daemon:get_wallpaper_surface()
    }

    local widget = widgets.popup {
        visible = false,
        ontop = true,
        shape = helpers.ui.rrect(),
        maximum_width = dpi(300),
        maximum_height = dpi(150),
        animate_method = "width",
        bg = beautiful.colors.background,
        widget = thumbnail
    }

    gtable.crush(widget, tag_preview, true)

    capi.client.connect_signal("property::fullscreen", function(c)
        if c.fullscreen then
            widget:hide()
        end
    end)

    capi.client.connect_signal("focus", function(c)
        if c.fullscreen then
            widget:hide()
        end
    end)

    capi.tag.connect_signal("property::selected", function(t)
        -- Wait a little bit so it won't screenshot the previous tag
        -- gtimer {
        --     timeout = 0.4,
        --     autostart = true,
        --     call_now = false,
        --     single_shot = true,
        --     callback = function()
        --         save_tag_thumbnail(t)
        --     end
        -- }
    end)

    return widget
end

if not instance then
    instance = new()
end
return instance
