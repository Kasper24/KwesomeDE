local gshape = require("gears.shape")
local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local beautiful = require("beautiful")
local screenshot_daemon = require("daemons.system.screenshot")
local dpi = beautiful.xresources.apply_dpi
local settings = { mt = {} }

local accent_color = beautiful.random_accent_color()

local function show_cursor()
    local checkbox = wibox.widget
    {
        widget = wibox.widget.checkbox,
        checked = screenshot_daemon:get_show_cursor(),
        forced_width = dpi(25),
        forced_height = dpi(25),
        paddings = dpi(3),
        shape = gshape.circle,
        color = accent_color
    }

    local text = widgets.text
    {
        valign = "top",
        size = 15,
        text = "Show Cursor"
    }

    local button = widgets.button.elevated.normal
    {
        margins = dpi(0),
        -- paddings = dpi(0),
        halign = "left",
        on_release = function()
            checkbox.checked = not checkbox.checked
            screenshot_daemon:set_show_cursor(checkbox.checked)
        end,
        child =
        {
            layout = wibox.layout.fixed.horizontal,
            spacing = dpi(15),
            checkbox,
            text
        }
    }

    return button
end

local function delay()
    local title = widgets.text
    {
        size = 15,
        text = "Delay:"
    }

    local value_text = widgets.text
    {
        size = 15,
        text = screenshot_daemon:get_delay(),
    }

    local plus_button = widgets.button.text.normal
    {
        forced_width = dpi(50),
        forced_height = dpi(50),
        text_normal_bg = accent_color,
        font = beautiful.circle_plus_icon.font,
        text = beautiful.circle_plus_icon.icon,
        on_release = function()
            value_text:set_text(screenshot_daemon:increase_delay())
        end
    }

    local minus_button = widgets.button.text.normal
    {
        forced_width = dpi(50),
        forced_height = dpi(50),
        text_normal_bg = accent_color,
        font = beautiful.circle_minus_icon.font,
        text = beautiful.circle_minus_icon.icon,
        on_release = function()
            value_text:set_text(screenshot_daemon:decrease_delay())
        end
    }

    return wibox.widget
    {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15),
        title,
        {
            layout = wibox.layout.fixed.horizontal,
            spacing = dpi(15),
            minus_button,
            value_text,
            plus_button,
        }
    }
end

local function folder()
    local title = widgets.text
    {
        size = 15,
        text = "Folder:"
    }

    local folder_text  = widgets.text
    {
        width = dpi(350),
        size = 12,
        text = screenshot_daemon:get_folder(),
    }

    local set_folder_button  = widgets.button.text.normal
    {
        text_normal_bg = accent_color,
        size = 15,
        text = "...",
        on_press = function()
            screenshot_daemon:set_folder()
        end,
    }

    screenshot_daemon:connect_signal("folder::updated", function(self, folder)
        folder_text.text = folder
    end)

    return wibox.widget
    {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15),
        title,
        folder_text,
        set_folder_button,
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
                show_cursor(),
                delay(),
                folder()
            }
        }
    }
end

function settings.mt:__call(layout)
    return new(layout)
end

return setmetatable(settings, settings.mt)
