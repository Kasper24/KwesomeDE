local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local wallpaper_tab = require("ui.apps.settings.tabs.wallpaper.tabs")
local theme_daemon = require("daemons.system.theme")
local library = require("library")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable
local random = math.random

local binary = {
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

    return wallpaper_tab("all", function(entry, scrollable_grid)
        local colors = theme_daemon:get_colorschemes()[entry.path] or theme_daemon:get_active_colorscheme_colors()

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
                widget = wibox.container.background,
                id = "background",
                shape = library.ui.rrect(),
                bg = colors[1],
                fg = beautiful.colors.random_accent_color(colors),
                {
                    widget = wibox.layout.stack,
                    {
                        widget = wibox.container.background,
                        id = "system_failure",
                        shape = library.ui.rrect(),
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
end

function binary.mt:__call()
    return new()
end

return setmetatable(binary, binary.mt)
