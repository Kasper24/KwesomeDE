local gtable = require("gears.table")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local empty_wallpapers = require("ui.apps.settings.tabs.wallpaper.empty_wallpapers")
local wallpapers_grid = require("ui.apps.settings.tabs.wallpaper.wallpapers_grid")
local actions = require("ui.apps.settings.tabs.wallpaper.actions")
local theme_daemon = require("daemons.system.theme")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local image = {
    mt = {}
}

local function new()
    local menu = widgets.menu {
        widgets.menu.button {
            text = "Preview",
            on_release = function()
                theme_daemon:preview_we_wallpaper(theme_daemon:get_selected_colorscheme(), SETTINGS_APP:get_client():geometry())
            end
        }
    }

    local wallpapers = wallpapers_grid("we_wallpapers", function(entry, rofi_grid)
        local widget = nil
        local button = wibox.widget {
            widget = widgets.button.state,
            id = "button",
            on_color = beautiful.icons.computer.color,
            halign = "center",
            on_release = function()
                widget:select()
            end,
            on_secondary_release = function()
                widget:select()
                menu:toggle()
            end,
            {
                widget = wibox.widget.imagebox,
                clip_shape = helpers.ui.rrect(),
                horizontal_fit_policy = "fit",
                vertical_fit_policy = "fit",
                image = entry.thumbnail
            }
        }

        local name = wibox.widget {
            widget = widgets.text,
            halign = "center",
            size = 12,
            text = entry.name
        }

        widget = wibox.widget {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(5),
            button,
            name
        }

        widget:connect_signal("select", function()
            button:turn_on()
            theme_daemon:set_selected_colorscheme(entry.path, "wallpaper_engine")
        end)

        widget:connect_signal("unselect", function()
            button:turn_off()
        end)

        return widget
    end)

    local empty_wallpapers_widget = empty_wallpapers()

    local content = wibox.widget {
        layout = wibox.layout.overflow.vertical,
        spacing = dpi(15),
        wallpapers,
        actions()
    }

    local stack = wibox.widget {
        layout = wibox.layout.stack,
        top_only = true,
        empty_wallpapers_widget,
        content
    }

    theme_daemon:connect_signal("wallpapers", function(self, wallpapers, wallpapers_and_we_wallpapers, we_wallpapers)
        if gtable.count_keys(we_wallpapers) == 0 then
            stack:raise_widget(empty_wallpapers_widget)
        else
            stack:raise_widget(content)
        end
    end)

    if gtable.count_keys(theme_daemon:get_we_wallpapers()) == 0 then
        stack:raise_widget(empty_wallpapers_widget)
    else
        stack:raise_widget(content)
    end

    return stack
end

function image.mt:__call()
    return new()
end

return setmetatable(image, image.mt)
