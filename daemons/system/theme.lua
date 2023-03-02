-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local unpack = unpack or table.unpack -- luacheck: globals unpack (compatibility with Lua 5.1)
local Gio = require("lgi").Gio
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gcolor = require("gears.color")
local gtimer = require("gears.timer")
local wibox = require("wibox")
local beautiful = require("beautiful")
local system_daemon = require("daemons.system.system")
local color_libary = require("external.color")
local helpers = require("helpers")
local filesystem = require("external.filesystem")
local json = require("external.json")
local string = string
local ipairs = ipairs
local pairs = pairs
local table = table
local math = math
local type = type
local os = os
local capi = {
    awesome = awesome,
    root = root,
    screen = screen,
    client = client
}

local theme = {}
local instance = nil

local WALLPAPERS_PATH = filesystem.filesystem.get_awesome_config_dir("assets/wallpapers")
local GTK_THEME_FLAT_COLOR_PATH = filesystem.filesystem.get_awesome_config_dir("assets/gtk-themes/FlatColor")
local GTK_THEME_LINEA_NORD_COLOR = filesystem.filesystem.get_awesome_config_dir("assets/gtk-themes/linea-nord-color")
local GTK_THEME_ALTO_COLOR = filesystem.filesystem.get_awesome_config_dir("assets/gtk-themes/alto-gtk")
local GTK_CONFIG_FILE_PATH = filesystem.filesystem.get_xdg_config_dir("gtk-3.0") .. "settings.ini"
local INSTALLED_GTK_THEMES_PATH = os.getenv("HOME") .. "/.local/share/themes/"
local BASE_TEMPLATES_PATH = filesystem.filesystem.get_awesome_config_dir("assets/templates")
local BACKGROUND_PATH = filesystem.filesystem.get_cache_dir() .. "wallpaper.png"
local GENERATED_TEMPLATES_PATH = filesystem.filesystem.get_cache_dir("templates")
local WAL_CACHE_PATH = filesystem.filesystem.get_xdg_cache_home("wal")
local RUN_AS_ROOT_SCRIPT_PATH = filesystem.filesystem.get_awesome_config_dir("scripts") .. "run-as-root.sh"
local FILE_PICKER_SCRIPT_PATH = filesystem.filesystem.get_awesome_config_dir("scripts") .. "file-picker.lua"
local COLOR_PICKER_SCRIPT_PATH = filesystem.filesystem.get_awesome_config_dir("scripts") .. "color-picker.lua"
local DEFAULT_PROFILE_IMAGE_PATH = filesystem.filesystem.get_awesome_config_dir("assets/images") .. "profile.png"
local WE_PATH = filesystem.filesystem.get_awesome_config_dir("assets/wallpaper-engine/binary")

local PICTURES_MIMETYPES = {
    ["application/pdf"] = "lximage", -- AI
    ["image/x-ms-bmp"] = "lximage", -- BMP
    ["application/postscript"] = "lximage", -- EPS
    ["image/gif"] = "lximage", -- GIF
    ["application/vnd.microsoft.icon"] = "lximage", -- ICo
    ["image/jpeg"] = "lximage", -- JPEG
    ["image/jp2"] = "lximage", -- JPEG 2000
    ["image/png"] = "lximage", -- PNG
    ["image/vnd.adobe.photoshop"] = "lximage", -- PSD
    ["image/svg+xml"] = "lximage", -- SVG
    ["image/tiff"] = "lximage", -- TIFF
    ["image/webp"] = "lximage" -- webp
}

local function distance(hex_src, hex_tgt)
    local color_1 = color_libary.color {
        hex = hex_src
    }
    local color_2 = color_libary.color {
        hex = hex_tgt
    }

    return math.sqrt((color_2.r - color_1.r)^2 + (color_2.g - color_1.g)^2 + (color_2.b - color_1.b)^2)
end

local function closet_color(colors, reference)
    local minDistance = math.huge
    local closest
    local closestIndex
    for i, color in ipairs(colors) do
      local d = distance(color, reference)
      if d < minDistance then
        minDistance = d
        closest = color
        closestIndex = i
      end
    end
    table.remove(colors, closestIndex)
    return closest
  end

local function generate_colorscheme(self, wallpaper, reset, light)
    if self:get_colorschemes()[wallpaper] ~= nil and reset ~= true then
        self:emit_signal("colorscheme::generated", self:get_colorschemes()[wallpaper])
        self:emit_signal("wallpaper::selected", wallpaper)
        return
    end

    self:emit_signal("colorscheme::generating")

    local color_count = 16

    local function imagemagick()
        local raw_colors = {}
        local cmd = string.format("magick %s -resize 25%% -colors %d -unique-colors txt:-", wallpaper, color_count)
        awful.spawn.easy_async_with_shell(cmd, function(stdout)
            for line in stdout:gmatch("[^\r\n]+") do
                local hex = line:match("#(.*) s")
                if hex ~= nil then
                    hex = "#" .. string.sub(hex, 1, 6)
                    table.insert(raw_colors, hex)
                end
            end

            if #raw_colors < 16 then
                if color_count < 37 then
                    print("Imagemagick couldn't generate a palette. Trying a larger palette size " .. color_count)
                    color_count = color_count + 1
                    imagemagick()
                    return
                else
                    print("Imagemagick couldn't generate a suitable palette.")
                    self:emit_signal("colorscheme::failed_to_generate", wallpaper)
                    return
                end
            end

            local colors = raw_colors
            for index = 2, 9 do
                colors[index] = colors[index + 7]
            end

            for index = 10, 15 do
                colors[index] = colors[index - 8]
            end

            if light == true then
                local color1 = colors[1]

                for _, color in ipairs(colors) do
                    color = helpers.color.pywal_saturate_color(color, 0.5)
                end

                colors[1] = helpers.color.pywal_lighten(raw_colors[#raw_colors], 0.85)
                colors[8] = color1
                colors[9] = helpers.color.pywal_darken(raw_colors[#raw_colors], 0.4)
                colors[16] = raw_colors[1]
            else
                if string.sub(colors[1], 2, 2) ~= "0" then
                    colors[1] = helpers.color.pywal_darken(colors[1], 0.4)
                end
                colors[8] = helpers.color.pywal_blend(colors[8], "#EEEEEE")
                colors[9] = helpers.color.pywal_darken(colors[8], 0.3)
                colors[16] = helpers.color.pywal_blend(colors[16], "#EEEEEE")
            end

            local sorted_colors = gtable.clone({unpack(colors, 2, 7)})
            colors[2] = closet_color(sorted_colors, "#FF0000")
            colors[3] = closet_color(sorted_colors, "#00FF00")
            colors[4] = closet_color(sorted_colors, "#FFFF00")
            colors[5] = closet_color(sorted_colors, "#800080")
            colors[6] = closet_color(sorted_colors, "#FF00FF")
            colors[7] = closet_color(sorted_colors, "#0000FF")

            local added_sat = light and 0.5 or 0.3
            local sign = light and -1 or 1

            for index = 10, 15 do
                local color = color_libary.color {
                    hex = colors[index - 8]
                }
                colors[index] = helpers.color.pywal_alter_brightness(colors[index - 8], (sign * color.l * 0.3) / 255, added_sat)
            end

            colors[9] = helpers.color.pywal_alter_brightness(colors[1], sign * 0.098039216)
            colors[16] = helpers.color.pywal_alter_brightness(colors[8], sign * 0.235294118)

            self:emit_signal("colorscheme::generated", colors)
            self:emit_signal("wallpaper::selected", wallpaper)

            self:get_colorschemes()[wallpaper] = colors
            self:save_colorscheme()
        end)
    end

    imagemagick()
end

local function reload_gtk()
    local refresh_gsettings = [[ gsettings set org.gnome.desktop.interface \
gtk-theme '%s' && sleep 0.1 && gsettings set \
org.gnome.desktop.interface gtk-theme '%s'
]]

    local refresh_xfsettings = [[ xfconf-query -c xsettings -p /Net/ThemeName -s \
'%s' && sleep 0.1 && xfconf-query -c xsettings -p \
/Net/ThemeName -s '%s'
]]

    local file = filesystem.file.new_for_path(GTK_CONFIG_FILE_PATH)
    file:read(function(error, content)
        if error == nil then
            local gtk_theme = content:match("gtk%-theme%-name=([^\n]+)")

            helpers.run.is_installed("gsettings", function(is_installed)
                if is_installed == true then
                    awful.spawn.with_shell(string.format(refresh_gsettings, gtk_theme, gtk_theme))
                end
            end)

            helpers.run.is_installed("xfconf-query", function(is_installed)
                if is_installed == true then
                    awful.spawn.with_shell(string.format(refresh_xfsettings, gtk_theme, gtk_theme))
                end
            end)

            helpers.run.is_installed("xsettingsd", function(is_installed)
                if is_installed == true then
                    local path = os.tmpname()
                    local file = filesystem.file.new_for_path(path)

                    file:write(string.format('Net/ThemeName "%s" \n', gtk_theme), function(error)
                        if error == nil then
                            awful.spawn(string.format("timeout 0.2s xsettingsd -c %s", path), false)
                        end
                    end)
                end
            end)
        end
    end)
end

local function reload_awesome_colorscheme()
    local old_colorscheme = beautiful.colors
    beautiful.init(filesystem.filesystem.get_awesome_config_dir("ui") .. "theme.lua")
    local new_colorscheme = beautiful.colors

    local old_colorscheme_to_new_map = {}
    for index, color in pairs(old_colorscheme) do
        old_colorscheme_to_new_map[color] = new_colorscheme[index]
    end

    capi.awesome.emit_signal("colorscheme::changed", old_colorscheme_to_new_map, new_colorscheme)
end

local function on_finished_generating(self)
    if self:get_command_after_generation() ~= nil then
        awful.spawn.with_shell(self:get_command_after_generation())
    end

    reload_gtk()
end

local function generate_sequences(colors)
    local function set_special(index, color, alpha)
        if (index == 11 or index == 708) and alpha ~= 100 then
            return string.format("\27]%s;[%s]%s\27\\", index, alpha, color)
        end

        return string.format("\27]%s;%s\27\\", index, color)
    end

    local function set_color(index, color)
        return string.format("\27]4;%s;%s\27\\", index, color)
    end

    local sequences = ""

    for index, color in ipairs(colors) do
        sequences = sequences .. set_color(index - 1, color)
    end

    sequences = sequences .. set_special(10, colors[16])
    sequences = sequences .. set_special(11, colors[1], 0)
    sequences = sequences .. set_special(12, colors[16])
    sequences = sequences .. set_special(13, colors[16])
    sequences = sequences .. set_special(17, colors[16])
    sequences = sequences .. set_special(19, colors[1])
    sequences = sequences .. set_color(232, colors[1])
    sequences = sequences .. set_color(256, colors[16])
    sequences = sequences .. set_color(257, colors[1])
    sequences = sequences .. set_special(708, colors[1], 0)

    local file = filesystem.file.new_for_path(GENERATED_TEMPLATES_PATH .. "sequences")
    file:write(sequences)

    -- Backwards compatibility with wal/wpgtk
    local file = filesystem.file.new_for_path(WAL_CACHE_PATH .. "sequences")
    file:write(sequences)

    for index = 0, 20 do
        local file = filesystem.file.new_for_path("/dev/pts/" .. index)
        file:exists(function(error, exists)
            if error == nil and exists == true then
                file:write_root(sequences)
            end
        end)
    end
end

local function replace_template_colors(color, color_name, line)
    color = color_libary.color {
        hex = color
    }

    if line:match("{" .. color_name .. ".rgba}") then
        local string = string.format("%s, %s, %s, %s", color.r, color.g, color.b, color.a)
        return line:gsub("{" .. color_name .. ".rgba}", string)
    elseif line:match("{" .. color_name .. ".rgb}") then
        local string = string.format("%s, %s, %s", color.r, color.g, color.b)
        return line:gsub("{" .. color_name .. ".rgb}", string)
    elseif line:match("{" .. color_name .. ".octal}") then
        local string = string.format("%s, %s, %s, %s", color.r, color.g, color.b, color.a)
        return line:gsub("{" .. color_name .. "%.octal}", string)
    elseif line:match("{" .. color_name .. ".xrgba}") then
        local string = string.format("%s/%s/%s/%s", color.r, color.g, color.b, color.a)
        return line:gsub("{" .. color_name .. ".xrgba}", string)
    elseif line:match("{" .. color_name .. ".strip}") then
        local string = color.hex:gsub("#", "")
        return line:gsub("{" .. color_name .. ".strip}", string)
    elseif line:match("{" .. color_name .. ".red}") then
        return line:gsub("{" .. color_name .. ".red}", color.r)
    elseif line:match("{" .. color_name .. ".green}") then
        return line:gsub("{" .. color_name .. ".green}", color.g)
    elseif line:match("{" .. color_name .. ".blue}") then
        return line:gsub("{" .. color_name .. ".blue}", color.b)
    elseif line:match("{" .. color_name .. "}") then
        return line:gsub("{" .. color_name .. "}", color.hex)
    end
end

local function generate_templates(self)
    local on_finished_generating_timer = gtimer {
        timeout = 2,
        call_now = false,
        single_shot = true,
        autostart = false,
        callback = function()
            on_finished_generating(self)
        end
    }

    filesystem.filesystem.iterate_contents(BASE_TEMPLATES_PATH, function(file)
        local name = file:get_name()
        if name:match(".base") ~= nil then
            local template_path = BASE_TEMPLATES_PATH .. name
            local file = filesystem.file.new_for_path(template_path)
            file:read(function(error, content)
                if error == nil then
                    local lines = {}
                    local users = {}
                    local copy_to = {}

                    if content ~= nil then
                        for line in content:gmatch("[^\r\n$]+") do
                            if line:match("{{") then
                                line = line:gsub("{{", "{")
                            end
                            if line:match("}}") then
                                line = line:gsub("}}", "}")
                            end

                            if line:match("user=") then
                                local user = line:gsub("user=", "")
                                table.insert(users, user)
                                line = ""
                            end
                            if line:match("copy_to=") then
                                local path = line:gsub("copy_to=", "")
                                table.insert(copy_to, path)
                                line = ""
                            end

                            local colors = self:get_active_colorscheme_colors()

                            for index = 0, 15 do
                                local color = replace_template_colors(colors[index + 1], "color" .. index, line)
                                if color ~= nil then
                                    line = color
                                end
                            end

                            local background = replace_template_colors(colors[1], "background", line)
                            if background ~= nil then
                                line = background
                            end

                            local foreground = replace_template_colors(colors[16], "foreground", line)
                            if foreground ~= nil then
                                line = foreground
                            end

                            local cursor = replace_template_colors(colors[16], "cursor", line)
                            if cursor ~= nil then
                                line = cursor
                            end

                            if line:match("{wallpaper}") then
                                line = line:gsub("{wallpaper}", self:get_active_wallpaper())
                            end

                            table.insert(lines, line)
                        end
                    end

                    local same_user = false
                    if #users > 0 then
                        for _, user in ipairs(users) do
                            if user == os.getenv("USER") then
                                same_user = true
                            end
                        end
                        if same_user == false then
                            return
                        end
                    end

                    -- Store the output as a string
                    local output = table.concat(lines, "\n")

                    -- Get the name of the file
                    name = name:gsub(".base", "")

                    -- Save to ~/.cache/awesome/templates
                    local file = filesystem.file.new_for_path(GENERATED_TEMPLATES_PATH .. name)
                    file:write(output)

                    -- Backwards compatibility with wal/wpgtk
                    local file = filesystem.file.new_for_path(WAL_CACHE_PATH .. name)
                    file:write(output, function()
                        -- Save to addiontal location specified in the template file
                        for _, path in ipairs(copy_to) do
                            path = path:gsub("~", os.getenv("HOME"))
                            if path:match(os.getenv("HOME")) then
                                local file = filesystem.file.new_for_path(path)
                                file:write(output)
                            else
                                awful.spawn.with_shell(RUN_AS_ROOT_SCRIPT_PATH .. " 'cp -r " .. WAL_CACHE_PATH .. name .. " " .. path.. "'")
                            end
                        end
                    end)
                end
            end)
        end
    end, {
        recursive = true
    }, function()
        on_finished_generating_timer:again()
    end)
end

local function install_gtk_theme()
    awful.spawn(string.format("cp -r %s %s", GTK_THEME_FLAT_COLOR_PATH, INSTALLED_GTK_THEMES_PATH), false)
    awful.spawn(string.format("cp -r %s %s", GTK_THEME_LINEA_NORD_COLOR, INSTALLED_GTK_THEMES_PATH), false)
    awful.spawn(string.format("cp -r %s %s", GTK_THEME_ALTO_COLOR, INSTALLED_GTK_THEMES_PATH), false)
end

local function on_wallpaper_changed()
    gtimer.start_new(1, function()
        capi.awesome.emit_signal("wallpaper::changed", BACKGROUND_PATH)
        return false
    end)
end

local function image_wallpaper(self, screen)
    local widget = wibox.widget {
        widget = wibox.widget.imagebox,
        resize = true,
        horizontal_fit_policy = "fit",
        vertical_fit_policy = "fit",
        image = self:get_active_wallpaper()
    }

    self._private.wallpaper_widget = widget

    awful.wallpaper {
        screen = screen,
        widget = widget
    }
end

local function mountain_wallpaper(self, screen)
    local colors = self:get_active_wallpaper_colors()

    local widget = wibox.widget {
        layout = wibox.layout.stack,
        {
            widget = wibox.container.background,
            id = "background",
            bg = {
                type = 'linear',
                from = {0, 0},
                to = {0, 100},
                stops = {
                    {0, beautiful.colors.random_accent_color(colors)},
                    {0.75, beautiful.colors.random_accent_color(colors)},
                    {1, beautiful.colors.random_accent_color(colors)}
                }
            }
        },
        {
            widget = wibox.widget.imagebox,
            resize = true,
            horizontal_fit_policy = "fit",
            vertical_fit_policy = "fit",
            image = beautiful.mountain_background
        },
    }

    self._private.wallpaper_widget = widget

    awful.wallpaper {
        screen = screen,
        widget = widget
    }
end

local function digital_sun_wallpaper(self, screen)
    local colors = self:get_active_wallpaper_colors()

    local widget =  wibox.widget {
        fit = function(_, width, height)
            return width, height
        end,
        draw = function(self, _, cr, width, height)
            cr:set_source(gcolor {
                type = 'linear',
                from = {0, 0},
                to = {0, height},
                stops = {
                    {0, colors[1]},
                    {0.75, colors[9]},
                    {1, colors[1]}
                }
            })
            cr:paint()
            -- Clip the first 33% of the screen
            cr:rectangle(0, 0, width, height / 3)

            -- Clip-out some increasingly large sections of add the sun "bars"
            for i = 0, 6 do
                cr:rectangle(0, height * .28 + i * (height * .055 + i / 2), width, height * .055)
            end
            cr:clip()

            -- Draw the sun
            cr:set_source(gcolor {
                type = 'linear',
                from = {0, 0},
                to = {0, height},
                stops = {
                    {0, beautiful.colors.random_accent_color(colors)},
                    {1, beautiful.colors.random_accent_color(colors)}
                }
            })
            cr:arc(width / 2, height / 2, height * .35, 0, math.pi * 2)
            cr:fill()

            -- Draw the grid
            local lines = width / 8
            cr:reset_clip()
            cr:set_line_width(0.5)
            cr:set_source(gcolor(beautiful.colors.random_accent_color(colors)))

            for i = 1, lines do
                cr:move_to((-width) + i * math.sin(i * (math.pi / (lines * 2))) * 30, height)
                cr:line_to(width / 4 + i * ((width / 2) / lines), height * 0.75 + 2)
                cr:stroke()
            end

            for i=1, 10 do
                cr:move_to(0, height*0.75 + i*30 + i*2)
                cr:line_to(width, height*0.75 + i*30 + i*2)
                cr:stroke()
            end
        end
    }

    self._private.wallpaper_widget = widget

    awful.wallpaper {
        screen = screen,
        widget = widget
    }
end

local function binary_wallpaper(self, screen)
    local function binary()
        local ret = {}
        for _ = 1, 30 do
            for _ = 1, 100 do
                table.insert(ret, math.random() > 0.5 and 1 or 0)
            end
            table.insert(ret, "\n")
        end

        return table.concat(ret)
    end

    local colors = self:get_active_wallpaper_colors()

    local widget = wibox.widget {
        widget = wibox.layout.stack,
        {
            widget = wibox.container.background,
            fg = beautiful.colors.random_accent_color(colors),
            {
                widget = wibox.widget.textbox,
                halign = "center",
                valign = "center",
                markup = "<tt><b>[SYSTEM FAILURE]</b></tt>"
            }
        },
        {
            widget = wibox.widget.textbox,
            halign = "center",
            valign = "center",
            wrap = "word",
            text = binary()
        }
    }

    self._private.wallpaper_widget = widget

    awful.wallpaper {
        screen = screen,
        bg = colors[1],
        fg = beautiful.colors.random_accent_color(colors),
        widget = widget
    }
end

local function get_we_wallpaper_id(path)
    local last_slash_pos = path:find("/[^/]*$")
    if last_slash_pos then
      local prefix = path:sub(1, last_slash_pos - 1)
      local second_to_last_slash_pos = prefix:find("/[^/]*$")

      if second_to_last_slash_pos then
        local substring = prefix:sub(second_to_last_slash_pos + 1, last_slash_pos - 1)
        return substring
      end
    end
end

local function we_wallpaper(self, screen)
    local id = get_we_wallpaper_id(self:get_active_wallpaper())
    local cmd = string.format("cd %s && ./linux-wallpaperengine --assets-dir %s %s --fps %s --class linux-wallpaperengine --x %s --y %s --width %s --height %s",
        WE_PATH,
        self:get_wallpaper_engine_assets_folder(),
        self:get_wallpaper_engine_workshop_folder() .. "/" .. id,
        self:get_wallpaper_engine_fps(),
        screen.geometry.x,
        screen.geometry.y,
        screen.geometry.width,
        screen.geometry.height
    )

    awful.spawn.easy_async_with_shell(cmd, function()
        on_wallpaper_changed()
    end)

end

local function scan_wallpapers(self)
    self._private.wallpapers = {}
    self._private.we_wallpapers = {}

    local emit_signal_timer = gtimer {
        timeout = 0.5,
        autostart = false,
        single_shot = true,
        callback = function()
            table.sort(self._private.wallpapers, function(a, b)
                return a < b
            end)

            table.sort(self._private.we_wallpapers, function(a, b)
                return a.title < b.title
            end)

            self:set_selected_colorscheme(self:get_selected_colorscheme())
            self:emit_signal("wallpapers", self._private.wallpapers, self._private.we_wallpapers)
        end
    }

    filesystem.filesystem.iterate_contents(WALLPAPERS_PATH, function(file)
        local wallpaper_path = WALLPAPERS_PATH .. file:get_name()
        local mimetype = Gio.content_type_guess(wallpaper_path)
        if PICTURES_MIMETYPES[mimetype] ~= nil then
            table.insert(self._private.wallpapers, wallpaper_path)
        end
    end, {}, function()
        emit_signal_timer:again()
    end)

    filesystem.filesystem.iterate_contents(self:get_wallpaper_engine_workshop_folder(), function(file, path, name)
        if type(path) == "string" then
            local mimetype = Gio.content_type_guess(path)
            if PICTURES_MIMETYPES[mimetype] ~= nil then
                local json_path = path:gsub("/" .. name, "") .. "/project.json"
                local json_file = filesystem.file.new_for_path(json_path)
                json_file:exists(function(error, exists)
                    if error == nil and exists then
                        json_file:read(function(error, content)
                            if error == nil then
                                local title = json.decode(content).title
                                table.insert(self._private.we_wallpapers, { path = path, title = title})
                            end
                        end)
                    end
                end)
            end
        end
    end, {}, function()
    end)
end

local function watch_wallpapers_changes(self)
    local wallpapers_watcher = helpers.inotify:watch(WALLPAPERS_PATH,
        {helpers.inotify.Events.create, helpers.inotify.Events.delete, helpers.inotify.Events.moved_from,
         helpers.inotify.Events.moved_to})
    wallpapers_watcher:connect_signal("event", function()
        scan_wallpapers(self)
    end)
end

local function setup_profile_image(self)
    if self:get_profile_image(true) == "none" then
        local profile_image = filesystem.file.new_for_path(os.getenv("HOME") .. "/.face")
        profile_image:exists(function(error, exists)
            if error == nil and exists == true then
                self:set_profile_image(os.getenv("HOME") .. "/.face")
            else
                profile_image = filesystem.file.new_for_path("/var/lib/AccountService/icons/" .. os.getenv("USER"))
                profile_image:exists(function(error, exists)
                    if error == nil and exists == true then
                        self:set_profile_image("/var/lib/AccountService/icons/" .. os.getenv("USER"))
                    else
                        self:set_profile_image(DEFAULT_PROFILE_IMAGE_PATH)
                    end
                end)
            end
        end)
    end
end

--Colorschemes
function theme:save_colorscheme()
    helpers.settings["theme-colorschemes"] = self._private.colorschemes
end

function theme:get_colorschemes()
    if self._private.colorschemes == nil then
        self._private.colorschemes = {}
        local colorschemes = helpers.settings["theme-colorschemes"]
        for path, colorscheme in pairs(colorschemes) do
            path = path:gsub("~", os.getenv("HOME"))
            self._private.colorschemes[path] = colorscheme
        end
    end

    return self._private.colorschemes
end

function theme:reset_colorscheme()
    local bg = self:get_selected_colorscheme_colors()[1]
    local light = not helpers.color.is_dark(bg)
    generate_colorscheme(self, self:get_selected_colorscheme(), true, light)
end

function theme:toggle_dark_light()
    local bg = self:get_selected_colorscheme_colors()[1]
    local light = helpers.color.is_dark(bg)
    generate_colorscheme(self, self:get_selected_colorscheme(), true, light)
end

function theme:edit_color(index)
    awful.spawn.easy_async(COLOR_PICKER_SCRIPT_PATH .. " '" .. self:get_selected_colorscheme_colors()[index] .. "'", function(stdout)
        stdout = helpers.string.trim(stdout)
        if stdout ~= "" and stdout ~= nil then
            self:get_selected_colorscheme_colors()[index] = stdout
            self:emit_signal("color::" .. index .. "::updated", stdout)
        end
    end)
end

-- Wallpaper
function theme:set_wallpaper(wallpaper, type)
    self._private.active_wallpaper = wallpaper
    helpers.settings["theme-active-wallpaper"] = wallpaper

    self._private.wallpaper_type = type
    helpers.settings["theme-wallpaper-type"] = type

    awful.spawn("pkill -f linux-wallpaperengine")

    for s in capi.screen do
        if self:get_wallpaper_type() == "image" then
            image_wallpaper(self, s)
        elseif self:get_wallpaper_type() == "mountain" then
            mountain_wallpaper(self, s)
        elseif self:get_wallpaper_type() == "digital_sun" then
            digital_sun_wallpaper(self, s)
        elseif self:get_wallpaper_type() == "binary" then
            binary_wallpaper(self, s)
        elseif self:get_wallpaper_type() == "we" then
            we_wallpaper(self, s)
        end
    end

    if self:get_wallpaper_type() ~= "we" then
        wibox.widget.draw_to_svg_file(
            self._private.wallpaper_widget,
            BACKGROUND_PATH,
            capi.screen.primary.geometry.width,
            capi.screen.primary.geometry.height
        )
        on_wallpaper_changed()
    end
end

function theme:get_wallpaper_path()
    return BACKGROUND_PATH
end

function theme:get_wallpaper_type()
    if self._private.wallpaper_type == nil then
        self._private.wallpaper_type = helpers.settings["theme-wallpaper-type"]
    end

    return self._private.wallpaper_type
end

function theme:get_active_wallpaper()
    if self._private.active_wallpaper == nil then
        self._private.active_wallpaper = helpers.settings["theme-active-wallpaper"]:gsub("~", os.getenv("HOME"))
    end

    return self._private.active_wallpaper
end

function theme:get_active_wallpaper_colors()
    return self:get_colorschemes()[self:get_active_wallpaper()]
end

function theme:get_short_wallpaper_name(wallpaper_path)
    return wallpaper_path:gsub(WALLPAPERS_PATH, "")
end

-- Active colorscheme
function theme:set_colorscheme(colorscheme)
    self._private.active_colorscheme = colorscheme
    helpers.settings["theme-active-colorscheme"] = colorscheme

    self:save_colorscheme()

    reload_awesome_colorscheme()
    install_gtk_theme()
    generate_templates(self)
    generate_sequences(self:get_active_colorscheme_colors())
end

function theme:get_active_colorscheme()
    if self._private.active_colorscheme == nil then
        self._private.active_colorscheme = helpers.settings["theme-active-colorscheme"]:gsub("~", os.getenv("HOME"))
    end

    return self._private.active_colorscheme
end

function theme:get_active_colorscheme_colors()
    return self:get_colorschemes()[self:get_active_colorscheme()]
end

-- Selected colorscheme
function theme:set_selected_colorscheme(colorscheme)
    self._private.selected_colorscheme = colorscheme
    generate_colorscheme(self, colorscheme)
end

function theme:get_selected_colorscheme()
    return self._private.selected_colorscheme or self:get_active_colorscheme()
end

function theme:get_selected_colorscheme_colors()
    return self:get_colorschemes()[self:get_selected_colorscheme()]
end

-- UI profile image
function theme:set_profile_image(profile_image)
    self._private.profile_image = profile_image
    helpers.settings["theme-profile-image"] = profile_image
    self:emit_signal("profile_image", profile_image)
end

function theme:set_profile_image_with_file_picker()
    awful.spawn.easy_async(FILE_PICKER_SCRIPT_PATH, function(stdout)
        stdout = helpers.string.trim(stdout)
        if stdout ~= "" and stdout ~= nil then
            self:set_profile_image(stdout)
        end
    end)
end

function theme:get_profile_image(internal)
    if self._private.profile_image == nil then
        self._private.profile_image = helpers.settings["theme-profile-image"]
    end
    -- If it's none, return the default until the setup_profile_image function finishes running
    if self._private.profile_image == "none" and (internal == false or internal == nil) then
        return DEFAULT_PROFILE_IMAGE_PATH
    end

    return self._private.profile_image
end

-- UI dpi
function theme:set_dpi(dpi)
    self._private.dpi = dpi
    helpers.settings["theme-dpi"] = dpi
end

function theme:get_dpi()
    if self._private.dpi == nil then
        self._private.dpi = helpers.settings["theme-dpi"]
    end

    return self._private.dpi
end

-- UI opacity
function theme:set_ui_opacity(opacity)
    self._private.ui_opacity = opacity
    helpers.settings["theme-ui-opacity"] = opacity
    reload_awesome_colorscheme()
end

function theme:get_ui_opacity()
    if self._private.ui_opacity == nil then
        self._private.ui_opacity = helpers.settings["theme-ui-opacity"]
    end

    return self._private.ui_opacity
end

-- UI border radius
function theme:set_ui_border_radius(border_radius)
    self._private.ui_border_radius = border_radius
    helpers.settings["theme-ui-border-radius"] = border_radius
    reload_awesome_colorscheme()
end

function theme:get_ui_border_radius()
    if self._private.ui_border_radius == nil then
        self._private.ui_border_radius = helpers.settings["theme-ui-border-radius"]
    end

    return self._private.ui_border_radius
end

-- Useless gaps
function theme:set_useless_gap(useless_gap, save)
    for _, tag in ipairs(capi.root.tags()) do
        tag.gap = useless_gap
    end

    for screen in capi.screen do
        awful.layout.arrange(screen)
    end

    self._private.useless_gap = useless_gap
    if save ~= false then
        helpers.settings["theme-useless-gap"] = useless_gap
    end
end

function theme:get_useless_gap()
    if self._private.useless_gap == nil then
        self._private.useless_gap = helpers.settings["theme-useless-gap"]
    end

    return self._private.useless_gap
end

-- Client gaps
function theme:set_client_gap(client_gap, save)
    for screen in capi.screen do
        screen.padding = {
            left = client_gap,
            right = client_gap,
            top = client_gap,
            bottom = client_gap
        }
        awful.layout.arrange(screen)
    end

    self._private.client_gap = client_gap
    if save ~= false then
        helpers.settings["theme-client-gap"] = client_gap
    end
end

function theme:get_client_gap()
    if self._private.client_gap == nil then
        self._private.client_gap = helpers.settings["theme-client-gap"]
    end

    return self._private.client_gap
end

-- UI animations
function theme:set_ui_animations(animations, save)
    helpers.animation:set_instant(not animations)

    if save ~= false then
        self._private.ui_animations = animations
        helpers.settings["theme-ui-animations"] = animations
    end
end

function theme:get_ui_animations()
    if self._private.ui_animations == nil then
        self._private.ui_animations = helpers.settings["theme-ui-animations"]
    end

    return self._private.ui_animations
end

function theme:set_ui_animations_framerate(framerate)
    helpers.animation:set_framerate(framerate)
    self._private.ui_animations = framerate
    helpers.settings["theme-ui-animations-framerate"] = framerate
end

function theme:get_ui_animations_framerate()
    if self._private.get_ui_animations_framerate == nil then
        self._private.get_ui_animations_framerate = helpers.settings["theme-ui-animations-framerate"]
    end

    return self._private.get_ui_animations_framerate
end

-- Command after generation
function theme:set_command_after_generation(command_after_generation)
    self._private.command_after_generation = command_after_generation
    helpers.settings["theme-command-after-generation"] = command_after_generation
end

function theme:get_command_after_generation()
    if self._private.command_after_generation == nil then
        self._private.command_after_generation = helpers.settings["theme-command-after-generation"]
    end

    return self._private.command_after_generation
end

-- Wallpaper engine assets folder
function theme:set_wallpaper_engine_assets_folder(wallpaper_engine_assets_folder)
    self._private.wallpaper_engine_assets_folder = wallpaper_engine_assets_folder
    helpers.settings["theme-we-assets-folder"] = wallpaper_engine_assets_folder
end

function theme:get_wallpaper_engine_assets_folder()
    if self._private.wallpaper_engine_assets_folder == nil then
        self._private.wallpaper_engine_assets_folder = helpers.settings["theme-we-assets-folder"]:gsub("~", os.getenv("HOME"))
    end

    return self._private.wallpaper_engine_assets_folder
end

-- Wallpaper engine assets folder
function theme:set_wallpaper_engine_workshop_folder(wallpaper_engine_workshop_folder)
    self._private.wallpaper_engine_workshop_folder = wallpaper_engine_workshop_folder
    helpers.settings["theme-we-workshop-folder"] = wallpaper_engine_workshop_folder
    scan_wallpapers(self)
end

function theme:get_wallpaper_engine_workshop_folder()
    if self._private.wallpaper_engine_workshop_folder == nil then
        self._private.wallpaper_engine_workshop_folder = helpers.settings["theme-we-workshop-folder"]:gsub("~", os.getenv("HOME"))
    end

    return self._private.wallpaper_engine_workshop_folder
end

-- Wallpaper engine fps
function theme:set_wallpaper_engine_fps(wallpaper_engine_fps)
    self._private.wallpaper_engine_fps = wallpaper_engine_fps
    helpers.settings["theme-we-fps"] = wallpaper_engine_fps
end

function theme:get_wallpaper_engine_fps()
    if self._private.wallpaper_engine_fps == nil then
        self._private.wallpaper_engine_fps = helpers.settings["theme-we-fps"]
    end

    return self._private.wallpaper_engine_fps
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, theme, true)

    ret._private = {}

    gtimer.delayed_call(function()
        ret:set_client_gap(ret:get_client_gap(), false)
        ret:set_ui_animations(ret:get_ui_animations())
        ret:set_ui_animations_framerate(ret:get_ui_animations_framerate())
        helpers.run.is_running("linux-wallpaperengine", function(is_running)
            if is_running and ret:get_wallpaper_type() == "we" then
                return
            end
            ret:set_wallpaper(ret:get_active_wallpaper(), ret:get_wallpaper_type())
        end)
    end)

    setup_profile_image(ret)
    scan_wallpapers(ret)
    watch_wallpapers_changes(ret)

    return ret
end

if not instance then
    instance = new()
end
return instance
