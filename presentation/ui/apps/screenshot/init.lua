-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local ruled = require("ruled")
local wibox = require("wibox")
local beautiful = require("beautiful")
local screenshot_daemon = require("daemons.system.screenshot")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi

local screenshot = { }
local instance = nil

local path = ...

local window = [[ lua -e "
    local lgi = require 'lgi'
    local Gtk = lgi.require('Gtk', '3.0')

    -- Create top level window with some properties and connect its 'destroy'
    -- signal to the event loop termination.
    local window = Gtk.Window {
        name = 'Screenshot',
    title = 'no-one-gonna-match-this1',
    default_width = 0,
    default_height = 0,
    on_destroy = Gtk.main_quit
    }

    if tonumber(Gtk._version) >= 3 then
    window.has_resize_grip = true
    end

    local icon = 'camera'
    pixbuf24 = Gtk.IconTheme.get_default():load_icon(icon, 24, 0)
    pixbuf32 = Gtk.IconTheme.get_default():load_icon(icon, 32, 0)
    pixbuf48 = Gtk.IconTheme.get_default():load_icon(icon, 48, 0)
    pixbuf64 = Gtk.IconTheme.get_default():load_icon(icon, 64, 0)
    pixbuf96 = Gtk.IconTheme.get_default():load_icon(icon, 96, 0)
    window:set_icon_list({pixbuf24, pixbuf32, pixbuf48, pixbuf64, pixbuf96});

    window:set_wmclass('Screenshot', 'Screenshot')

    -- Show window and start the loop.
    window:show_all()
    Gtk.main()
"
]]

function screenshot:show()
    helpers.client.run_or_raise({class = "Screenshot"}, false, window, { switchtotag = true })
    self._private.visible = true
end

function screenshot:hide()
    self._private.client:kill()
    self._private.visible = false
end

function screenshot:toggle()
    if self._private.visible == true then
        self:hide()
    else
        self:show()
    end
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, screenshot, true)

    ret._private = {}

    local stack = wibox.layout.stack()
    stack:set_top_only(true)
    stack:add(require(path .. ".main")(ret, stack))
    stack:add(require(path .. ".settings")(stack))

    ruled.client.connect_signal("request::rules", function()
        ruled.client.append_rule
        {
            rule = { name = "no-one-gonna-match-this1" },
            properties = { floating = true, width = dpi(550), height = 1, placement = awful.placement.centered },
            callback = function(c)
                ret._private.client = c

                c:connect_signal("unmanage", function()
                    ret._private.visible = false
                    ret._private.client = nil
                end)

                c.can_resize = false
                c.custom_titlebar = false
                c.can_tile = false

                -- Settings placement in properties doesn't work
                c.x = (c.screen.geometry.width / 2) - (dpi(550) / 2)
                c.y = (c.screen.geometry.height / 2) - (dpi(280) / 2)

                awful.titlebar(c,
                {
                    position = "top",
                    size = dpi(280),
                    bg = beautiful.colors.background
                }) : setup
                {
                    widget = stack
                }
            end
        }
    end)

    screenshot_daemon:connect_signal("started", function()
        ret._private.client.hidden = true
    end)

    screenshot_daemon:connect_signal("ended", function()
        ret._private.client.hidden = false
    end)

    screenshot_daemon:connect_signal("error::create_file", function()
        ret._private.client.hidden = false
    end)

    screenshot_daemon:connect_signal("error::create_directory", function()
        ret._private.client.hidden = false
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance