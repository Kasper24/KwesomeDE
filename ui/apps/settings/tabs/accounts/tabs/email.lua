local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local text_input_widget = require("ui.apps.settings.text_input")
local email_daemon = require("daemons.web.email")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local email = {
    mt = {}
}

local function new()
    local machine_text_input = text_input_widget(
        beautiful.icons.server,
        "Machine:",
        email_daemon:get_machine()
    )

    local login_text_input = text_input_widget(
        beautiful.icons.user,
        "Login:",
        email_daemon:get_login()
    )

    local password_text_input = text_input_widget(
        beautiful.icons.lock,
        "Password:",
        email_daemon:get_password()
    )

    machine_text_input:connect_signal("unfocus", function(self)
        email_daemon:update_net_rc(machine_text_input:get_text(), login_text_input:get_text(), password_text_input:get_text())
    end)

    login_text_input:connect_signal("unfocus", function(self)
        email_daemon:update_net_rc(machine_text_input:get_text(), login_text_input:get_text(), password_text_input:get_text())
    end)

    password_text_input:connect_signal("unfocus", function(self)
        email_daemon:update_net_rc(machine_text_input:get_text(), login_text_input:get_text(), password_text_input:get_text())
    end)

    return wibox.widget {
        layout = wibox.layout.overflow.vertical,
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(10),
        step = 50,
        spacing = dpi(15),
        machine_text_input,
        login_text_input,
        password_text_input
    }
end

function email.mt:__call()
    return new()
end

return setmetatable(email, email.mt)