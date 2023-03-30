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

local function new()
    local navigator = wibox.widget {
        widget = widgets.navigator.vertical
    }

    navigator:set_tabs {
        {
            {
                id = "image",
                icon = beautiful.icons.spraycan,
                title = "Image",
                tab = image_tab(),
                on_select = function()
                    theme_daemon:set_selected_tab("image")
                end
            },
            {
                id = "mountain",
                icon = beautiful.icons.spraycan,
                title = "Mountain",
                tab = mountain_tab(),
                on_select = function()
                    theme_daemon:set_selected_tab("mountain")
                end
            },
            {
                id = "digital_sun",
                icon = beautiful.icons.spraycan,
                title = "Digital Sun",
                tab = digital_sun_tab(),
                on_select = function()
                    theme_daemon:set_selected_tab("digital_sun")
                end
            },
            {
                id = "binary",
                icon = beautiful.icons.spraycan,
                title = "Binary",
                tab = binary_tab(),
                on_select = function()
                    theme_daemon:set_selected_tab("binary")
                end
            },
            {
                id = "wallpaper_engine",
                icon = beautiful.icons.spraycan,
                title = "Wallpaper Engine",
                tab = wallpaper_engine_tab(),
                on_select = function()
                    theme_daemon:set_selected_tab("wallpaper_engine")
                end
            },
        }
    }

    return navigator
end

function theme.mt:__call()
    return new()
end

return setmetatable(theme, theme.mt)