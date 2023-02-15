-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local app = require("ui.apps.app")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

local instance = nil

local path = ...

local function new()
    local app = app {
        title ="Theme Manager",
        class = "Theme Manager",
        width = dpi(800),
        height = dpi(1060),
    }
    local stack = wibox.layout.stack()
    stack:set_top_only(true)
    stack:add(require(path .. ".main")(app, stack))
    stack:add(require(path .. ".settings")(stack))

    local widget = wibox.widget {
        widget = wibox.container.margin,
        margins = dpi(15),
        stack
    }

    app:set_widget(widget)

    return app
end

if not instance then
    instance = new()
end
return instance
