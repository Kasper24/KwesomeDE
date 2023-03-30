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

local function new()
    local gnome_keyring = wibox.widget {
        widget = widgets.text,
        size = 15,
        text = "Secrets are now stored in a secured way. Please install gnome-keyring and re-set your Gitlab API key and Openweather access token"
    }

    return wibox.widget {
        layout = wibox.layout.overflow.vertical,
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(10),
        step = 50,
        spacing = dpi(15),
        gnome_keyring
    }
end

function breaking_changes.mt:__call()
    return new()
end

return setmetatable(breaking_changes, breaking_changes.mt)