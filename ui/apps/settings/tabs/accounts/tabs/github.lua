local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local text_input = require("ui.apps.settings.text_input")
local github_daemon = require("daemons.web.github")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local github = {
    mt = {}
}

local function new()
    local username_text_input = text_input {
        icon = beautiful.icons.user,
        placeholder = "Username:",
        initial = github_daemon:get_username()
    }

    username_text_input:connect_signal("unfocus", function(self, context, text)
        github_daemon:set_username(text)
        github_daemon:refresh()
    end)

    return wibox.widget {
        layout = wibox.layout.overflow.vertical,
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(10),
        step = 50,
        spacing = dpi(15),
        username_text_input
    }
end

function github.mt:__call()
    return new()
end

return setmetatable(github, github.mt)