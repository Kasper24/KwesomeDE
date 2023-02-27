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

local function show_cursor()
    local checkbox = wibox.widget {
        widget = widgets.checkbox,
        state = screenshot_daemon:get_show_cursor(),
        handle_active_color = beautiful.icons.camera_retro.color,
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

    local slider = widgets.slider_prompt {
        slider_width = dpi(150),
        value = screenshot_daemon:get_delay(),
        round = true,
        maximum = 100,
        bar_active_color = beautiful.icons.camera_retro.color,
    }

    slider:connect_signal("property::value", function(self, value, instant)
        screenshot_daemon:set_delay(value)
    end)

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_height = dpi(35),
        spacing = dpi(15),
        title,
        slider
    }
end

local function folder()
    local title = wibox.widget {
        widget = widgets.text,
        size = 15,
        text = "Folder:"
    }

    local folder_prompt = wibox.widget {
        widget = widgets.prompt,
        forced_width = dpi(220),
        size = 12,
        text = screenshot_daemon:get_folder()
    }

    folder_prompt:connect_signal("text::changed", function(self, text)
        screenshot_daemon:set_folder(text)
    end)

    local set_folder_button = wibox.widget {
        widget = widgets.button.text.normal,
        size = 15,
        text_normal_bg = beautiful.colors.on_background,
        text = "...",
        on_release = function()
            screenshot_daemon:set_folder()
        end
    }

    screenshot_daemon:connect_signal("folder::updated", function(self, folder)
        folder_prompt:set_text(folder)
    end)

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_height = dpi(35),
        spacing = dpi(15),
        title,
        folder_prompt,
        set_folder_button
    }
end

local function new(layout)
    local back_button = wibox.widget {
        widget = widgets.button.text.normal,
        forced_width = dpi(50),
        forced_height = dpi(50),
        text_normal_bg = beautiful.icons.camera_retro.color,
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
