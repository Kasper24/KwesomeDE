-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local email_tab = require("ui.apps.settings.tabs.accounts.tabs.email")
local github_tab = require("ui.apps.settings.tabs.accounts.tabs.github")
local gitlab_tab = require("ui.apps.settings.tabs.accounts.tabs.gitlab")
local weather_tab = require("ui.apps.settings.tabs.accounts.tabs.weather")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local theme = {
    mt = {}
}

local function new()
    local navigator = wibox.widget {
        widget = widgets.navigator.vertical,
        buttons_selected_color = beautiful.colors.accent,
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
                    id = "weather",
                    icon = beautiful.icons.clouds,
                    title = "Weather",
                    tab = weather_tab()
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
