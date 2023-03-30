-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local tab_button = require("ui.apps.settings.tab_button")
local breaking_changes_tab = require("ui.apps.settings.tabs.about.tabs.breaking_changes")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local about = {
    mt = {}
}

local function new()
    local navigator = wibox.widget {
        widget = widgets.navigator.vertical
    }

    navigator:set_tabs {
        {
            {
                id = "breaking_changes",
                button = tab_button(navigator, "breaking_changes", beautiful.icons.circle_exclamation, "Breaking Changes"),
                tab = breaking_changes_tab()
            },
        }
    }

    return navigator
end

function about.mt:__call()
    return new()
end

return setmetatable(about, about.mt)