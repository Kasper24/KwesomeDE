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
local random = math.random

local image = {
    mt = {}
}

local function new()
    local function binary()
        local ret = {}
        for _ = 1, 30 do
            for _ = 1, 100 do
                table.insert(ret, random() > 0.5 and 1 or 0)
            end
            table.insert(ret, "\n")
        end

        return table.concat(ret)
    end

    local wallpapers = wallpapers_grid("wallpapers_and_we_wallpapers", function(entry, rofi_grid)
        local colors = theme_daemon:get_colorschemes()[entry.path] or theme_daemon:get_active_colorscheme_colors()

        local widget = nil
        local button = wibox.widget {
            widget = widgets.button.elevated.state,
            id = "button",
            forced_width = dpi(146),
            forced_height = dpi(105),
            on_normal_bg = beautiful.icons.spraycan.color,
            halign = "center",
            on_release = function()
                widget:select()
            end,
            {
                widget = wibox.container.background,
                id = "background",
                forced_width = dpi(146),
                forced_height = dpi(105),
                shape = helpers.ui.rrect(),
                bg = colors[1],
                fg = beautiful.colors.random_accent_color(colors),
                {
                    widget = wibox.layout.stack,
                    {
                        widget = wibox.container.background,
                        id = "system_failure",
                        shape = helpers.ui.rrect(),
                        fg = beautiful.colors.random_accent_color(colors),
                        {
                            widget = wibox.widget.textbox,
                            halign = "center",
                            valign = "center",
                            markup = "<tt><b>[SYSTEM FAILURE]</b></tt>"
                        }
                    },
                    {
                        widget = wibox.widget.textbox,
                        halign = "center",
                        valign = "center",
                        wrap = "word",
                        text = binary()
                    }
                }
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
            theme_daemon:set_selected_colorscheme(entry.path, "binary")
        end)

        widget:connect_signal("unselect", function()
            button:turn_off()
        end)

        theme_daemon:connect_signal("colorscheme::generation::success", function(self, colors, wallpaper, update)
            if wallpaper == entry.path and update == true then
                button:get_children_by_id("background")[1].bg = colors[1]
                button:get_children_by_id("background")[1].fg = beautiful.colors.random_accent_color(colors)
                button:get_children_by_id("system_failure")[1].fg = beautiful.colors.random_accent_color(colors)
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