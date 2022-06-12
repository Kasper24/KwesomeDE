-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local gtimer = require("gears.timer")
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
        forced_height = dpi(40),
        animate_size = false,
        halign = "left",
        text_normal_bg = beautiful.colors.on_background,
        size = 12,
        text = wallpaper,
        on_press = function()
            theme_daemon:select_wallpaper(wallpaper)
        end
    }

    theme_daemon:connect_signal("wallpaper::selected", function(self, new_wallpaper)
        if wallpaper == new_wallpaper then
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
            color_text:set_color("#FFFFFF")
        else
            color_text:set_color("#000000")
        end
        color_text:set_text(color)
        background.bg = color
    end)

    theme_daemon:connect_signal("colorscheme::generated", function(self, colors)
        local color = colors[index]
        if helpers.color.is_dark(color) then
            color_text:set_color("#FFFFFF")
        else
            color_text:set_color("#000000")
        end
        color_text:set_text(color)
        background.bg = color
    end)

    return color_button
end

local function image_tab(self)
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
        step = 43,
    }

    local light_dark = widgets.button.text.normal
    {
        animate_size = false,
        normal_bg = beautiful.colors.surface,
        text_normal_bg = beautiful.colors.on_surface,
        size = 15,
        text = "Light",
        on_press = function()
            theme_daemon:toggle_dark_light()
        end
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
            light_dark,
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

    theme_daemon:connect_signal("colorscheme::generated", function(self, colors)
        if helpers.color.is_dark(colors[1]) then
            light_dark:set_text("Light")
        else
            light_dark:set_text("Dark")
        end
    end)

    theme_daemon:connect_signal("colorscheme::generating", function(self)
        spinning_circle.children[1]:start()
        stack:raise_widget(spinning_circle)
    end)

    theme_daemon:connect_signal("wallpaper::selected", function(self, wallpaper)
        wallpaper_image.image = wallpaper
        spinning_circle.children[1]:abort()
        stack:raise_widget(widget)
    end)

    local selected_wallpaper_index = 0
    theme_daemon:connect_signal("wallpapers", function(self, wallpapers)
        wallpapers_layout:reset()

        if wallpapers ~= nil then
            for index, wallpaper in ipairs(wallpapers) do
                wallpapers_layout:add(wallpaper_widget(wallpaper))

                if wallpaper == theme_daemon:get_wallpaper() then
                    selected_wallpaper_index = index
                end
            end

            theme_daemon:select_wallpaper(theme_daemon:get_wallpaper())
            stack:raise_widget(widget)
        end
    end)

    theme_daemon:connect_signal("wallpapers::empty", function()
        stack:raise_widget(empty_wallpapers)
        wallpapers_layout:reset()
    end)

    self:connect_signal("visible", function(self, visiblity)
        if visiblity == true then
            gtimer { timeout = 0.1, single_shot = true, autostart = true, call_now = false, callback = function()
                wallpapers_layout:scroll(selected_wallpaper_index)
            end}
        end
    end)

    for i = 1, 16 do
        colors:add(color_button(i))
    end

    return stack
end

local function digital_sun_tab()
    local gcolor = require("gears.color")

    local set = widgets.button.text.normal
    {
        animate_size = false,
        normal_bg = beautiful.colors.surface,
        text_normal_bg = beautiful.colors.on_surface,
        size = 15,
        text = "Set",
        on_press = function()
            theme_daemon:set_wallpaper("digital_sun")
        end
    }

    return wibox.widget
    {
        layout = wibox.layout.fixed.vertical,
        wibox.widget {
            forced_width = dpi(20),
            forced_height = dpi(250),
            fit = function(_, width, height)
                return width, height
            end,
            draw = function(_, _, cr, width, height)
                cr:set_source(gcolor {
                    type  = 'linear',
                    from  = { 0, 0      },
                    to    = { 0, height },
                    stops = {
                        { 0   , beautiful.colors.background },
                        { 0.75, beautiful.colors.surface },
                        { 1   , beautiful.colors.background }
                    }
                })
                cr:paint()
                -- Clip the first 33% of the screen
                cr:rectangle(0,0, width, height/3)

                -- Clip-out some increasingly large sections of add the sun "bars"
                for i=0, 6 do
                    cr:rectangle(0, height*.28 + i*(height*.055 + i/2), width, height*.055)
                end
                cr:clip()

             -- Draw the sun
                cr:set_source(gcolor {
                    type  = 'linear' ,
                    from  = { 0, 0      },
                    to    = { 0, height },
                    stops = {
                        { 0, beautiful.random_accent_color() },
                        { 1, beautiful.random_accent_color() }
                    }
                })
                cr:arc(width/2, height/2, height*.35, 0, math.pi*2)
                cr:fill()

                -- Draw the grid
                local lines = width/8
                cr:reset_clip()
                cr:set_line_width(0.5)
                cr:set_source(gcolor(beautiful.random_accent_color()))

                for i=1, lines do
                    cr:move_to((-width) + i* math.sin(i * (math.pi/(lines*2)))*30, height)
                    cr:line_to(width/4 + i*((width/2)/lines), height*0.75 + 2)
                    cr:stroke()
                end

                for i=1, 5 do
                    cr:move_to(0, height*0.75 + i*10 + i*2)
                    cr:line_to(width, height*0.75 + i*10 + i*2)
                    cr:stroke()
                end
            end
        },
        set,
    }
end

local function new(self, layout)
    local accent_color = beautiful.random_accent_color()

    local _image_button = {}
    local _tiled_button = {}
    local _color_button = {}
    local _digital_sun_button = {}
    local _binary_button = {}

    local _stack = {}
    local _image_tab = image_tab(self)
    local _tiled_tab = {}
    local _color_tab = {}
    local _digital_sun_tab = digital_sun_tab()
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
        text_on_normal_bg = beautiful.colors.on_accent,
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
        text_on_normal_bg = beautiful.colors.on_accent,
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
        text_on_normal_bg = beautiful.colors.on_accent,
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
        text_on_normal_bg = beautiful.colors.on_accent,
        text = "Digital Sun",
        animate_size = false,
        on_release = function()
            _image_button:turn_off()
            _tiled_button:turn_off()
            _color_button:turn_off()
            _digital_sun_button:turn_on()
            _binary_button:turn_off()
            _stack:raise_widget(_digital_sun_tab)
            print("sun")
        end
    }

    _binary_button = widgets.button.text.state
    {
        size = 15,
        on_normal_bg = accent_color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
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
        _digital_sun_tab,
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