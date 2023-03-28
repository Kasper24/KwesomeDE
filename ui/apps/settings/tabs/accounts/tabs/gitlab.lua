local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local text_input_widget = require("ui.apps.settings.text_input")
local gitlab_daemon = require("daemons.web.gitlab")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local gitlab = {
    mt = {}
}

local function new()
    local host_text_input = text_input_widget(
        beautiful.icons.server,
        "Host:",
        gitlab_daemon:get_host()
    )

    local access_token_text_input = text_input_widget(
        beautiful.icons.lock,
        "Access Token:",
        gitlab_daemon:get_access_token()
    )

    host_text_input:connect_signal("unfocus", function(self, context, text)
        gitlab_daemon:set_host(text)
        gitlab_daemon:refresh()
    end)

    access_token_text_input:connect_signal("unfocus", function(self, context, text)
        gitlab_daemon:set_access_token(text)
        gitlab_daemon:refresh()
    end)

    return wibox.widget {
        layout = wibox.layout.overflow.vertical,
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(10),
        step = 50,
        spacing = dpi(15),
        host_text_input,
        access_token_text_input
    }
end

function gitlab.mt:__call()
    return new()
end

return setmetatable(gitlab, gitlab.mt)