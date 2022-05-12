local beautiful = require("beautiful")
local bling = require("modules.bling")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi

local instance = nil

local function new()
    return bling.widget.app_launcher
    {
        skip_names = { "avahi", "Hardware Local", "networkmanager_dmenu" },
        type = "menu",
        terminal = "kitty",
        background = beautiful.colors.background,
        prompt_height = dpi(50),
        prompt_margins = dpi(25),
        prompt_paddings = dpi(15),
        prompt_shape = helpers.ui.rrect(beautiful.border_radius),
        prompt_color = helpers.color.lighten(beautiful.colors.surface, 20),
        prompt_icon_color = beautiful.colors.on_background,
        prompt_text_color = beautiful.colors.on_background,
        prompt_cursor_color = beautiful.colors.on_background,
        app_default_icon = beautiful.profile_icon,
        app_width = dpi(150),
        app_height = dpi(150),
        apps_spacing = dpi(15),
        apps_per_row =  5,
        apps_per_column = 5,
        app_selected_color = beautiful.random_accent_color(),
        app_normal_color = string.sub(beautiful.colors.background, 1, 7) .. "00",
        app_shape = helpers.ui.rrect(beautiful.bor1der_radius),
        app_name_font = beautiful.font_name .. 12,
        apps_margin = { left = dpi(40), right  = dpi(40), bottom = dpi(30) }
    }
end

if not instance then
    instance = new()
end
return instance