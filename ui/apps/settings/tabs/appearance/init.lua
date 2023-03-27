-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local theme_tab = require("ui.apps.settings.tabs.appearance.tabs.theme")
local ui_tab = require("ui.apps.settings.tabs.appearance.tabs.ui")
local compositor_tab = require("ui.apps.settings.tabs.appearance.tabs.compositor")
local wallpaper_engine_tab = require("ui.apps.settings.tabs.appearance.tabs.wallpaper_engine")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local theme = {
    mt = {}
}

local function tab_button(navigator, id, icon, title)
    return wibox.widget {
        widget = widgets.button.elevated.state,
        halign = "left",
        on_normal_bg = beautiful.icons.spraycan.color,
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