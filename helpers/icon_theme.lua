-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local lgi = require("lgi")
local Gtk = lgi.require("Gtk", "3.0")
local beautiful = require("beautiful")
local filesystem = require("external.filesystem")
local ipairs = ipairs

local _icon_theme = {}

local ICON_SIZE = 48
local GTK_THEME = Gtk.IconTheme.get_default()
GTK_THEME:set_custom_theme("candy-icons")
GTK_THEME:set_search_path({filesystem.filesystem.get_awesome_config_dir("assets")})

local icons = {}

function _icon_theme.choose_icon(icons_names)
    local icon_info = GTK_THEME:choose_icon(icons_names, ICON_SIZE, 0);
    if icon_info then
        local icon_path = icon_info:get_filename()
        if icon_path then
            return icon_path
        end
    end

    return nil
end

function _icon_theme.get_gicon_path(gicon)
    if gicon == nil then
        return nil
    end

    local icon_info = GTK_THEME:lookup_by_gicon(gicon, ICON_SIZE, 0);
    if icon_info then
        local icon_path = icon_info:get_filename()
        if icon_path then
            return icon_path
        end
    end

    return nil
end

function _icon_theme.get_icon_path(icon_name)
    if icons[icon_name] then
        return icons[icon_name]
    end

    local icon_info = GTK_THEME:lookup_icon(icon_name, ICON_SIZE, 0)
    if icon_info then
        local icon_path = icon_info:get_filename()
        if icon_path then
            icons[icon_name] = { path = icon_path, color = beautiful.colors.random_accent_color() }
            return icons[icon_name]
        end
    end

    return nil
end

function _icon_theme.get_app_icon_path(icon_names)
    if type(icon_names) == "table" then
        return _icon_theme.choose_icon(icon_names) or
                _icon_theme.get_icon_path("application-x-ktheme")
    end

    return _icon_theme.get_icon_path(icon_names) or
            _icon_theme.get_icon_path("application-x-ktheme")
end

function _icon_theme:get_app_font_icon(...)
    local args = { ... }

    for _, arg in ipairs(args) do
        if arg then
            arg = arg:lower()
            arg = arg:gsub("_", "")
            arg = arg:gsub("%s+", "")
            arg = arg:gsub("-", "")
            arg = arg:gsub("%.", "")
            local icon = beautiful.app_icons[arg]
            if icon then
                return icon
            end
        end
    end

    return beautiful.icons.window
end

return _icon_theme
