-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("ui.widgets")
local bling = require("external.bling")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local capi = {
    awesome = awesome
}

local instance = nil

local function new()
    local app_on_accent_color = beautiful.colors.random_accent_color()

    local app_launcher = bling.widget.app_launcher {
        placement = function(widget)
            awful.placement.top_left(widget, {
                honor_workarea = true,
                honor_padding = true,
                attach = true
            })
        end,
        background = beautiful.colors.background,
        prompt_height = dpi(50),
        prompt_margins = dpi(25),
        prompt_paddings = dpi(15),
        prompt_shape = helpers.ui.rrect(),
        prompt_color = beautiful.colors.background,
        prompt_icon_color = beautiful.colors.on_background,
        prompt_text_color = beautiful.colors.on_background,
        prompt_cursor_color = beautiful.colors.on_background,
        expand_apps = true,
        apps_spacing = dpi(15),
        apps_per_row = 5,
        apps_per_column = 4,
        apps_margin = { left = dpi(40), right  = dpi(40), bottom = dpi(30) },
        app_template = function(app)
            local button = wibox.widget {
                widget = widgets.button.text.state,
                forced_width = dpi(200),
                forced_height = dpi(60),
                id = "button",
                size = 12,
                on_normal_bg = app_on_accent_color,
                text_normal_bg = beautiful.colors.on_background,
                text_on_normal_bg = beautiful.colors.on_accent,
                text = app.name
            }

            button:connect_signal("selected", function()
                button:turn_on()
            end)

            button:connect_signal("unselected", function()
                button:turn_off()
            end)

            return button
        end,
    }

    capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
        app_launcher._private.widget.widget.bg = old_colorscheme_to_new_map[beautiful.colors.background]
    end)

    return app_launcher
end

if not instance then
    instance = new()
end
return instance
