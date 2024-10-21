local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local text_input = require("ui.apps.settings.widgets.text_input")
local email_daemon = require("daemons.web.email")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local email = {
    mt = {}
}

local function new()
    local feed_address_text_input = text_input {
        icon = beautiful.icons.server,
        placeholder = "Feed Address:",
        initial = email_daemon:get_feed_address()
    }

    local address_text_input = text_input {
        icon = beautiful.icons.user,
        placeholder = "Email Address:",
        initial = email_daemon:get_address()
    }

    local app_password_text_input = text_input {
        icon = beautiful.icons.lock,
        placeholder = "App Password:",
        initial = email_daemon:get_app_password()
    }

    feed_address_text_input:connect_signal("unfocus", function(self)
        email_daemon:set_feed_address(self:get_text())
    end)

    address_text_input:connect_signal("unfocus", function(self)
        email_daemon:set_address(self:get_text())
    end)

    app_password_text_input:connect_signal("unfocus", function(self)
        email_daemon:set_app_password(self:get_text())
    end)

    return wibox.widget {
        layout = wibox.layout.overflow.vertical,
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(10),
        step = 50,
        spacing = dpi(15),
        feed_address_text_input,
        address_text_input,
        app_password_text_input
    }
end

function email.mt:__call()
    return new()
end

return setmetatable(email, email.mt)
