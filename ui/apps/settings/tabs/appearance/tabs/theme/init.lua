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
        widget = widgets.navigator.vertical,
        buttons_selected_color = beautiful.icons.computer.color,
        on_select = function(id)
            theme_daemon:set_selected_tab(id)
        end,
        tabs = {
            {
                {
                    id = "image",
                    title = "Image",
                    tab = image_tab()
                },
                {
                    id = "mountain",
                    title = "Mountain",
                    tab = mountain_tab()
                },
                {
                    id = "digital_sun",
                    title = "Digital Sun",
                    tab = digital_sun_tab()
                },
                {
                    id = "binary",
                    title = "Binary",
                    tab = binary_tab()
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