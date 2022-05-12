local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local beautiful = require("beautiful")
local theme_daemon = require("daemons.system.theme")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local colorscheme = { mt = {} }

local function color_button(index)
    local background = wibox.widget
    {
        widget = wibox.container.background,
        forced_width = dpi(200),
        forced_height = dpi(40),
    }

    local color_text = widgets.text
    {
        halign = "center",
        size = 12,
        color = beautiful.colors.on_accent,
        text = beautiful.random_accent_color(),
    }

    local color_button = wibox.widget
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        widgets.text
        {
            halign = "center",
            size = 12,
            text = index
        },
        widgets.button.elevated.normal
        {
            paddings = dpi(0),
            on_press = function()
                theme_daemon:edit_color(index)
            end,
            child =
            {
                layout = wibox.layout.stack,
                background,
                color_text
            }
        }
    }

    theme_daemon:connect_signal("current_colorscheme", function(self, colors)
        local color = colors[index]
        if helpers.color.is_dark(color) then
            color_text:set_color(beautiful.colors.on_background)
        else
            color_text:set_color(beautiful.colors.on_accent)
        end
        color_text:set_text(color)
        background.bg = color
    end)

    return color_button
end

local function custom()
    local function colorscheme_widget(self, colorscheme)
        local function color(color)
            return wibox.widget
            {
                widget = wibox.container.background,
                forced_width = dpi(15),
                forced_height = dpi(10),
                bg = color
            }
        end

        local colors = wibox.widget
        {
            layout = wibox.layout.grid,
            forced_num_cols = 8,
        }

        for i = 1, 16 do
            colors:add(color(colorscheme.colorscheme["colors"]["color" .. i - 1]))
        end

        local widget = widgets.button.elevated.state
        {
            forced_height = dpi(150),
            on_normal_bg = beautiful.colors.surface,
            on_press = function(_self)
                self:select_entry(_self)
                theme_daemon:select_colorscheme(colorscheme.colorscheme_path)
            end,
            child =
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(15),
                {
                    widget = wibox.widget.imagebox,
                    forced_height = dpi(40),
                    horizontal_fit_policy = "fit",
                    vertical_fit_policy = "fit",
                    image = colorscheme.low_res_wallpaper_path,
                },
                colors
            }
        }

        widget:connect_signal("selected", function()
            theme_daemon:select_colorscheme(colorscheme.colorscheme_path)
        end)

        return widget
    end

    local colorschemes_widget = widgets.rofi_grid
    {
        reset_on_hide = false,
        entries = theme_daemon:get_colorschemes(),
        entries_per_row = 3,
        entries_per_column = 5,
        entries_spacing = dpi(15),
        create_entry_widget = colorscheme_widget
    }

    theme_daemon:connect_signal("colorschemes", function(_, colorschemes)
        colorschemes_widget:set_entries(colorschemes)
    end)

    local colors = wibox.widget
    {
        widget = wibox.layout.grid,
        spacing = dpi(15),
        forced_num_rows = 2,
        forced_num_cols = 8,
        expand = true,
    }

    for i = 1, 16 do
        colors:add(color_button(i))
    end

    local auto_adjust = widgets.button.text.normal
    {
        animate_size = false,
        normal_bg = beautiful.colors.surface,
        text_normal_bg = beautiful.colors.on_surface,
        size = 15,
        text = "Add Colorscheme",
        on_press = function()
            theme_daemon:add_colorscheme()
        end
    }

    local shuffle_colors = widgets.button.text.normal
    {
        animate_size = false,
        normal_bg = beautiful.colors.surface,
        text_normal_bg = beautiful.colors.on_surface,
        size = 15,
        text = "Shuffle",
        on_press = function()
            theme_daemon:shuffle_colorscheme()
        end
    }

    local reset = widgets.button.text.normal
    {
        animate_size = false,
        normal_bg = beautiful.colors.surface,
        text_normal_bg = beautiful.colors.on_surface,
        size = 15,
        text = "Reset",
        on_press = function()
            theme_daemon:reset_colorscheme()
        end
    }

    local save = widgets.button.text.normal
    {
        animate_size = false,
        normal_bg = beautiful.colors.surface,
        text_normal_bg = beautiful.colors.on_surface,
        size = 15,
        text = "Save",
        on_press = function()
            theme_daemon:save_colorscheme()
        end
    }

    local set_colorscheme = widgets.button.text.normal
    {
        animate_size = false,
        normal_bg = beautiful.colors.surface,
        text_normal_bg = beautiful.colors.on_surface,
        size = 15,
        text = "Set Colorscheme",
        on_press = function()
            theme_daemon:set_colorscheme(false, true)
        end
    }

    local set_wallpaper = widgets.button.text.normal
    {
        animate_size = false,
        normal_bg = beautiful.colors.surface,
        text_normal_bg = beautiful.colors.on_surface,
        size = 15,
        text = "Set Wallpaper",
        on_press = function()
            theme_daemon:set_colorscheme(true, false)
        end
    }

    local set_both = widgets.button.text.normal
    {
        animate_size = false,
        normal_bg = beautiful.colors.surface,
        text_normal_bg = beautiful.colors.on_surface,
        size = 15,
        text = "Set Both",
        on_press = function()
            theme_daemon:set_colorscheme(true, true)
        end
    }

    return wibox.widget
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        colorschemes_widget.grid,
        colors,
        {
            layout = wibox.layout.flex.horizontal,
            forced_width = dpi(1000),
            spacing = dpi(10),
            auto_adjust,
            shuffle_colors,
            reset,
            save
        },
        {
            layout = wibox.layout.flex.horizontal,
            forced_width = dpi(1000),
            spacing = dpi(10),
            set_colorscheme,
            set_wallpaper,
            set_both
        }
    }
end

local function presets(type)
    local function colorscheme_widget(self, colorscheme)
        local function color(color)
            return wibox.widget
            {
                widget = wibox.container.background,
                forced_width = dpi(10),
                forced_height = dpi(10),
                bg = color
            }
        end

        local grid = wibox.widget
        {
            layout = wibox.layout.grid,
            forced_num_cols = 8,
        }

        for i = 1, 16 do
            grid:add(color(colorscheme.colorscheme["colors"]["color" .. i - 1]))
        end

        local widget = widgets.button.elevated.state
        {
            on_normal_bg = beautiful.colors.surface,
            on_press = function(_self)
                self:select_entry(_self)
                theme_daemon:select_pywal_colorscheme(colorscheme.name)
            end,
            child =
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(15),
                grid,
                widgets.text
                {
                    size = 12,
                    text = colorscheme.name
                }
            }
        }

        widget:connect_signal("selected", function()
            theme_daemon:select_pywal_colorscheme(colorscheme.name)
        end)

        return widget
    end

    self.custom_tab = custom()
    self.presets_tab = presets()

    local colorschemes_widget = widgets.rofi_grid
    {
        reset_on_hide = false,
        entries = theme_daemon:get_pywal_colorschemes(type),
        entries_per_row = 5,
        entries_per_column = 6,
        create_entry_widget = colorscheme_widget
    }

    theme_daemon:connect_signal(string.format("pywal_%s_colorschemes", type), function(_, colorschemes)
        colorschemes_widget:set_entries(colorschemes)
    end)

    local set_colorscheme = widgets.button.text.normal
    {
        animate_size = false,
        normal_bg = beautiful.colors.surface,
        text_normal_bg = beautiful.colors.on_surface,
        size = 15,
        text = "Set Colorscheme",
        on_press = function()
            theme_daemon:set_pywal_colorscheme()
        end
    }

    return wibox.widget
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        {
            widget = wibox.container.background,
            forced_height = dpi(630),
            colorschemes_widget.grid,
        },
        {
            layout = wibox.layout.flex.horizontal,
            forced_width = dpi(1000),
            set_colorscheme,
        }
    }
end

local function new()
    local self = {}

    self.custom_tab = custom()
    self.presets_tab = presets()

    self.content = wibox.widget
    {
        layout = wibox.layout.stack,
        top_only = true,
        self.custom_tab,
        self.presets_tab,
    }

    local buttons_accent_color = beautiful.random_accent_color()

    self.custom_button = widgets.button.text.state
    {
        size = 15,
        on_normal_bg = buttons_accent_color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.background,
        text = "Custom",
        animate_size = false,
        on_release = function()
            self.custom_button:turn_on()
            self.presets_button:turn_off()
            self.content:raise_widget(self.custom_tab)
        end
    }

    self.presets_button = widgets.button.text.state
    {
        size = 15,
        on_normal_bg = buttons_accent_color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.background,
        text = "Light",
        animate_size = false,
        on_release = function()
            self.custom_button:turn_off()
            self.presets_button:turn_off()
            self.content:raise_widget(self.presets_button)
        end
    }

    return wibox.widget
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        {
            layout = wibox.layout.flex.horizontal,
            spacing = dpi(15),
            self.custom_button,
            self.presets_button,
        },
        self.content
    }
end

function colorscheme.mt:__call()
    return new()
end

return setmetatable(colorscheme, colorscheme.mt)