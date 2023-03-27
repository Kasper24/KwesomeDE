-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local tab_button = require("ui.apps.settings.tab_button")
local theme_tab = require("ui.apps.settings.tabs.appearance.tabs.theme")
local ui_tab = require("ui.apps.settings.tabs.appearance.tabs.ui")
local compositor_tab = require("ui.apps.settings.tabs.appearance.tabs.compositor")
local wallpaper_engine_tab = require("ui.apps.settings.tabs.appearance.tabs.wallpaper_engine")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local theme = {
    mt = {}
}

local function new()
    local navigator = wibox.widget {
        widget = widgets.vertical_navigator
    }

    navigator:set_tabs {
        {
            {
                id = "theme",
                button = tab_button(navigator, "theme", beautiful.icons.spraycan, "Theme"),
                tab = theme_tab()
            },
            {
                id = "ui",
                button = tab_button(navigator, "ui", beautiful.icons.spraycan, "UI"),
                tab = ui_tab()
            },
            {
                id = "compositor",
                button = tab_button(navigator, "compositor", beautiful.icons.spraycan, "Compositor"),
                tab = compositor_tab()
            },
            {
                id = "wallpaper_engine",
                button = tab_button(navigator, "wallpaper_engine", beautiful.icons.spraycan, "Wallpaper Engine"),
                tab = wallpaper_engine_tab()
            },
        }
    }

    return navigator
end

function theme.mt:__call()
    return new()
end

return setmetatable(theme, theme.mt)