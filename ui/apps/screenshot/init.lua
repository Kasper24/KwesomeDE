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
        width = dpi(560),
        height = dpi(280),
    }
    local stack = wibox.layout.stack()
    stack:set_top_only(true)
    stack:add(require(path .. ".main")(app, stack))
    stack:add(require(path .. ".settings")(stack))
    app:set_widget(stack)

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
