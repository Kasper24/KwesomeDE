local gcolor = require("gears.color")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local wallpaper_tab = require("ui.apps.settings.tabs.wallpaper.tabs")
local theme_daemon = require("daemons.system.theme")
local library = require("library")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable
local sin = math.sin
local pi = math.pi

local digital_sun = {
    mt = {}
}

local function new()
    return wallpaper_tab("all", function(entry, scrollable_grid)
        local colors = theme_daemon:get_colorschemes()[entry.path] or theme_daemon:get_active_colorscheme_colors()
        local sun = wibox.widget {
            widget = wibox.widget.base.make_widget,
            background_color_1 = colors[1],
            background_color_2 = colors[9],
            sun_accent_color_1 = beautiful.colors.random_accent_color(colors),
            sun_accent_color_2 = beautiful.colors.random_accent_color(colors),
            grid_accent_color = beautiful.colors.random_accent_color(colors),
            fit = function(_, __, width, height) return width, height end,
            draw = function(self, __, cr, width, height)
                cr:set_source(gcolor {
                    type = 'linear',
                    from = {0, 0},
                    to = {0, height},
                    stops = {
                        {0, self.background_color_1},
                        {0.75, self.background_color_2},
                        {1, self.background_color_1}
                    }
                })
                cr:paint()
                -- Clip the first 33% of the screen
                cr:rectangle(0, 0, width, height / 3)

                -- Clip-out some increasingly large sections of add the sun "bars"
                for i = 0, 6 do
                    cr:rectangle(0, height * .28 + i * (height * .055 + i / 2), width, height * .055)
                end
                cr:clip()

                -- Draw the sun
                cr:set_source(gcolor {
                    type = 'linear',
                    from = {0, 0},
                    to = {0, height},
                    stops = {
                        {0, self.sun_accent_color_1},
                        {1, self.sun_accent_color_2}
                    }
                })
                cr:arc(width / 2, height / 2, height * .35, 0, pi * 2)
                cr:fill()

                -- Draw the grid
                local lines = width / 8
                -- cr:reset_clip()
                cr:set_line_width(0.5)
                cr:set_source(gcolor(self.grid_accent_color))

                for i = 1, lines do
                    cr:move_to((-width) + i * sin(i * (pi / (lines * 2))) * 30, height)
                    cr:line_to(width / 4 + i * ((width / 2) / lines), height * 0.75 + 2)
                    cr:stroke()
                end

                for i = 1, 5 do
                    cr:move_to(0, height * 0.75 + i * 10 + i * 2)
                    cr:line_to(width, height * 0.75 + i * 10 + i * 2)
                    cr:stroke()
                end
            end
        }

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
                shape = library.ui.rrect(),
                sun
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
            theme_daemon:set_selected_colorscheme(entry.path, "digital_sun")
        end)

        widget:connect_signal("unselect", function()
            button:turn_off()
        end)

        theme_daemon:connect_signal("colorscheme::generation::success", function(self, colors, wallpaper, update)
            if wallpaper == entry.path and update == true then
                sun.background_color_1 = colors[1]
                sun.background_color_2 = colors[9]
                sun.sun_accent_color_1 = beautiful.colors.random_accent_color(colors)
                sun.sun_accent_color_2 = beautiful.colors.random_accent_color(colors)
                sun.grid_accent_color = beautiful.colors.random_accent_color(colors)
                sun:emit_signal("widget::redraw_needed")
            end
        end)

        return widget
    end)
end

function digital_sun.mt:__call()
    return new()
end

return setmetatable(digital_sun, digital_sun.mt)
