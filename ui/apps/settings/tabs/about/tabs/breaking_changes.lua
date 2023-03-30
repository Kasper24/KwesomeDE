local gshape = require("gears.shape")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local text_input = require("ui.apps.settings.text_input")
local email_daemon = require("daemons.web.email")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local breaking_changes = {
    mt = {}
}

local function bullet_point(message)
    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15),
        {
            widget = widgets.background,
            forced_width = dpi(20),
            forced_height = dpi(20),
            shape = gshape.circle,
            bg = beautiful.colors.on_background
        },
        {
            widget = widgets.text,
            size = 15,
            text = message
        }
    }
end

local function new()
    return wibox.widget {
        layout = wibox.layout.overflow.vertical,
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(10),
        step = 50,
        spacing = dpi(15),
        bullet_point("Secrets are now stored in a secured way. Please install gnome-keyring and re-set your Gitlab API key and Openweather access token")
    }
end

function breaking_changes.mt:__call()
    return new()
end

return setmetatable(breaking_changes, breaking_changes.mt)