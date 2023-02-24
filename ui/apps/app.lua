-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local ruled = require("ruled")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local helpers = require("helpers")
local capi = {
    awesome = awesome
}

local app = {
    mt = {}
}
function app:show()
    helpers.client.run_or_raise({
        class = self._private.class
    }, true, self._private.command, {shell = true})
end

function app:hide()
    if self._private.client ~= nil then
        self._private.client:kill()
    end
    self._private.visible = false
end

function app:toggle()
    if self._private.visible == true then
        self:hide()
    else
        self:show()
    end
end

function app:get_client()
    return self._private.client
end

function app:set_hidden(hidden)
    local client = self:get_client()
    if client then
        client.hidden = hidden
    end
end

function app:set_widget(widget)
    self._private.widget = widget
end

local function new(args)
    local ret = gobject {}
    gtable.crush(ret, app, true)

    ret._private = {}

    ret._private.title =args.title or ""
    ret._private.class = args.class or ""
    ret._private.width = args.width or nil
    ret._private.height = args.height or nil
    ret._private.widget = args.widget or nil
    ret._private.command = string.format([[ lua -e "
    local lgi = require 'lgi'
    local Gtk = lgi.require('Gtk', '3.0')

    -- Create top level window with some properties and connect its 'destroy'
    -- signal to the event loop termination.
    local window = Gtk.Window {
    title = '%s',
    default_width = 0,
    default_height = 0,
    on_destroy = Gtk.main_quit
    }

    if tonumber(Gtk._version) >= 3 then
    window.has_resize_grip = true
    end

    window:set_wmclass('%s', '%s')

    -- Show window and start the loop.
    window:show_all()
    Gtk.main()
"
]], ret._private.title, ret._private.class, ret._private.class)

    ruled.client.connect_signal("request::rules", function()
        ruled.client.append_rule {
            rule = {
                class = ret._private.class
            },
            properties = {
                floating = true,
                width = ret._private.width,
                height = 1,
                placement = awful.placement.centered
            },
            callback = function(c)
                ret._private.client = c

                c:connect_signal("unmanage", function()
                    ret._private.visible = false
                    ret._private.client = nil
                end)

                c.custom_titlebar = true
                c.can_resize = false
                c.can_tile = false

                -- Settings placement in properties doesn't work
                c.x = (c.screen.geometry.width / 2) - (ret._private.width / 2)
                c.y = (c.screen.geometry.height / 2) - (ret._private.height / 2)

                ret._private.titlebar = widgets.titlebar(c, {
                    position = "top",
                    size = ret._private.height,
                    bg = beautiful.colors.background
                })
                ret._private.titlebar:setup{
                    widget = ret._private.widget
                }

                capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
                    ret._private.titlebar:set_bg(beautiful.colors.background)
                end)

                c:connect_signal("request::unmanage", function()
                    ret:emit_signal("visibility", false)
                end)

                ret._private.visible = true
                ret:emit_signal("visibility", true)
            end
        }
    end)

    return ret
end

function app.mt:__call(...)
    return new(...)
end

return setmetatable(app, app.mt)