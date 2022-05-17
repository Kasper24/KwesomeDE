local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local beautiful = require("beautiful")
local theme_daemon = require("daemons.system.theme")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local main = { mt = {} }

local function wallpaper_widget(wallpaper)
    local button = widgets.button.text.state
    {
        animate_size = false,
        halign = "left",
        text_normal_bg = beautiful.colors.on_background,
        size = 12,
        text = wallpaper.path,
        on_press = function()
            theme_daemon:select_wallpaper(wallpaper)
        end
    }

    theme_daemon:connect_signal("wallpaper::selected", function(self, new_wallpaper)
        if wallpaper.path == new_wallpaper.path then
            button:turn_on()
        else
            button:turn_off()
        end
    end)

    return button
end

local function color_button(index)
    local background = wibox.widget
    {
        widget = wibox.container.background,
        forced_width = dpi(200),
        forced_height = dpi(40),
        bg = "#FFFFFF"
    }

    local color_text = widgets.text
    {
        halign = "center",
        size = 12,
        color = beautiful.colors.background,
        text = "#FFFFFF",
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

    theme_daemon:connect_signal("color::" .. index .. "::updated", function(self, color)
        local color = color
        if helpers.color.is_dark(color) then
            color_text:set_color(beautiful.colors.on_background)
        else
            color_text:set_color(beautiful.colors.on_accent)
        end
        color_text:set_text(color)
        background.bg = color
    end)

    theme_daemon:connect_signal("colorscheme::generated", function(self, colors)
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

local function image_tab()
    local wallpaper_image = wibox.widget
    {
        widget = wibox.widget.imagebox,
        forced_height = dpi(300),
        horizontal_fit_policy = "fit",
        vertical_fit_policy = "fit",
    }

    local colors = wibox.widget
    {
        widget = wibox.layout.grid,
        spacing = dpi(15),
        forced_num_rows = 2,
        forced_num_cols = 8,
        expand = true,
    }

    local empty_wallpapers = wibox.widget
    {
        widget = wibox.container.margin,
        margins = { top = dpi(250) },
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            widgets.text
            {
                halign = "center",
                size = 50,
                color = beautiful.random_accent_color(),
                font = beautiful.spraycan_icon.font,
                text = beautiful.spraycan_icon.icon
            },
            widgets.text
            {
                halign = "center",
                size = 15,
                text = "It's empty out here ):"
            },
        }
    }

    local spinning_circle = wibox.widget
    {
        widget = wibox.container.place,
        halign = "center",
        valign = "center",
        widgets.spinning_circle
        {
            forced_width = dpi(250),
            forced_height = dpi(250),
            thickness = dpi(30)
        }
    }

    spinning_circle.children[1]:abort()

    local wallpapers_layout = wibox.widget
    {
        layout = widgets.overflow.vertical,
        forced_height = dpi(250),
        spacing = dpi(3),
        scrollbar_widget =
        {
            widget = wibox.widget.separator,
            shape = helpers.ui.rrect(beautiful.border_radius),
            color = beautiful.colors.on_background
        },
        scrollbar_width = dpi(3),
        scroll_speed = 10,
    }

    local reset_colorscheme = widgets.button.text.normal
    {
        animate_size = false,
        normal_bg = beautiful.colors.surface,
        text_normal_bg = beautiful.colors.on_surface,
        size = 15,
        text = "Reset Colorscheme",
        on_press = function()
            theme_daemon:reset_colorscheme()
        end
    }

    local save_colorscheme = widgets.button.text.normal
    {
        animate_size = false,
        normal_bg = beautiful.colors.surface,
        text_normal_bg = beautiful.colors.on_surface,
        size = 15,
        text = "Save Colorscheme",
        on_press = function()
            theme_daemon:save_colorscheme()
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
            theme_daemon:set_wallpaper("image")
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
            theme_daemon:set_colorscheme()
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
            theme_daemon:set_wallpaper("image")
            theme_daemon:set_colorscheme()
        end
    }

    local widget = wibox.widget
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        wallpaper_image,
        colors,
        wallpapers_layout,
        {
            layout = wibox.layout.flex.horizontal,
            spacing = dpi(10),
            reset_colorscheme,
            save_colorscheme,
        },
        {
            layout = wibox.layout.flex.horizontal,
            spacing = dpi(10),
            set_wallpaper,
            set_colorscheme,
            set_both
        }
    }

    local stack = wibox.widget
    {
        layout = wibox.layout.stack,
        top_only = true,
        empty_wallpapers,
        spinning_circle,
        widget
    }


    theme_daemon:connect_signal("colorscheme::generating", function(self)
        spinning_circle.children[1]:start()
        stack:raise_widget(spinning_circle)
    end)

    theme_daemon:connect_signal("wallpaper::selected", function(self, wallpaper)
        wallpaper_image.image = wallpaper.path
        spinning_circle.children[1]:abort()
        stack:raise_widget(widget)
    end)

    theme_daemon:connect_signal("wallpapers", function(self, wallpapers)
        wallpapers_layout:reset()

        if wallpapers ~= nil then
            for _, wallpaper in ipairs(wallpapers) do
                wallpapers_layout:add(wallpaper_widget(wallpaper))
            end

            theme_daemon:select_wallpaper(wallpapers[1])
            wallpapers_layout:set_position(0)
            stack:raise_widget(widget)
        end
    end)

    theme_daemon:connect_signal("wallpapers::empty", function()
        stack:raise_widget(empty_wallpapers)
        wallpapers_layout:reset()
    end)

    for i = 1, 16 do
        colors:add(color_button(i))
    end

    return stack
end

local function new(self, layout)
    local accent_color = beautiful.random_accent_color()

    local _image_button = {}
    local _tiled_button = {}
    local _color_button = {}
    local _digital_sun_button = {}
    local _binary_button = {}

    local _stack = {}
    local _image_tab = image_tab()
    local _tiled_tab = {}
    local _color_tab = {}
    local _digital_sun_tab = {}
    local _binary_tab = {}

    local title = widgets.text
    {
        forced_width = dpi(50),
        forced_height = dpi(50),
        bold = true,
        size = 15,
        text = "Theme Manager"
    }

    local settings_button = widgets.button.text.normal
    {
        forced_width = dpi(50),
        forced_height = dpi(50),
        size = 15,
        text_normal_bg = accent_color,
        font = beautiful.gear_icon.font,
        text = beautiful.gear_icon.icon,
        on_release = function()
            layout:raise(2)
        end
    }

    local close_button = widgets.button.text.normal
    {
        forced_width = dpi(50),
        forced_height = dpi(50),
        text_normal_bg = accent_color,
        font = beautiful.xmark_icon.font,
        text = beautiful.xmark_icon.icon,
        on_release = function()
            self:hide()
        end
    }

    _image_button = widgets.button.text.state
    {
        on_by_default = true,
        size = 15,
        on_normal_bg = accent_color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.background,
        text = "Image",
        animate_size = false,
        on_release = function()
            _image_button:turn_on()
            _tiled_button:turn_off()
            _color_button:turn_off()
            _digital_sun_button:turn_off()
            _binary_button:turn_off()
            _stack:raise_widget(_image_tab)
        end
    }

    _tiled_button = widgets.button.text.state
    {
        size = 15,
        on_normal_bg = accent_color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.background,
        text = "Tiled",
        animate_size = false,
        on_release = function()
            _image_button:turn_off()
            _tiled_button:turn_on()
            _color_button:turn_off()
            _digital_sun_button:turn_off()
            _binary_button:turn_off()
            _stack:raise_widget(_image_tab)
        end
    }

    _color_button = widgets.button.text.state
    {
        size = 15,
        on_normal_bg = accent_color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.background,
        text = "Color",
        animate_size = false,
        on_release = function()
            _image_button:turn_off()
            _tiled_button:turn_off()
            _color_button:turn_on()
            _digital_sun_button:turn_off()
            _binary_button:turn_off()
            _stack:raise_widget(_image_tab)
        end
    }

    _digital_sun_button = widgets.button.text.state
    {
        size = 15,
        on_normal_bg = accent_color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.background,
        text = "Digital Sun",
        animate_size = false,
        on_release = function()
            _image_button:turn_off()
            _tiled_button:turn_off()
            _color_button:turn_off()
            _digital_sun_button:turn_on()
            _binary_button:turn_off()
            _stack:raise_widget(_image_tab)
        end
    }

    _binary_button = widgets.button.text.state
    {
        size = 15,
        on_normal_bg = accent_color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.background,
        text = "Binary",
        animate_size = false,
        on_release = function()
            _image_button:turn_off()
            _tiled_button:turn_off()
            _color_button:turn_off()
            _digital_sun_button:turn_off()
            _binary_button:turn_on()
            _stack:raise_widget(_image_tab)
        end
    }

    _stack = wibox.widget
    {
        layout = wibox.layout.stack,
        top_only = true,
        _image_tab,
        _image_tab,
        _image_tab,
        _image_tab,
        _image_tab
    }

    return wibox.widget
    {
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
        {
            layout = wibox.layout.flex.horizontal,
            spacing = dpi(15),
            _image_button,
            _tiled_button,
            _color_button,
            _digital_sun_button,
            _binary_button
        },
        _stack
    }
end

function main.mt:__call(self, layout)
    return new(self, layout)
end

return setmetatable(main, main.mt)