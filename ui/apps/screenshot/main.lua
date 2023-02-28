-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local screenshot_daemon = require("daemons.system.screenshot")
local dpi = beautiful.xresources.apply_dpi

local main = {
    mt = {}
}

local function button(icon, text, on_release, on_by_default)
    local icon = wibox.widget {
        widget = widgets.text,
        halign = "center",
        color = beautiful.icons.camera_retro.color,
        text_normal_bg = beautiful.icons.camera_retro.color,
        text_on_normal_bg = beautiful.colors.transparent,
        icon = icon
    }

    local text = wibox.widget {
        widget = widgets.text,
        halign = "center",
        size = 12,
        color = beautiful.colors.on_surface,
        text_normal_bg = beautiful.colors.on_surface,
        text_on_normal_bg = beautiful.colors.transparent,
        text = text
    }

    return wibox.widget {
        widget = widgets.button.elevated.state,
        on_by_default = on_by_default,
        forced_width = dpi(120),
        forced_height = dpi(120),
        normal_bg = beautiful.colors.surface,
        on_normal_bg = beautiful.icons.camera_retro.color,
        on_release = function(self)
            on_release(self)
        end,
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            icon,
            text
        }
    }
end

local function new(self, layout)
    local selection_button = nil
    local screen_button = nil
    local window_button = nil
    local color_picker_button = nil

    selection_button = button(beautiful.icons.scissors, "Selection", function()
        screenshot_daemon:set_screenshot_method("selection")
        selection_button:turn_on()
        screen_button:turn_off()
        window_button:turn_off()
        color_picker_button:turn_off()
    end, true)

    screen_button = button(beautiful.icons.computer, "Screen", function()
        screenshot_daemon:set_screenshot_method("screen")
        selection_button:turn_off()
        screen_button:turn_on()
        window_button:turn_off()
        color_picker_button:turn_off()
    end)

    window_button = button(beautiful.icons.window, "Window", function()
        screenshot_daemon:set_screenshot_method("window")
        selection_button:turn_off()
        screen_button:turn_off()
        window_button:turn_on()
        color_picker_button:turn_off()
    end)

    color_picker_button = button(beautiful.icons.palette, "Pick Color", function()
        screenshot_daemon:set_screenshot_method("color_picker")
        selection_button:turn_off()
        screen_button:turn_off()
        window_button:turn_off()
        color_picker_button:turn_on()
    end)

    local title = wibox.widget {
        widget = widgets.text,
        bold = true,
        size = 15,
        text = "Screenshot"
    }

    local settings_button = wibox.widget {
        widget = widgets.button.text.normal,
        forced_width = dpi(50),
        forced_height = dpi(50),
        text_normal_bg = beautiful.icons.camera_retro.color,
        icon = beautiful.icons.gear,
        size = 15,
        on_release = function()
            layout:raise(2)
        end
    }

    local close_button = wibox.widget {
        widget = widgets.button.text.normal,
        forced_width = dpi(50),
        forced_height = dpi(50),
        text_normal_bg = beautiful.icons.camera_retro.color,
        icon = beautiful.icons.xmark,
        on_release = function()
            self:hide()
        end
    }

    local screenshot_button = wibox.widget {
        widget = widgets.button.text.normal,
        forced_width = dpi(50),
        size = 15,
        normal_bg = beautiful.icons.camera_retro.color,
        text_normal_bg = beautiful.colors.on_accent,
        text = "Screenshot",
        on_release = function()
            screenshot_daemon:screenshot()
        end
    }

    return wibox.widget {
        widget = wibox.container.margin,
        margins = dpi(15),
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
                widget = wibox.layout.fixed.horizontal,
                spacing = dpi(15),
                selection_button,
                screen_button,
                window_button,
                color_picker_button
            },
            screenshot_button
        }
    }
end

function main.mt:__call(self, layout)
    return new(self, layout)
end

return setmetatable(main, main.mt)
