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
local GTK_THEME = Gtk.IconTheme.new()
GTK_THEME:set_search_path({filesystem.filesystem.get_awesome_config_dir("assets")})
Gtk.IconTheme.set_custom_theme(GTK_THEME, "candy-icons")

local icons_cache = {}

local function get_icon_path(icon_info)
    if icon_info then
        local icon_path = icon_info:get_filename()

        if not icons_cache[icon_path] then
            icons_cache[icon_path] = { path = icon_path, color = beautiful.colors.random_accent_color() }
        end

        return icons_cache[icon_path]
    end

    return nil
end

function _icon_theme.choose_icon(icons_names)
    local icon_info = GTK_THEME:choose_icon(icons_names, ICON_SIZE, 0);
    return get_icon_path(icon_info) or nil
end

function _icon_theme.get_gicon_path(gicon)
    local icon_info = GTK_THEME:lookup_by_gicon(gicon, ICON_SIZE, 0);
    return get_icon_path(icon_info) or nil
end

function _icon_theme.get_icon_path(icon_name)
    local icon_info = GTK_THEME:lookup_icon(icon_name, ICON_SIZE, 0)
    return get_icon_path(icon_info) or nil
end

function _icon_theme.get_app_icon_path(icon_names)
    if type(icon_names) == "table" then
        table.insert(icon_names, "application-x-ktheme")
        return _icon_theme.choose_icon(icon_names)
    end

    return _icon_theme.choose_icon({icon_names, "application-x-ktheme"})
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
