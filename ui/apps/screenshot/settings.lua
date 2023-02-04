-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gshape = require("gears.shape")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local screenshot_daemon = require("daemons.system.screenshot")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local settings = {
    mt = {}
}

local accent_color = beautiful.colors.random_accent_color()

local function show_cursor()
    local checkbox = wibox.widget {
        widget = widgets.checkbox,
        state = screenshot_daemon:get_show_cursor(),
        color = accent_color,
        on_turn_on = function()
            screenshot_daemon:set_show_cursor(true)
        end,
        on_turn_off = function()
            screenshot_daemon:set_show_cursor(false)
        end
    }

    local text = wibox.widget {
        widget = widgets.text,
        valign = "center",
        size = 15,
        text = "Show Cursor: "
    }

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_height = dpi(35),
        spacing = dpi(5),
        text,
        checkbox
    }
end

local function delay()
    local title = wibox.widget {
        widget = widgets.text,
        size = 15,
        text = "Delay:"
    }

    local value_text = wibox.widget {
        widget = widgets.text,
        size = 15,
        text = screenshot_daemon:get_delay()
    }

    local slider = wibox.widget {
        widget = widgets.slider,
        forced_width = dpi(150),
        value = screenshot_daemon:get_delay(),
        maximum = 100,
        bar_height = 5,
        bar_shape = helpers.ui.rrect(beautiful.border_radius),
        bar_color = beautiful.colors.surface,
        bar_active_color = beautiful.colors.random_accent_color(),
        handle_width = dpi(15),
        handle_color = beautiful.colors.on_background,
        handle_shape = gshape.circle
    }

    slider:connect_signal("property::value", function(self, value, instant)
        if instant == false then
            screenshot_daemon:set_delay(value)
            value_text:set_text(value)
        end
    end)

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_height = dpi(35),
        spacing = dpi(15),
        title,
        slider,
        value_text
    }
end

local function folder()
    local title = wibox.widget {
        widget = widgets.text,
        size = 15,
        text = "Folder:"
    }

    local folder_text = wibox.widget {
        widget = widgets.text,
        forced_width = dpi(220),
        size = 12,
        text = screenshot_daemon:get_folder()
    }

    local set_folder_button = wibox.widget {
        widget = widgets.button.text.normal,
        size = 15,
        text = "...",
        on_press = function()
            screenshot_daemon:set_folder()
        end
    }

    screenshot_daemon:connect_signal("folder::updated", function(self, folder)
        folder_text.text = folder
    end)

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_height = dpi(35),
        spacing = dpi(15),
        title,
        folder_text,
        set_folder_button
    }
end

local function new(layout)
    local back_button = wibox.widget {
        widget = widgets.button.text.normal,
        forced_width = dpi(50),
        forced_height = dpi(50),
        icon = beautiful.icons.left,
        on_release = function()
            layout:raise(2)
        end
    }

    local settings_text = wibox.widget {
        widget = widgets.text,
        bold = true,
        size = 15,
        text = "Settings"
    }

    return wibox.widget {
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
