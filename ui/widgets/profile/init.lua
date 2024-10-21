-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local gtable = require("gears.table")
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
    local profile_letter = wibox.widget {
        widget = bwidget,
        shape = gshape.circle,
        bg = beautiful.icons.computer.color,
        {
            widget = wibox.container.place,
            halign = "center",
            valign = "center",
            {
                widget = twidget,
                id = "profile_letter",
                bold = true,
                size = 50,
                color = beautiful.colors.on_accent,
                text = os.getenv("USER"):sub(1, 1):upper()
            }
        }
    }

    local profile = wibox.widget {
        widget = wibox.widget.imagebox,
        clip_shape = gshape.circle,
        halign = "center",
        valign = "center",
    }

    local stack = wibox.widget {
        widget = wibox.layout.stack,
        top_only = true,
        profile_letter,
        profile
    }

    function stack:set_letter_size(size)
        profile_letter:get_children_by_id("profile_letter")[1]:set_size(size)
    end

    if ui_daemon:get_profile_image() then
        local success = profile:set_image(ui_daemon:get_profile_image())
        if success then
            stack:raise_widget(profile)
        end
    end

    ui_daemon:connect_signal("profile_image", function(self, profile_image)
        local success = profile:set_image(profile_image)
        if success then
            stack:raise_widget(profile)
        end
    end)

    return stack
end

function profile.mt:__call()
    return new()
end

return setmetatable(profile, profile.mt)
