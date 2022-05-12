local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local beautiful = require("beautiful")
local theme_daemon = require("daemons.system.theme")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local wallpaper = { mt = {} }

local function wallpaper_widget(self, wallpaper)
    return widgets.button.elevated.state
    {
        on_normal_bg = beautiful.colors.surface,
        on_press = function(_self)
            self:select_entry(_self)
            theme_daemon:select_wallpaper(wallpaper)
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
                image = wallpaper,
            },
            widgets.text
            {
                halign = "center",
                valign = "center",
                size = 12,
                text = "wallpaper.name"
            }
        }
    }
end

local function image()
    local wallpapers_widget = widgets.rofi_grid
    {
        entries = theme_daemon:get_wallpapers(),
        entries_per_row = 5,
        entries_per_column = 5,
        entries_spacing = dpi(10),
        create_entry_widget = wallpaper_widget
    }

    theme_daemon:connect_signal("wallpapers_updated", function(_, wallpapers)
        wallpapers_widget:set_entries(wallpapers)
    end)

    local set_wallpaper = widgets.button.text.normal
    {
        animate_size = false,
        normal_bg = beautiful.colors.surface,
        text_normal_bg = beautiful.colors.on_surface,
        size = 15,
        text = "Set Wallpaper",
        on_press = function()
            theme_daemon:set_wallpaper(true, false)
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
            theme_daemon:set_wallpaper(false, true)
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
            theme_daemon:set_wallpaper(true, true)
        end
    }

    return wibox.widget
    {
        start = function() wallpapers_widget:start() end,
        stop = function() wallpapers_widget:stop() end,
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        wallpapers_widget.grid,
        {
            layout = wibox.layout.flex.horizontal,
            forced_width = dpi(1000),
            spacing = dpi(10),
            set_wallpaper,
            set_colorscheme,
            set_both
        }
    }
end

local function new()
    local self = {}

    self.image_tab = image()

    self.content = wibox.widget
    {
        layout = wibox.layout.stack,
        top_only = true,
        self.image_tab,
    }

    local buttons_accent_color = beautiful.random_accent_color()

    self.image_button = widgets.button.text.state
    {
        size = 15,
        on_normal_bg = buttons_accent_color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.background,
        text = "Image",
        animate_size = false,
        on_release = function()
            self.image_button:turn_on()
            self.tiled_button:turn_off()
            self.color_button:turn_off()
            self.digital_sun_button:turn_off()
            self.binary_button:turn_off()
            self.content:raise_widget(self.image_tab)
        end
    }

    self.tiled_button = widgets.button.text.state
    {
        size = 15,
        on_normal_bg = buttons_accent_color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.background,
        text = "Tiled",
        animate_size = false,
        on_release = function()
            self.image_button:turn_off()
            self.tiled_button:turn_on()
            self.color_button:turn_off()
            self.digital_sun_button:turn_off()
            self.binary_button:turn_off()
            self.content:raise_widget(self.image_tab)
        end
    }

    self.color_button = widgets.button.text.state
    {
        size = 15,
        on_normal_bg = buttons_accent_color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.background,
        text = "Color",
        animate_size = false,
        on_release = function()
            self.image_button:turn_off()
            self.tiled_button:turn_off()
            self.color_button:turn_on()
            self.digital_sun_button:turn_off()
            self.binary_button:turn_off()
            self.content:raise_widget(self.image_tab)
        end
    }

    self.digital_sun_button = widgets.button.text.state
    {
        size = 15,
        on_normal_bg = buttons_accent_color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.background,
        text = "Digital Sun",
        animate_size = false,
        on_release = function()
            self.image_button:turn_off()
            self.tiled_button:turn_off()
            self.color_button:turn_off()
            self.digital_sun_button:turn_on()
            self.binary_button:turn_off()
            self.content:raise_widget(self.image_tab)
        end
    }

    self.binary_button = widgets.button.text.state
    {
        size = 15,
        on_normal_bg = buttons_accent_color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.background,
        text = "Binary",
        animate_size = false,
        on_release = function()
            self.image_button:turn_off()
            self.tiled_button:turn_off()
            self.color_button:turn_off()
            self.digital_sun_button:turn_off()
            self.binary_button:turn_on()
            self.content:raise_widget(self.image_tab)
        end
    }

    return wibox.widget
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        {
            layout = wibox.layout.flex.horizontal,
            spacing = dpi(15),
            self.image_button,
            self.tiled_button,
            self.color_button,
            self.digital_sun_button,
            self.binary_button
        },
        self.content
    }
end

function wallpaper.mt:__call()
    return new()
end

return setmetatable(wallpaper, wallpaper.mt)