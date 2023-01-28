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
    local button = wibox.widget
    {
        widget = widgets.button.text.state,
        forced_height = dpi(40),
        animate_size = false,
        halign = "left",
        text_bg = beautiful.colors.on_background,
        size = 12,
        text = theme_daemon:get_short_wallpaper_name(wallpaper),
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

    local color_text = wibox.widget
    {
        widget = widgets.text,
        halign = "center",
        size = 12,
        color = beautiful.colors.background,
        text = "#FFFFFF",
    }

    local color_button = wibox.widget
    {
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

    local light_dark = wibox.widget
    {
        widget = widgets.button.text.normal,
        animate_size = false,
        bg = beautiful.colors.surface,
        text_bg = beautiful.colors.on_surface,
        size = 15,
        text = "Light",
        on_press = function()
            theme_daemon:toggle_dark_light()
        end
    }

    local reset_colorscheme = wibox.widget
    {
        widget = widgets.button.text.normal,
        animate_size = false,
        bg = beautiful.colors.surface,
        text_bg = beautiful.colors.on_surface,
        size = 15,
        text = "Reset Colorscheme",
        on_press = function()
            theme_daemon:reset_colorscheme()
        end
    }

    local save_colorscheme = wibox.widget
    {
        widget = widgets.button.text.normal,
        animate_size = false,
        bg = beautiful.colors.surface,
        text_bg = beautiful.colors.on_surface,
        size = 15,
        text = "Save Colorscheme",
        on_press = function()
            theme_daemon:save_colorscheme()
        end
    }

    local set_wallpaper = wibox.widget
    {
        widget = widgets.button.text.normal,
        animate_size = false,
        bg = beautiful.colors.surface,
        text_bg = beautiful.colors.on_surface,
        size = 15,
        text = "Set Wallpaper",
        on_press = function()
            theme_daemon:set_wallpaper("image")
        end
    }

    local set_colorscheme = wibox.widget
    {
        widget = widgets.button.text.normal,
        animate_size = false,
        bg = beautiful.colors.surface,
        text_bg = beautiful.colors.on_surface,
        size = 15,
        text = "Set Colorscheme",
        on_press = function()
            theme_daemon:set_colorscheme()
        end
    }

    local set_both = wibox.widget
    {
        widget = widgets.button.text.normal,
        animate_size = false,
        bg = beautiful.colors.surface,
        text_bg = beautiful.colors.on_surface,
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
        },
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

    theme_daemon:connect_signal("colorscheme::failed_to_generate", function(self, wallpaper)
        spinning_circle.children[1]:abort()
        stack:raise_widget(widget)
    end)

    theme_daemon:connect_signal("wallpaper::selected", function(self, wallpaper)
        wallpaper_image.image = wallpaper
        spinning_circle.children[1]:abort()
        stack:raise_widget(widget)
    end)

    theme_daemon:connect_signal("wallpapers", function(self, wallpapers)
        spinning_circle.children[1]:start()
        stack:raise_widget(spinning_circle)

        wallpapers_layout:reset()

        for _, wallpaper in ipairs(wallpapers) do
            wallpapers_layout:add(wallpaper_widget(wallpaper))
        end

        stack:raise_widget(widget)
        spinning_circle.children[1]:abort()
    end)

    theme_daemon:connect_signal("wallpapers::empty", function()
        stack:raise_widget(empty_wallpapers)
        wallpapers_layout:reset()
    end)

    for i = 1, 16 do
        colors:add(color_button(i))
    end

    self:connect_signal("visible", function(self, visible)
        if visible == true then
            theme_daemon:select_wallpaper(theme_daemon:get_wallpaper())
            wallpapers_layout:set_scroll_factor(0)
            wallpapers_layout:scroll(theme_daemon:get_wallpaper_index())
        end
    end)

    return stack
end

local function digital_sun_tab()
    local gcolor = require("gears.color")

    local set = wibox.widget
    {
        widget = widgets.button.text.normal,
        animate_size = false,
        bg = beautiful.colors.surface,
        text_bg = beautiful.colors.on_surface,
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

local function wip_tab()
    return wibox.widget
    {
        widget = wibox.container.place,
        forced_width = dpi(500),
        forced_height = dpi(500),
        halign = "center",
        valign = "center",
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(30),
            {
                widget = widgets.text,
                halign = "center",
                valign = "center",
                icon = beautiful.icons.hammer,
                size = 120,
            },
            {
                widget = widgets.text,
                halign = "center",
                valign = "center",
                size = 50,
                text = "WIP",
            }
        }
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
    local _tiled_tab = wip_tab()
    local _color_tab = wip_tab()
    local _digital_sun_tab = digital_sun_tab()
    local _binary_tab = wip_tab()

    local title = wibox.widget
    {
        widget = widgets.text,
        bold = true,
        size = 15,
        text = "Theme Manager"
    }

    local settings_button = wibox.widget
    {
        widget = widgets.button.text.normal,
        forced_width = dpi(50),
        forced_height = dpi(50),
        text_bg = accent_color,
        icon = beautiful.icons.gear,
        size = 15,
        on_release = function()
            layout:raise(2)
        end
    }

    local close_button = wibox.widget
    {
        widget = widgets.button.text.normal,
        forced_width = dpi(50),
        forced_height = dpi(50),
        text_bg = accent_color,
        icon = beautiful.icons.xmark,
        on_release = function()
            self:hide()
        end
    }

    _image_button = wibox.widget
    {
        widget = widgets.button.text.state,
        on_by_default = true,
        size = 15,
        on_bg = accent_color,
        text_bg = beautiful.colors.on_background,
        text_on_bg = beautiful.colors.on_accent,
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

    _tiled_button = wibox.widget
    {
        widget = widgets.button.text.state,
        size = 15,
        on_bg = accent_color,
        text_bg = beautiful.colors.on_background,
        text_on_bg = beautiful.colors.on_accent,
        text = "Tiled",
        animate_size = false,
        on_release = function()
            _image_button:turn_off()
            _tiled_button:turn_on()
            _color_button:turn_off()
            _digital_sun_button:turn_off()
            _binary_button:turn_off()
            _stack:raise_widget(_tiled_tab)
        end
    }

    _color_button = wibox.widget
    {
        widget = widgets.button.text.state,
        size = 15,
        on_bg = accent_color,
        text_bg = beautiful.colors.on_background,
        text_on_bg = beautiful.colors.on_accent,
        text = "Color",
        animate_size = false,
        on_release = function()
            _image_button:turn_off()
            _tiled_button:turn_off()
            _color_button:turn_on()
            _digital_sun_button:turn_off()
            _binary_button:turn_off()
            _stack:raise_widget(_color_tab)
        end
    }

    _digital_sun_button = wibox.widget
    {
        widget = widgets.button.text.state,
        size = 15,
        on_bg = accent_color,
        text_bg = beautiful.colors.on_background,
        text_on_bg = beautiful.colors.on_accent,
        text = "Digital Sun",
        animate_size = false,
        on_release = function()
            _image_button:turn_off()
            _tiled_button:turn_off()
            _color_button:turn_off()
            _digital_sun_button:turn_on()
            _binary_button:turn_off()
            _stack:raise_widget(_digital_sun_tab)
        end
    }

    _binary_button = wibox.widget
    {
        widget = widgets.button.text.state,
        size = 15,
        on_bg = accent_color,
        text_bg = beautiful.colors.on_background,
        text_on_bg = beautiful.colors.on_accent,
        text = "Binary",
        animate_size = false,
        on_release = function()
            _image_button:turn_off()
            _tiled_button:turn_off()
            _color_button:turn_off()
            _digital_sun_button:turn_off()
            _binary_button:turn_on()
            _stack:raise_widget(_binary_tab)
        end
    }

    _stack = wibox.widget
    {
        layout = wibox.layout.stack,
        top_only = true,
        _image_tab,
        _tiled_tab,
        _color_tab,
        _digital_sun_tab,
        _binary_tab
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