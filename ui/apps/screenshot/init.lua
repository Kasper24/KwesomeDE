-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local ruled = require("ruled")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local app = require("ui.apps.app")
local beautiful = require("beautiful")
local screenshot_daemon = require("daemons.system.screenshot")
local dpi = beautiful.xresources.apply_dpi
local capi = {
    awesome = awesome
}

local instance = nil

local path = ...

local function new()
    local app = app {
        title ="Screenshot",
        class = "Screenshot",
        width = dpi(420),
        height = dpi(280),
    }
    local stack = wibox.layout.stack()
    stack:set_top_only(true)
    stack:add(require(path .. ".main")(app, stack))
    stack:add(require(path .. ".settings")(stack))
    app:set_widget(stack)


    ruled.client.connect_signal("request::rules", function()
        ruled.client.append_rule {
            rule = {
                class = "awesome-app-screenshot"
            },
            properties = {
                floating = true,
                width = dpi(420),
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
                c.x = (c.screen.geometry.width / 2) - (dpi(550) / 2)
                c.y = (c.screen.geometry.height / 2) - (dpi(280) / 2)

                local titlebar = widgets.titlebar(c, {
                    position = "top",
                    size = dpi(280),
                    bg = beautiful.colors.background
                })
                titlebar:setup{widget = stack}

                capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
                    titlebar:set_bg(beautiful.colors.background)
                end)

                ret._private.visible = true
                ret:emit_signal("visibility", true)
            end
        }
    end)

    screenshot_daemon:connect_signal("started", function()
        app:set_hidden(true)
    end)

    screenshot_daemon:connect_signal("ended", function()
        app:set_hidden(false)
    end)

    screenshot_daemon:connect_signal("error::create_file", function()
        app:set_hidden(false)
    end)

    screenshot_daemon:connect_signal("error::create_directory", function()
        app:set_hidden(false)
    end)

    return app
end

if not instance then
    instance = new()
end
return instance
