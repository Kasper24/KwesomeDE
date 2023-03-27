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
    SETTINGS_APP = app {
        title ="Settings",
        class = "Settings",
        width = dpi(1650),
        height = dpi(1080),
    }

    local first = true
    SETTINGS_APP:connect_signal("visibility", function(self, visible)
        if visible == true and first == true then
            local widget = wibox.widget {
                widget = wibox.container.margin,
                margins = dpi(15),
                main(SETTINGS_APP)
            }

            SETTINGS_APP:set_widget(widget)
            first = false
        end
    end)

    return SETTINGS_APP
end

if not instance then
    instance = new()
end
return instance
