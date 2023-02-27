-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gcolor = require("gears.color")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local theme_daemon = require("daemons.system.theme")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable
local ipairs = ipairs

local main = {
    mt = {}
}

local function wallpaper_widget(wallpaper)
    local button = wibox.widget {
        widget = widgets.button.text.state,
        forced_height = dpi(40),
        text_normal_bg = beautiful.colors.on_background,
        size = 12,
        text = theme_daemon:get_short_wallpaper_name(wallpaper),
        on_release = function()
            theme_daemon:set_selected_colorscheme(wallpaper)
        end
    }

    theme_daemon:dynamic_connect_signal("wallpaper::selected", function(self, new_wallpaper)
        if wallpaper == new_wallpaper then
            button:turn_on()
        else
            button:turn_off()
        end
    end)

    return button
end

local function color_button(index)
    local background = wibox.widget {
        widget = wibox.container.background,
        forced_width = dpi(200),
        forced_height = dpi(40),
        shape = helpers.ui.rrect(),
        bg = beautiful.colors.white
    }

    local color_text = wibox.widget {
        widget = widgets.text,
        halign = "center",
        size = 12,
        color = beautiful.colors.background,
        text = beautiful.colors.white
    }

    local color_button = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        {
            widget = widgets.text,
            halign = "center",
            size = 12,
            text = index
        },
        {
            widget = widgets.button.elevated.normal,
            on_release = function()
                theme_daemon:edit_color(index)
            end,
            {
                layout = wibox.layout.stack,
                background,
                color_text
            }
        }
    }

    theme_daemon:connect_signal("color::" .. index .. "::updated", function(self, color)
        local color = color
        if helpers.color.is_dark(color) then
            color_text:set_color(beautiful.colors.white)
        else
            color_text:set_color(beautiful.colors.black)
        end
        color_text:set_text(color)
        background.bg = color
    end)

    theme_daemon:connect_signal("colorscheme::generated", function(self, colors)
        local color = colors[index]
        if helpers.color.is_dark(color) then
            color_text:set_color(beautiful.colors.white)
        else
            color_text:set_color(beautiful.colors.black)
        end
        color_text:set_text(color)
        background.bg = color
    end)

    return color_button
end

local function image_tab()
    local image = wibox.widget {
        widget = wibox.widget.imagebox,
        forced_height = dpi(300),
        horizontal_fit_policy = "fit",
        vertical_fit_policy = "fit"
    }

    theme_daemon:connect_signal("wallpaper::selected", function(_, wallpaper)
        image.image = wallpaper
    end)

    return image
end

local function mountain_tab()
    local colors = theme_daemon:get_selected_colorscheme_colors()

    local widget = wibox.widget {
        layout = wibox.layout.stack,
        {
            widget = wibox.container.background,
            id = "background",
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
            resize = true,
            horizontal_fit_policy = "fit",
            vertical_fit_policy = "fit",
            image = beautiful.mountain_background
        },
    }

    theme_daemon:connect_signal("colorscheme::generated", function(self, new_colors)
        widget:get_children_by_id("background")[1].bg = {
            type = 'linear',
            from = {0, 0},
            to = {0, 100},
            stops = {
                {0, beautiful.colors.random_accent_color(new_colors)},
                {0.75, beautiful.colors.random_accent_color(new_colors)},
                {1, beautiful.colors.random_accent_color(new_colors)}
            }
        }
    end)

    return widget
end

local function digital_sun_tab()
    local sun = wibox.widget {
        colors = theme_daemon:get_selected_colorscheme_colors(),
        fit = function(_, _, width, height) return width, height end,
        draw = function(self, _, cr, width, height)
            cr:set_source(gcolor {
                type = 'linear',
                from = {0, 0},
                to = {0, height},
                stops = {
                    {0, self.colors[1]},
                    {0.75, self.colors[9]},
                    {1, self.colors[1]}
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
                    {0, beautiful.colors.random_accent_color(self.colors)},
                    {1, beautiful.colors.random_accent_color(self.colors)}
                }
            })
            cr:arc(width / 2, height / 2, height * .35, 0, math.pi * 2)
            cr:fill()

            -- Draw the grid
            local lines = width / 8
            cr:reset_clip()
            cr:set_line_width(0.5)
            cr:set_source(gcolor(beautiful.colors.random_accent_color(self.colors)))

            for i = 1, lines do
                cr:move_to((-width) + i * math.sin(i * (math.pi / (lines * 2))) * 30, height)
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

    -- I can't manage to clip the grid correctly so it fits inside
    -- the widget, so instead showing an image of it
    local image = wibox.widget {
        widget = wibox.widget.imagebox,
        image =  wibox.widget.draw_to_image_surface(sun, 1000, 370)
    }

    theme_daemon:connect_signal("colorscheme::generated", function(self, new_colors)
        sun.colors = new_colors
        sun:emit_signal("widget::redraw_needed")
        image.image = wibox.widget.draw_to_image_surface(sun, 1000, 370)
    end)

    return image
end

local function binary_tab()
    local colors = theme_daemon:get_selected_colorscheme_colors()

    local function binary()
        local ret = {}
        for _ = 1, 30 do
            for _ = 1, 100 do
                table.insert(ret, math.random() > 0.5 and 1 or 0)
            end
            table.insert(ret, "\n")
        end

        return table.concat(ret)
    end

    local widget = wibox.widget {
        widget = wibox.container.background,
        bg = colors[1],
        fg = beautiful.colors.random_accent_color(colors),
        {
            widget = wibox.layout.stack,
            {
                widget = wibox.container.background,
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

    theme_daemon:connect_signal("colorscheme::generated", function(self, new_colors)
        widget.bg = new_colors[1]
        widget.fg = beautiful.colors.random_accent_color(new_colors)
    end)

    return widget
end

local function tabs(self)
    self._private.selected_tab = "image"

    local _image_button = {}
    local _mountain_button = {}
    local _digital_sun_button = {}
    local _binary_button = {}

    local _stack = {}
    local _image_tab = image_tab()
    local _mountain_tab = mountain_tab()
    local _digital_sun_tab = digital_sun_tab()
    local _binary_tab = binary_tab()

    _image_button = wibox.widget {
        widget = widgets.button.text.state,
        on_by_default = true,
        size = 15,
        on_normal_bg = beautiful.icons.spraycan.color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        text = "Image",
        on_release = function()
            self._private.selected_tab = "image"
            _image_button:turn_on()
            _mountain_button:turn_off()
            _digital_sun_button:turn_off()
            _binary_button:turn_off()
            _stack:raise_widget(_image_tab)
        end
    }

    _mountain_button = wibox.widget {
        widget = widgets.button.text.state,
        size = 15,
        on_normal_bg = beautiful.icons.spraycan.color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        text = "Mountain",
        on_release = function()
            self._private.selected_tab = "mountain"
            _image_button:turn_off()
            _mountain_button:turn_on()
            _digital_sun_button:turn_off()
            _binary_button:turn_off()
            _stack:raise_widget(_mountain_tab)
        end
    }

    _digital_sun_button = wibox.widget {
        widget = widgets.button.text.state,
        size = 15,
        on_normal_bg = beautiful.icons.spraycan.color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        text = "Digital Sun",
        on_release = function()
            self._private.selected_tab = "digital_sun"
            _image_button:turn_off()
            _mountain_button:turn_off()
            _digital_sun_button:turn_on()
            _binary_button:turn_off()
            _stack:raise_widget(_digital_sun_tab)
        end
    }

    _binary_button = wibox.widget {
        widget = widgets.button.text.state,
        size = 15,
        on_normal_bg = beautiful.icons.spraycan.color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        text = "Binary",
        on_release = function()
            self._private.selected_tab = "binary"
            _image_button:turn_off()
            _mountain_button:turn_off()
            _digital_sun_button:turn_off()
            _binary_button:turn_on()
            _stack:raise_widget(_binary_tab)
        end
    }

    _stack = wibox.widget {
        layout = wibox.layout.stack,
        forced_height = dpi(300),
        top_only = true,
        _image_tab,
        _mountain_tab,
        _digital_sun_tab,
        _binary_tab
    }

    return wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        {
            layout = wibox.layout.flex.horizontal,
            spacing = dpi(15),
            _image_button,
            _mountain_button,
            _digital_sun_button,
            _binary_button
        },
        _stack,
    }
end

local function widget(self)
    local colors = wibox.widget {
        widget = wibox.layout.grid,
        spacing = dpi(15),
        forced_num_rows = 2,
        forced_num_cols = 8,
        expand = true
    }

    local empty_wallpapers = wibox.widget {
        widget = wibox.container.margin,
        margins = {
            top = dpi(250)
        },
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            {
                widget = widgets.text,
                halign = "center",
                icon = beautiful.icons.spraycan,
                size = 50
            },
            {
                widget = widgets.text,
                halign = "center",
                size = 15,
                text = "It's empty out here ):"
            }
        }
    }

    local spinning_circle = widgets.spinning_circle {
        forced_width = dpi(250),
        forced_height = dpi(250),
        thickness = dpi(30),
        run_by_default = false
    }

    local wallpapers_layout = wibox.widget {
        layout = widgets.overflow.vertical,
        forced_height = dpi(250),
        spacing = dpi(3),
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(3),
        step = 50
    }

    local light_dark = wibox.widget {
        widget = widgets.button.text.normal,
        normal_bg = beautiful.icons.spraycan.color,
        text_normal_bg = beautiful.colors.on_accent,
        size = 15,
        text = "Light",
        on_release = function()
            theme_daemon:toggle_dark_light()
        end
    }

    local reset_colorscheme = wibox.widget {
        widget = widgets.button.text.normal,
        normal_bg = beautiful.icons.spraycan.color,
        text_normal_bg = beautiful.colors.on_accent,
        size = 15,
        text = "Reset Colorscheme",
        on_release = function()
            theme_daemon:reset_colorscheme()
        end
    }

    local save_colorscheme = wibox.widget {
        widget = widgets.button.text.normal,
        normal_bg = beautiful.icons.spraycan.color,
        text_normal_bg = beautiful.colors.on_accent,
        size = 15,
        text = "Save Colorscheme",
        on_release = function()
            theme_daemon:save_colorscheme()
        end
    }

    local set_wallpaper = wibox.widget {
        widget = widgets.button.text.normal,
        normal_bg = beautiful.icons.spraycan.color,
        text_normal_bg = beautiful.colors.on_accent,
        size = 15,
        text = "Set Wallpaper",
        on_release = function()
            theme_daemon:set_wallpaper(theme_daemon:get_selected_colorscheme(), self._private.selected_tab)
        end
    }

    local set_colorscheme = wibox.widget {
        widget = widgets.button.text.normal,
        normal_bg = beautiful.icons.spraycan.color,
        text_normal_bg = beautiful.colors.on_accent,
        size = 15,
        text = "Set Colorscheme",
        on_release = function()
            theme_daemon:set_colorscheme(theme_daemon:get_selected_colorscheme())
        end
    }

    local set_both = wibox.widget {
        widget = widgets.button.text.normal,
        normal_bg = beautiful.icons.spraycan.color,
        text_normal_bg = beautiful.colors.on_accent,
        size = 15,
        text = "Set Both",
        on_release = function()
            theme_daemon:set_wallpaper(theme_daemon:get_selected_colorscheme(), self._private.selected_tab)
            theme_daemon:set_colorscheme(theme_daemon:get_selected_colorscheme())
        end
    }

    local widget = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        colors,
        wallpapers_layout,
        {
            layout = wibox.layout.grid,
            spacing = dpi(10),
            forced_num_rows = 3,
            forced_num_cols = 3,
            horizontal_expand = true,
            light_dark,
            reset_colorscheme,
            save_colorscheme,
            set_wallpaper,
            set_colorscheme,
            set_both
        }
    }

    local stack = wibox.widget {
        layout = wibox.layout.stack,
        top_only = true,
        empty_wallpapers,
        spinning_circle,
        widget
    }

    theme_daemon:connect_signal("colorscheme::generated", function(self, colors)
        if helpers.color.is_dark(colors[1]) then
            light_dark:set_text("Light")
        else
            light_dark:set_text("Dark")
        end
    end)

    theme_daemon:connect_signal("colorscheme::generating", function()
        spinning_circle:start()
        stack:raise_widget(spinning_circle)
    end)

    theme_daemon:connect_signal("colorscheme::failed_to_generate", function()
        spinning_circle:stop()
        stack:raise_widget(widget)
    end)

    theme_daemon:connect_signal("wallpaper::selected", function()
        spinning_circle:stop()
        stack:raise_widget(widget)
    end)

    theme_daemon:connect_signal("wallpapers", function(self, wallpapers)
        spinning_circle:start()
        stack:raise_widget(spinning_circle)

        wallpapers_layout:reset()
        theme_daemon:dynamic_disconnect_signals("wallpaper::selected")
        collectgarbage("collect")

        for _, wallpaper in ipairs(wallpapers) do
            wallpapers_layout:add(wallpaper_widget(wallpaper))
        end

        stack:raise_widget(widget)
        spinning_circle:stop()
    end)

    theme_daemon:connect_signal("wallpapers::empty", function()
        stack:raise_widget(empty_wallpapers)
        wallpapers_layout:reset()
        theme_daemon:dynamic_disconnect_signals("wallpaper::selected")
        collectgarbage("collect")
    end)

    for i = 1, 16 do
        colors:add(color_button(i))
    end

    return stack
end

local function new(self, layout)
    local title = wibox.widget {
        widget = widgets.text,
        bold = true,
        size = 15,
        text = "Theme Manager"
    }

    local settings_button = wibox.widget {
        widget = widgets.button.text.normal,
        forced_width = dpi(50),
        forced_height = dpi(50),
        text_normal_bg = beautiful.icons.spraycan.color,
        icon = beautiful.icons.gear,
        size = 15,
        on_release = function()
            layout:raise(2)
        end
    }

    local close_button = wibox.widget {
        widget = widgets.button.text.normal,
        forced_width = dpi(50),
        forced_height = dpi(50),
        text_normal_bg = beautiful.icons.spraycan.color,
        icon = beautiful.icons.xmark,
        on_release = function()
            self:hide()
        end
    }

    return wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        {
            layout = wibox.layout.align.horizontal,
            title,
            nil,
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(15),
                settings_button,
                close_button
            }
        },
        tabs(self),
        widget(self)
    }
end

function main.mt:__call(self, layout)
    return new(self, layout)
end

return setmetatable(main, main.mt)
