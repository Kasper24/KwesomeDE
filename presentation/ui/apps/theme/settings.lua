-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local beautiful = require("beautiful")
local theme_daemon = require("daemons.system.theme")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local settings = { mt = {} }

local function template_widget(layout, template)
    local title = widgets.text
    {
        halign = "left",
        size = 12,
        text = template
    }

    local remove_button = widgets.button.text.normal
    {
        forced_width = dpi(40),
        forced_height = dpi(40),
        animate_size = false,
        font = beautiful.xmark_icon.font,
        text = beautiful.xmark_icon.icon,
        on_press = function()
            theme_daemon:remove_template(template)
        end
    }

    local widget = wibox.widget
    {
        layout = wibox.layout.align.horizontal,
        title,
        nil,
        remove_button
    }

    theme_daemon:connect_signal("templates::" .. template .. "::removed", function()
        layout:remove_widgets(widget)
    end)

    return widget
end

local function templates_widget()
    local title = widgets.text
    {
        size = 15,
        text = "Templates:"
    }

    local layout = wibox.widget
    {
        layout = widgets.overflow.vertical,
        spacing = dpi(15),
        scrollbar_widget =
        {
            widget = wibox.widget.separator,
            shape = helpers.ui.rrect(beautiful.border_radius),
            color = beautiful.colors.on_background
        },
        scrollbar_width = dpi(3),
        step = 50,
    }

    local add = widgets.button.text.normal
    {
        animate_size = false,
        text = "Add",
        on_press = function()
            theme_daemon:add_template()
        end
    }

    for _, template in ipairs(theme_daemon:get_templates()) do
        layout:add(template_widget(layout, template))
    end

    theme_daemon:connect_signal("templates::added", function(self, template)
        layout:add(template_widget(layout, template))
    end)

    return wibox.widget
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        title,
        {
            widget = wibox.container.constraint,
            strategy = "max",
            height = dpi(400),
            layout
        },
        add
    }
end

local function wallpaper_path_widget(layout, path)
    local title = widgets.text
    {
        halign = "left",
        size = 12,
        text = path
    }

    local remove_button = widgets.button.text.normal
    {
        forced_width = dpi(40),
        forced_height = dpi(40),
        animate_size = false,
        font = beautiful.xmark_icon.font,
        text = beautiful.xmark_icon.icon,
        on_press = function()
            theme_daemon:remove_wallpapers_path(path)
        end
    }

    local widget = wibox.widget
    {
        layout = wibox.layout.align.horizontal,
        title,
        nil,
        remove_button
    }

    theme_daemon:connect_signal("wallpapers_paths::" .. path .. "::removed", function()
        layout:remove_widgets(widget)
    end)

    return widget
end

local function wallpapers_paths_widget()
    local title = widgets.text
    {
        size = 15,
        text = "Wallpapers Paths:"
    }

    local layout = wibox.widget
    {
        layout = widgets.overflow.vertical,
        spacing = dpi(15),
        scrollbar_widget =
        {
            widget = wibox.widget.separator,
            shape = helpers.ui.rrect(beautiful.border_radius),
            color = beautiful.colors.on_background
        },
        scrollbar_width = dpi(3),
        step = 50,
    }

    local add = widgets.button.text.normal
    {
        animate_size = false,
        text = "Add",
        on_press = function()
            theme_daemon:add_wallpapers_path()
        end
    }

    for _, path in ipairs(theme_daemon:get_wallpapers_paths()) do
        layout:add(wallpaper_path_widget(layout, path))
    end

    theme_daemon:connect_signal("wallpapers_paths::added", function(self, path)
        layout:add(wallpaper_path_widget(layout, path))
    end)

    return wibox.widget
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        title,
        {
            widget = wibox.container.constraint,
            strategy = "max",
            height = dpi(400),
            layout
        },
        add
    }
end

local function command_after_generation_widget()
    local title = widgets.text
    {
        size = 15,
        text = "Run after generation:"
    }

    local prompt = widgets.prompt
    {
        reset_on_stop = false,
        prompt = "",
        text = theme_daemon:get_command_after_generation(),
        text_color = beautiful.colors.on_background,
        icon_font = beautiful.launcher_icon.font,
        icon = nil,
        changed_callback = function(text)
            theme_daemon:set_command_after_generation(text)
        end
    }

    return wibox.widget
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        title,
        prompt.widget
    }
end

local function new(layout)
    local back_button = widgets.button.text.normal
    {
        forced_width = dpi(50),
        forced_height = dpi(50),
        font = beautiful.left_icon.font,
        text = beautiful.left_icon.icon,
        on_release = function()
            layout:raise(2)
        end
    }

    local settings_text = widgets.text
    {
        bold = true,
        size = 15,
        text = "Settings",
    }

    return wibox.widget
    {
        widget = wibox.container.margin,
        margins = dpi(23),
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(15),
                back_button,
                settings_text
            },
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(15),
                command_after_generation_widget(),
                wallpapers_paths_widget(),
                templates_widget()
            }
        }
    }
end

function settings.mt:__call(layout)
    return new(layout)
end

return setmetatable(settings, settings.mt)