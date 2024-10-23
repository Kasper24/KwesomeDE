local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local wallpapers_tab = require("ui.apps.settings.tabs.wallpaper.tabs")
local theme_daemon = require("daemons.system.theme")
local library = require("library")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local mountain = {
    mt = {}
}

local function new()
    return wallpapers_tab("all", function(entry, scrollable_grid)
        local colors = theme_daemon:get_colorschemes()[entry.path]

        local widget = nil
        local button = wibox.widget {
            widget = widgets.button.state,
            id = "button",
            on_color = beautiful.icons.computer.color,
            halign = "center",
            on_release = function()
                widget:select()
            end,
            {
                layout = wibox.layout.stack,
                {
                    widget = wibox.container.background,
                    id = "background",
                    shape = library.ui.rrect(),
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
                    clip_shape = library.ui.rrect(),
                    horizontal_fit_policy = "fit",
                    vertical_fit_policy = "fit",
                    image = beautiful.mountain_background_thumbnail
                },
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
end

function mountain.mt:__call()
    return new()
end

return setmetatable(mountain, mountain.mt)
