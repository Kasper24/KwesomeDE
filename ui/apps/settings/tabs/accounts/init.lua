-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local email_tab = require("ui.apps.settings.tabs.accounts.tabs.email")
local github_tab = require("ui.apps.settings.tabs.accounts.tabs.github")
local gitlab_tab = require("ui.apps.settings.tabs.accounts.tabs.gitlab")
local openweather_tab = require("ui.apps.settings.tabs.accounts.tabs.openweather")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local theme = {
    mt = {}
}

local function tab_button(navigator, id, icon, title)
    return wibox.widget {
        widget = widgets.button.elevated.state,
        halign = "left",
        on_normal_bg = beautiful.icons.computer.color,
        on_release = function()
            navigator:emit_signal("tab::select", id)
        end,
        {
            layout = wibox.layout.fixed.horizontal,
            spacing = dpi(15),
            {
                widget = widgets.text,
                size = 13,
                halign = "left",
                text_normal_bg = beautiful.colors.on_background,
                text_on_normal_bg = beautiful.colors.on_accent,
                icon = icon,
            },
            {
                widget = widgets.text,
                size = 13,
                halign = "left",
                text_normal_bg = beautiful.colors.on_background,
                text_on_normal_bg = beautiful.colors.on_accent,
                text = title,
            }
        }
    }
end

local function new()
    local navigator = wibox.widget {
        widget = widgets.vertical_navigator
    }

    navigator:set_tabs {
        {
            {
                id = "email",
                button = tab_button(navigator, "email", beautiful.icons.envelope, "Email"),
                tab = email_tab()
            },
            {
                id = "github",
                button = tab_button(navigator, "github", beautiful.icons.github, "Github"),
                tab = github_tab()
            },
            {
                id = "gitlab",
                button = tab_button(navigator, "gitlab", beautiful.icons.gitlab, "Gitlab"),
                tab = gitlab_tab()
            },
            {
                id = "open_weather",
                button = tab_button(navigator, "open_weather", beautiful.icons.clouds, "OpenWeather"),
                tab = openweather_tab()
            },
        }
    }

    return navigator
end

function theme.mt:__call()
    return new()
end

return setmetatable(theme, theme.mt)