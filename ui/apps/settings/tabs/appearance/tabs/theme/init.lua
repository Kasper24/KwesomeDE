-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local image_tab = require("ui.apps.settings.tabs.appearance.tabs.theme.tabs.image")
local mountain_tab = require("ui.apps.settings.tabs.appearance.tabs.theme.tabs.mountain")
local digital_sun_tab = require("ui.apps.settings.tabs.appearance.tabs.theme.tabs.digital_sun")
local binary_tab = require("ui.apps.settings.tabs.appearance.tabs.theme.tabs.binary")
local wallpaper_engine_tab = require("ui.apps.settings.tabs.appearance.tabs.theme.tabs.wallpaper_engine")
local theme_daemon = require("daemons.system.theme")
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
            theme_daemon:set_selected_tab(id)
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
                id = "image",
                button = tab_button(navigator, "image", beautiful.icons.computer, "Image"),
                tab = image_tab()
            },
            {
                id = "mountain",
                button = tab_button(navigator, "mountain", beautiful.icons.computer, "Mountain"),
                tab = mountain_tab()
            },
            {
                id = "digital_sun",
                button = tab_button(navigator, "digital_sun", beautiful.icons.computer, "Digital Sun"),
                tab = digital_sun_tab()
            },
            {
                id = "binary",
                button = tab_button(navigator, "binary", beautiful.icons.computer, "Binary"),
                tab = binary_tab()
            },
            {
                id = "wallpaper_engine",
                button = tab_button(navigator, "wallpaper_engine", beautiful.icons.computer, "Wallpaper Engine"),
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