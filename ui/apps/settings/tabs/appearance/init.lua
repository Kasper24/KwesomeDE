-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
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
        widget = widgets.navigator.vertical,
        buttons_selected_color = beautiful.colors.accent,
        tabs = {
            {
                {
                    id = "ui",
                    title = "UI",
                    tab = ui_tab()
                },
                {
                    id = "compositor",
                    title = "Compositor",
                    tab = compositor_tab()
                },
                {
                    id = "wallpaper_engine",
                    title = "Wallpaper Engine",
                    tab = wallpaper_engine_tab()
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
