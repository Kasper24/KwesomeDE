local gtable = require("gears.table")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local empty_wallpapers = require("ui.apps.settings.tabs.appearance.tabs.theme.empty_wallpapers")
local wallpapers_grid = require("ui.apps.settings.tabs.appearance.tabs.theme.wallpapers_grid")
local actions = require("ui.apps.settings.tabs.appearance.tabs.theme.actions")
local theme_daemon = require("daemons.system.theme")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local image = {
    mt = {}
}

local function new()
    local wallpapers = wallpapers_grid("wallpapers_and_we_wallpapers", function(entry, rofi_grid)
        local colors = theme_daemon:get_colorschemes()[entry.path]

        local widget = nil
        local button = wibox.widget {
            widget = widgets.button.elevated.state,
            id = "button",
            forced_width = dpi(146),
            forced_height = dpi(105),
            on_normal_bg = beautiful.icons.computer.color,
            halign = "center",
            on_release = function()
                widget:select()
            end,
            {
                layout = wibox.layout.stack,
                {
                    widget = wibox.container.background,
                    id = "background",
                    shape = helpers.ui.rrect(),
                    bg = {
                        type = 'linear',
                        from = {0, 0},
                        to = {0, 100},
                        stops = {
                            {0, beautiful.colors.random_accent_color(colors)},
                            {0.75, beautiful.colors.random_accent_color(colors)},
                            {1, beautiful.colors.random_accent_color(colors)}
                        }
                    }
                },
                {
                    widget = wibox.widget.imagebox,
                    forced_width = dpi(146),
                    forced_height = dpi(105),
                    clip_shape = helpers.ui.rrect(),
                    horizontal_fit_policy = "fit",
                    vertical_fit_policy = "fit",
                    image = beautiful.mountain_background_thumbnail
                },
            }
        }

        local name = wibox.widget {
            widget = widgets.text,
            forced_width = dpi(130),
            forced_height = dpi(20),
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
            theme_daemon:set_selected_colorscheme(entry.path, "mountain")
        end)

        widget:connect_signal("unselect", function()
            button:turn_off()
        end)

        theme_daemon:connect_signal("colorscheme::generation::success", function(self, colors, wallpaper, update)
            if wallpaper == entry.path and update == true then
                colors = theme_daemon:get_colorschemes()[entry.path]
                button:get_children_by_id("background")[1].bg = {
                    type = 'linear',
                    from = {0, 0},
                    to = {0, 100},
                    stops = {
                        {0, beautiful.colors.random_accent_color(colors)},
                        {0.75, beautiful.colors.random_accent_color(colors)},
                        {1, beautiful.colors.random_accent_color(colors)}
                    }
                }
            end
        end)

        return widget
    end)

    local empty_wallpapers_widget = empty_wallpapers()

    local content = wibox.widget {
        layout = wibox.layout.fixed.vertical,
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
        if gtable.count_keys(wallpapers_and_we_wallpapers) == 0 then
            stack:raise_widget(empty_wallpapers_widget)
        else
            stack:raise_widget(content)
        end
    end)

    if gtable.count_keys(theme_daemon:get_wallpapers_and_we_wallpapers()) == 0 then
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