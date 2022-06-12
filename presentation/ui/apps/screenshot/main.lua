-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local beautiful = require("beautiful")
local screenshot_daemon = require("daemons.system.screenshot")
local dpi = beautiful.xresources.apply_dpi

local main = { mt = {} }

local function button(icon, text, on_release, on_by_default)
    local icon = widgets.text
    {
        halign = "center",
        font = icon.font,
        text = icon.icon
    }

    local text = widgets.text
    {
        halign = "center",
        size = 12,
        text = text
    }

    return widgets.button.elevated.state
    {
        on_by_default = on_by_default,
        forced_width = dpi(120),
        forced_height = dpi(120),
        normal_bg = beautiful.colors.surface,
        on_release = function(self)
            on_release(self)
        end,
        child = wibox.widget
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            icon,
            text
        }
    }
end

local function new(self, layout)
    local accent_color = beautiful.random_accent_color()

    local selection_button = nil
    local screen_button = nil
    local window_button = nil
    local flameshot_button = nil

    selection_button = button
    (
        beautiful.scissors_icon,
        "Selection",
        function()
            screenshot_daemon:set_screenshot_method("selection")
            selection_button:turn_on()
            screen_button:turn_off()
            window_button:turn_off()
            flameshot_button:turn_off()
        end,
        true
    )

    screen_button = button
    (
        beautiful.computer_icon,
        "Screen",
        function()
            screenshot_daemon:set_screenshot_method("screen")
            selection_button:turn_off()
            screen_button:turn_on()
            window_button:turn_off()
            flameshot_button:turn_off()
        end
    )

    window_button = button
    (
        beautiful.window_icon,
        "Window",
        function()
            screenshot_daemon:set_screenshot_method("window")
            selection_button:turn_off()
            screen_button:turn_off()
            window_button:turn_on()
            flameshot_button:turn_off()
        end
    )

    flameshot_button = button
    (
        beautiful.flameshot_icon,
        "Flameshot",
        function()
            screenshot_daemon:set_screenshot_method("flameshot")
            selection_button:turn_off()
            screen_button:turn_off()
            window_button:turn_off()
            flameshot_button:turn_on()
        end
    )

    local title = widgets.text
    {
        bold = true,
        size = 15,
        text = "Screenshot",
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

    local screenshot_button = widgets.button.text.normal
    {
        forced_width = dpi(50),
        size = 15,
        normal_bg = beautiful.random_accent_color(),
        text_normal_bg = beautiful.colors.background,
        text = "Screenshot",
        animate_size = false,
        on_release = function()
            screenshot_daemon:screenshot()
        end
    }

    return wibox.widget
    {
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
                flameshot_button
            },
            screenshot_button
        }
    }
end

function main.mt:__call(self, layout)
    return new(self, layout)
end

return setmetatable(main, main.mt)
