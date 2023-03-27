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
local main = require(path .. ".main")

local function new()
    local app = app {
        title ="Settings",
        class = "Settings",
    }

    app:connect_signal("init", function(self, visible)
        app:set_width(app:get_client().screen.geometry.width * 0.9)
        app:set_height(app:get_client().screen.geometry.height * 0.9)
    end)

    local first = true
    app:connect_signal("visibility", function(self, visible)
        if visible == true and first == true then
            local widget = wibox.widget {
                widget = wibox.container.margin,
                margins = dpi(15),
                main(app)
            }

            app:set_widget(widget)
            first = false
        end
    end)

    return app
end

if not instance then
    instance = new()
end
return instance
