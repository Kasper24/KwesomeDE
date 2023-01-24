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

local function command_after_generation_widget()
    local title = wibox.widget
    {
        widget = widgets.text,
        size = 15,
        text = "Run after generation:"
    }

    local prompt = widgets.prompt
    {
        forced_width = dpi(600),
        forced_height = dpi(50),
        reset_on_stop = false,
        prompt = "",
        text = theme_daemon:get_command_after_generation(),
        text_color = beautiful.colors.on_background,
        icon_font = beautiful.icons.launcher.font,
        icon = nil,
        changed_callback = function(text)
            theme_daemon:set_command_after_generation(text)
        end
    }

    return wibox.widget
    {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(5),
        title,
        prompt.widget
    }
end

local function new(layout)
    local back_button = widgets.button.text.normal
    {
        forced_width = dpi(50),
        forced_height = dpi(50),
        font = beautiful.icons.left.font,
        text = beautiful.icons.left.icon,
        on_release = function()
            layout:raise(2)
        end
    }

    local settings_text = wibox.widget
    {
        widget = widgets.text,
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
            command_after_generation_widget()
        }
    }
end

function settings.mt:__call(layout)
    return new(layout)
end

return setmetatable(settings, settings.mt)