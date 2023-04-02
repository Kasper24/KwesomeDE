-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gshape = require("gears.shape")
local wibox = require("wibox")
local bwidget = require("ui.widgets.background")
local twidget = require("ui.widgets.text")
local beautiful = require("beautiful")
local ui_daemon = require("daemons.system.ui")
local setmetatable = setmetatable
local os = os

local profile = {
    mt = {}
}

local function new()
    local fake_profile = wibox.widget {
        widget = bwidget,
        shape = gshape.circle,
        bg = beautiful.icons.computer.color,
        {
            widget = twidget,
            bold = true,
            size = 10,
            color = beautiful.colors.on_accent,
            text = os.getenv("USER"):sub(1, 1):upper()
        }
    }

    local profile = wibox.widget {
        image = ui_daemon:get_profile_image()
    }

    local stack = wibox.widget {
        widget = wibox.layout.stack,
        top_only = true,
        fake_profile,
        profile
    }

    if ui_daemon:get_profile_image() then
        stack:raise_widget(profile)
    end

    ui_daemon:connect_signal("profile_image", function(self, profile_image)
        profile.image = profile_image
        stack:raise_widget(profile)
    end)

    return stack
end

function profile.mt:__call(...)
    return new(...)
end

return setmetatable(profile, profile.mt)
