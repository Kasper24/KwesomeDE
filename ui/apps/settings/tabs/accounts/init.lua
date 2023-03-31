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

local function new()
    local navigator = wibox.widget {
        widget = widgets.navigator.vertical,
        buttons_selected_color = beautiful.icons.computer.color,
        tabs = {
            {
                {
                    id = "email",
                    icon = beautiful.icons.envelope,
                    title = "Email",
                    tab = email_tab()
                },
                {
                    id = "github",
                    icon = beautiful.icons.github,
                    title = "Github",
                    tab = github_tab()
                },
                {
                    id = "gitlab",
                    icon = beautiful.icons.gitlab,
                    title = "Gitlab",
                    tab = gitlab_tab()
                },
                {
                    id = "open_weather",
                    icon = beautiful.icons.clouds,
                    title = "OpenWeather",
                    tab = openweather_tab()
                },
            }
        }
    }

    return navigator
end

function theme.mt:__call()
    return new()
end

return setmetatable(theme, theme.mt)