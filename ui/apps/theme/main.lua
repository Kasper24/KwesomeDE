-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gtable = require("gears.table")
local gcolor = require("gears.color")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local theme_daemon = require("daemons.system.theme")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable
local table = table
local math = math
local random = math.random
local sin = math.sin
local pi = math.pi

local main = {
    mt = {}
}

local function color_button(index)
    local background = wibox.widget {
        widget = wibox.container.background,
        forced_width = dpi(200),
        forced_height = dpi(40),
        shape = helpers.ui.rrect(),
    }

    local color_text = wibox.widget {
        widget = widgets.text,
        halign = "center",
        size = 12,
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

    theme_daemon:connect_signal("colorscheme::generation::success", function(self, colors, wallpaper)
        if wallpaper == theme_daemon:get_selected_colorscheme() then
            local color = colors[index]
            if helpers.color.is_dark(color) then
                color_text:set_color(beautiful.colors.white)
            else
                color_text:set_color(beautiful.colors.black)
            end
            color_text:set_text(color)
            background.bg = color
        end
    end)

    return color_button
end

local function wallpapers_grid(theme_app, wallpapers_key, entry_template)
    local slider = wibox.widget {
        widget = wibox.widget.slider,
        forced_width = dpi(5),
        minimum = 1,
        value = 1,
        bar_shape = helpers.ui.rrect(),
        bar_height= 3,
        bar_color = beautiful.colors.transparent,
        bar_active_color = beautiful.colors.transparent,
        handle_width = dpi(50),
        handle_color = beautiful.bg_normal,
        handle_shape = helpers.ui.rrect(),
        handle_color = beautiful.colors.on_background
    }

    local layout = wibox.widget {
        layout = widgets.rofi_grid,
        sort_fn = function(a, b)
            return a.title:lower() < b.title:lower()
        end,
        search_fn = function(text, entry)
            if helpers.fzy.has_match(text, entry.title) then
                return true
            end
            return false
        end,
        search_sort_fn = function(text, a, b)
            return helpers.fzy.score(text, a.title) < helpers.fzy.score(text, b.title)
        end,
        widget_template = wibox.widget {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            {
                widget = widgets.text_input,
                id = "text_input_role",
                forced_width = dpi(800),
                forced_height = dpi(55),
                unfocus_on_subject_mouse_leave = theme_app:get_client(),
                widget_template = wibox.widget {
                    widget = widgets.background,
                    shape = helpers.ui.rrect(),
                    bg = beautiful.colors.surface,
                    {
                        widget = wibox.container.margin,
                        margins = dpi(15),
                        {
                            layout = wibox.layout.fixed.horizontal,
                            spacing = dpi(15),
                            {
                                widget = widgets.text,
                                icon = beautiful.icons.magnifying_glass,
                                color = beautiful.icons.spraycan.color
                            },
                            {
                                layout = wibox.layout.stack,
                                {
                                    widget = wibox.widget.textbox,
                                    id = "placeholder_role",
                                    text = "Search: "
                                },
                                {
                                    widget = wibox.widget.textbox,
                                    id = "text_role"
                                }
                            }
                        }
                    }
                }
            },
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(10),
                {
                    layout = wibox.layout.grid,
                    forced_width = dpi(750),
                    id = "grid_role",
                    orientation = "horizontal",
                    homogeneous = true,
                    spacing = dpi(5),
                    forced_num_cols = 5,
                    forced_num_rows = 4,
                },
                {
                    layout = wibox.container.rotate,
                    direction = 'west',
                    slider
                }
            }
        },
        entry_template = entry_template
    }

    theme_daemon:connect_signal("wallpapers", function()
        layout:set_entries(theme_daemon["get_" .. wallpapers_key](theme_daemon))
        slider:set_maximum(#theme_daemon["get_" .. wallpapers_key](theme_daemon))
        slider:set_value(1)
    end)

    layout:connect_signal("scroll", function(self, dir, new_index, widget, entry)
        slider:set_value(new_index)
    end)

    layout:connect_signal("page::forward", function(self, dir, new_index, widget, entry)
        slider:set_value(new_index)
    end)

    layout:connect_signal("page::backward", function(self, dir, new_index, widget, entry)
        slider:set_value(new_index)
    end)

    layout:connect_signal("search", function(self, dir, increamant, widget, entry)
        slider:set_value(1)
        slider:set_maximum(#layout:get_matched_entries())
    end)

    layout:connect_signal("select", function(self, new_index)
        slider:set_value(new_index)
    end)

    slider:connect_signal("property::value", function(self, value, instant)
        if instant ~= true then
            layout:set_selected_entry(value)
        end
    end)

    layout:set_entries(theme_daemon["get_" .. wallpapers_key](theme_daemon))
    slider:set_maximum(#layout:get_matched_entries())

    return layout
end

local function image_tab(theme_app)
    local layout = wallpapers_grid(
        theme_app,
        "wallpapers",
        function(entry)
            local widget = nil
            local button = wibox.widget {
                widget = widgets.button.elevated.state,
                id = "button",
                forced_width = dpi(146),
                forced_height = dpi(100),
                on_normal_bg = beautiful.icons.spraycan.color,
                halign = "center",
                on_release = function()
                    widget:select()
                end,
                {
                    widget = wibox.widget.imagebox,
                    clip_shape = helpers.ui.rrect(),
                    horizontal_fit_policy = "fit",
                    vertical_fit_policy = "fit",
                    forced_width = dpi(146),
                    forced_height = dpi(100),
                    image = helpers.ui.adjust_image_res(entry.path, 100, 70)
                }
            }

            local title = wibox.widget {
                widget = widgets.text,
                forced_width = dpi(130),
                forced_height = dpi(20),
                halign = "center",
                size = 12,
                text = entry.title
            }

            widget = wibox.widget {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(5),
                button,
                title
            }

            widget:connect_signal("select", function()
                button:turn_on()
                theme_daemon:set_selected_colorscheme(entry.path, "image")
            end)

            widget:connect_signal("unselect", function()
                button:turn_off()
            end)

            return widget
        end
    )

    return layout
end

local function mountain_tab(theme_app)
    local layout = wallpapers_grid(
        theme_app,
        "wallpapers_and_we_wallpapers",
        function(entry, rofi_grid)
            local colors = theme_daemon:get_colorschemes()[entry.path]

            local widget = nil
            local button = wibox.widget {
                widget = widgets.button.elevated.state,
                id = "button",
                forced_width = dpi(146),
                forced_height = dpi(100),
                on_normal_bg = beautiful.icons.spraycan.color,
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
                        forced_height = dpi(100),
                        clip_shape = helpers.ui.rrect(),
                        horizontal_fit_policy = "fit",
                        vertical_fit_policy = "fit",
                        image = helpers.ui.adjust_image_res(beautiful.mountain_background, 100, 70)
                    },
                }
            }

            local title = wibox.widget {
                widget = widgets.text,
                forced_width = dpi(130),
                forced_height = dpi(20),
                halign = "center",
                size = 12,
                text = entry.title
            }

            widget = wibox.widget {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(5),
                button,
                title
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
                    button:get_children_by_id("background").bg = {
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
        end
    )

    return layout
end

local function digital_sun_tab(theme_app)
    local layout = wallpapers_grid(
        theme_app,
        "wallpapers_and_we_wallpapers",
        function(entry, rofi_grid)
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
                widget = widgets.button.elevated.state,
                id = "button",
                forced_width = dpi(146),
                forced_height = dpi(100),
                on_normal_bg = beautiful.icons.spraycan.color,
                halign = "center",
                on_release = function()
                    widget:select()
                end,
                {
                    widget = wibox.container.background,
                    shape = helpers.ui.rrect(),
                    sun
                }
            }

            local title = wibox.widget {
                widget = widgets.text,
                forced_width = dpi(130),
                forced_height = dpi(20),
                halign = "center",
                size = 12,
                text = entry.title
            }

            widget = wibox.widget {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(5),
                button,
                title
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
        end
    )

    return layout
end

local function binary_tab(theme_app)
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

    local layout = wallpapers_grid(
        theme_app,
        "wallpapers_and_we_wallpapers",
        function(entry, rofi_grid)
            local colors = theme_daemon:get_colorschemes()[entry.path] or theme_daemon:get_active_colorscheme_colors()

            local widget = nil
            local button = wibox.widget {
                widget = widgets.button.elevated.state,
                id = "button",
                forced_width = dpi(146),
                forced_height = dpi(100),
                on_normal_bg = beautiful.icons.spraycan.color,
                halign = "center",
                on_release = function()
                    widget:select()
                end,
                {
                    widget = wibox.container.background,
                    id = "background",
                    forced_width = dpi(146),
                    forced_height = dpi(100),
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

            local title = wibox.widget {
                widget = widgets.text,
                forced_width = dpi(130),
                forced_height = dpi(20),
                halign = "center",
                size = 12,
                text = entry.title
            }

            widget = wibox.widget {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(5),
                button,
                title
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
        end
    )

    return layout
end

local function we_tab(theme_app)
    local layout = wallpapers_grid(
        theme_app,
        "we_wallpapers",
        function(entry, rofi_grid)
            local menu = widgets.menu {
                widgets.menu.button {
                    text = "Preview",
                    on_release = function()
                        theme_daemon:preview_we_wallpaper(entry.path, theme_app:get_client():geometry())
                    end
                }
            }

            local widget = nil
            local button = wibox.widget {
                widget = widgets.button.elevated.state,
                id = "button",
                forced_width = dpi(146),
                forced_height = dpi(100),
                on_normal_bg = beautiful.icons.spraycan.color,
                halign = "center",
                on_release = function()
                    widget:select()
                end,
                on_secondary_release = function()
                    menu:toggle()
                end,
                {
                    widget = wibox.widget.imagebox,
                    forced_width = dpi(146),
                    forced_height = dpi(100),
                    clip_shape = helpers.ui.rrect(),
                    horizontal_fit_policy = "fit",
                    vertical_fit_policy = "fit",
                    image = helpers.ui.adjust_image_res(entry.path, 100, 70)
                }
            }

            local title = wibox.widget {
                widget = widgets.text,
                forced_width = dpi(130),
                forced_height = dpi(20),
                halign = "center",
                size = 12,
                text = entry.title
            }

            widget = wibox.widget {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(5),
                button,
                title
            }

            widget:connect_signal("select", function()
                button:turn_on()
                theme_daemon:set_selected_colorscheme(entry.path, "we")
            end)

            widget:connect_signal("unselect", function()
                button:turn_off()
            end)

            return widget
        end
    )

    return layout
end

local function tabs(theme_app)
    local _image_button = {}
    local _mountain_button = {}
    local _digital_sun_button = {}
    local _binary_button = {}
    local _we_button = {}

    local _stack = {}
    local _image_tab = image_tab(theme_app)
    local _mountain_tab = mountain_tab(theme_app)
    local _digital_sun_tab = digital_sun_tab(theme_app)
    local _binary_tab = binary_tab(theme_app)
    local _we_tab = we_tab(theme_app)

    _image_button = wibox.widget {
        widget = widgets.button.text.state,
        on_by_default = true,
        size = 13,
        on_normal_bg = beautiful.icons.spraycan.color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        text = "Image",
        on_release = function()
            theme_daemon:set_selected_tab("image")
            _image_button:turn_on()
            _mountain_button:turn_off()
            _digital_sun_button:turn_off()
            _binary_button:turn_off()
            _we_button:turn_off()
            _stack:raise_widget(_image_tab)
        end
    }

    _mountain_button = wibox.widget {
        widget = widgets.button.text.state,
        size = 13,
        on_normal_bg = beautiful.icons.spraycan.color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        text = "Mountain",
        on_release = function()
            theme_daemon:set_selected_tab("mountain")
            _image_button:turn_off()
            _mountain_button:turn_on()
            _digital_sun_button:turn_off()
            _binary_button:turn_off()
            _we_button:turn_off()
            _stack:raise_widget(_mountain_tab)
        end
    }

    _digital_sun_button = wibox.widget {
        widget = widgets.button.text.state,
        size = 13,
        on_normal_bg = beautiful.icons.spraycan.color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        text = "Digital Sun",
        on_release = function()
            theme_daemon:set_selected_tab("digital_sun")
            _image_button:turn_off()
            _mountain_button:turn_off()
            _digital_sun_button:turn_on()
            _binary_button:turn_off()
            _we_button:turn_off()
            _stack:raise_widget(_digital_sun_tab)
        end
    }

    _binary_button = wibox.widget {
        widget = widgets.button.text.state,
        size = 13,
        on_normal_bg = beautiful.icons.spraycan.color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        text = "Binary",
        on_release = function()
            theme_daemon:set_selected_tab("binary")
            _image_button:turn_off()
            _mountain_button:turn_off()
            _digital_sun_button:turn_off()
            _binary_button:turn_on()
            _we_button:turn_off()
            _stack:raise_widget(_binary_tab)
        end
    }

    _we_button = wibox.widget {
        widget = widgets.button.text.state,
        size = 13,
        on_normal_bg = beautiful.icons.spraycan.color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        text = "WP Engine",
        on_release = function()
            theme_daemon:set_selected_tab("we")
            _image_button:turn_off()
            _mountain_button:turn_off()
            _digital_sun_button:turn_off()
            _binary_button:turn_off()
            _we_button:turn_on()
            _stack:raise_widget(_we_tab)
        end
    }

    _stack = wibox.widget {
        layout = wibox.layout.stack,
        forced_height = dpi(580),
        top_only = true,
        _image_tab,
        _mountain_tab,
        _digital_sun_tab,
        _binary_tab,
        _we_tab
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
            _binary_button,
            _we_button
        },
        _stack,
    }
end

local function bottom()
    local colors = wibox.widget {
        widget = wibox.layout.grid,
        spacing = dpi(15),
        forced_num_rows = 2,
        forced_num_cols = 8,
        expand = true
    }

    local spinning_circle = widgets.spinning_circle {
        forced_width = dpi(250),
        forced_height = dpi(250),
        thickness = dpi(30),
        run_by_default = false
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
            theme_daemon:set_wallpaper(theme_daemon:get_selected_colorscheme())
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
            theme_daemon:set_wallpaper(theme_daemon:get_selected_colorscheme())
            theme_daemon:set_colorscheme(theme_daemon:get_selected_colorscheme())
        end
    }

    local widget = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        colors,
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
        spinning_circle,
        widget
    }

    theme_daemon:connect_signal("colorscheme::generation::start", function()
        spinning_circle:start()
        stack:raise_widget(spinning_circle)
    end)

    theme_daemon:connect_signal("colorscheme::generation::error", function()
        spinning_circle:stop()
        stack:raise_widget(widget)
    end)

    theme_daemon:connect_signal("colorscheme::generation::success", function(self, colors, wallpaper)
        if wallpaper == theme_daemon:get_selected_colorscheme() then
            if helpers.color.is_dark(colors[1]) then
                light_dark:set_text("Light")
            else
                light_dark:set_text("Dark")
            end
            spinning_circle:stop()
            stack:raise_widget(widget)
        end
    end)

    for i = 1, 16 do
        colors:add(color_button(i))
    end

    return stack
end

local function new(theme_app, layout)
    local title = wibox.widget {
        widget = widgets.text,
        bold = true,
        size = 15,
        text = "Theme Manager"
    }

    local settings_button = wibox.widget {
        widget = widgets.button.text.normal,
        forced_width = dpi(40),
        forced_height = dpi(40),
        text_normal_bg = beautiful.icons.spraycan.color,
        icon = beautiful.icons.gear,
        size = 15,
        on_release = function()
            layout:raise(2)
        end
    }

    local close_button = wibox.widget {
        widget = widgets.button.text.normal,
        forced_width = dpi(40),
        forced_height = dpi(40),
        text_normal_bg = beautiful.icons.spraycan.color,
        icon = beautiful.icons.xmark,
        on_release = function()
            theme_app:hide()
        end
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

    local content = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        tabs(theme_app),
        bottom()
    }

    local stack = wibox.widget {
        layout = wibox.layout.stack,
        top_only = true,
        empty_wallpapers,
        content
    }

    local widget = wibox.widget {
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
        stack
    }

    theme_daemon:connect_signal("tab::select", function(self, tab)
        if tab == "image" then
            if gtable.count_keys(theme_daemon:get_wallpapers()) == 0 then
                stack:raise_widget(empty_wallpapers)
            else
                stack:raise_widget(content)
            end
        elseif tab == "mountain" or tab == "digital_sun" or tab == "binary" then
            if gtable.count_keys(theme_daemon:get_wallpapers_and_we_wallpapers()) == 0 then
                stack:raise_widget(empty_wallpapers)
            else
                stack:raise_widget(content)
            end
        elseif tab == "we" then
            if gtable.count_keys(theme_daemon:get_we_wallpapers()) == 0 then
                stack:raise_widget(empty_wallpapers)
            else
                stack:raise_widget(content)
            end
        end
    end)

    theme_daemon:set_selected_tab("image")

    return widget
end

function main.mt:__call(self, layout)
    return new(self, layout)
end

return setmetatable(main, main.mt)
