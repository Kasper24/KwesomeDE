local awful = require("awful")
local beautiful = require("beautiful")
local bling = require("modules.bling")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi

local instance = nil

local function new()
    return bling.widget.app_launcher
    {
        placement = function(widget)
            awful.placement.top_left(widget,
            {
                honor_workarea = true,
                honor_padding = true,
                attach = true
            })
        end,
        app_show_icon = false,
        skip_names = { "avahi", "Hardware Local", "networkmanager_dmenu" },
        type = "menu",
        terminal = "kitty",
        background = beautiful.colors.background,
        prompt_height = dpi(50),
        prompt_margins = dpi(25),
        prompt_paddings = dpi(15),
        prompt_shape = helpers.ui.rrect(beautiful.border_radius),
        prompt_color = beautiful.colors.background,
        prompt_icon_color = beautiful.colors.on_background,
        prompt_text_color = beautiful.colors.on_background,
        prompt_cursor_color = beautiful.colors.on_background,
        app_default_icon = beautiful.profile_icon,
        app_width = dpi(400),
        app_height = dpi(75),
        app_name_halign = "left",
        apps_spacing = dpi(15),
        apps_per_row =  9,
        apps_per_column = 1,
        app_selected_color = beautiful.random_accent_color(),
        app_normal_color = beautiful.colors.background,
        app_shape = helpers.ui.rrect(beautiful.bor1der_radius),
        app_name_font = beautiful.font_name .. 14,
        -- apps_margin = { left = dpi(40), right  = dpi(40), bottom = dpi(30) }
    }
end

if not instance then
    instance = new()
end
return instance