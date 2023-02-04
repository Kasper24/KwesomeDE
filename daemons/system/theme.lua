-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local lgi = require("lgi")
local Gdk = lgi.require("Gdk", "3.0")
local Gio = require("lgi").Gio
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gcolor = require("gears.color")
local gtimer = require("gears.timer")
local wibox = require("wibox")
local beautiful = require("beautiful")
local color_libary = require("external.color")
local helpers = require("helpers")
local string = string
local ipairs = ipairs
local pairs = pairs
local table = table
local os = os
local capi = {
    awesome = awesome,
    screen = screen,
    client = client
}

local theme = {}
local instance = nil

local COLORSCHEME_DATA_PATH = helpers.filesystem.get_cache_dir("colorschemes") .. "data.json"
local WALLPAPERS_PATH = helpers.filesystem.get_awesome_config_dir("ui/assets/wallpapers")
local GTK_THEME_PATH = helpers.filesystem.get_awesome_config_dir("config/FlatColor")
local INSTALLED_GTK_THEME_PATH = os.getenv("HOME") .. "/.local/share/themes/"
local BASE_TEMPLATES_PATH = helpers.filesystem.get_awesome_config_dir("config/templates")
local BACKGROUND_PATH = helpers.filesystem.get_cache_dir("") .. "wallpaper"
local GENERATED_TEMPLATES_PATH = helpers.filesystem.get_cache_dir("templates")
local WAL_CACHE_PATH = helpers.filesystem.get_xdg_cache_home("wal")

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

local function generate_colorscheme(self, wallpaper, reset, light)
    if self._private.colors[wallpaper] ~= nil and reset ~= true then
        self:emit_signal("colorscheme::generated", self._private.colors[wallpaper])
        self:emit_signal("wallpaper::selected", wallpaper)
        return
    end

    self:emit_signal("colorscheme::generating")

    local color_count = 16

    local function imagemagick()
        local colors = {}
        local cmd = string.format("magick %s -resize 25%% -colors %d -unique-colors txt:-", wallpaper, color_count)
        awful.spawn.easy_async_with_shell(cmd, function(stdout)
            for line in stdout:gmatch("[^\r\n]+") do
                local hex = line:match("#(.*) s")
                if hex ~= nil then
                    hex = "#" .. string.sub(hex, 1, 6)
                    table.insert(colors, hex)
                end
            end

            if #colors < 16 then
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

            for index = 2, 9 do
                colors[index] = colors[index + 7]
            end

            for index = 10, 15 do
                colors[index] = colors[index - 8]
            end

            if light == true then
                local color1 = colors[1]
                local color8 = colors[8]

                for _, color in ipairs(colors) do
                    color = helpers.color.pywal_saturate_color(color, 0.5)
                end

                colors[1] = helpers.color.pywal_lighten(colors[16], 0.5)
                colors[8] = color1
                colors[9] = helpers.color.pywal_darken(colors[16], 0.3)
                colors[16] = colors[8]
            else
                if string.sub(colors[1], 2, 2) ~= "0" then
                    colors[1] = helpers.color.pywal_darken(colors[1], 0.4)
                end
                colors[8] = helpers.color.pywal_blend(colors[8], "#EEEEEE")
                colors[9] = helpers.color.pywal_darken(colors[8], 0.3)
                colors[16] = colors[8]
            end

            local added_sat = light == true and 0.5 or 0.3
            local sign = light == true and -1 or 1

            for index = 10, 15 do
                local color = color_libary.color {
                    hex = colors[index - 8]
                }
                colors[index] = helpers.color.pywal_alter_brightness(colors[index - 8], sign * color.l * 0.3, added_sat)
            end

            colors[9] = helpers.color.pywal_alter_brightness(colors[1], sign * 0.098039216)
            colors[16] = helpers.color.pywal_alter_brightness(colors[8], sign * 0.098039216)

            self:emit_signal("colorscheme::generated", colors)
            self:emit_signal("wallpaper::selected", wallpaper)

            self._private.colors[wallpaper] = colors

            local file = helpers.file.new_for_path(COLORSCHEME_DATA_PATH)
            file:write(helpers.json.encode(self._private.colors, {
                indent = true
            }))
        end)
    end

    imagemagick()
end

local function reload_gtk()
    local refresh_gsettings = [[ gsettings set org.gnome.desktop.interface \
gtk-theme 'FlatColor' && sleep 0.1 && gsettings set \
org.gnome.desktop.interface gtk-theme 'FlatColor'
]]

    local refresh_xfsettings = [[ xfconf-query -c xsettings -p /Net/ThemeName -s \
'FlatColor' && sleep 0.1 && xfconf-query -c xsettings -p \
/Net/ThemeName -s 'FlatColor'
]]

    helpers.run.is_installed("gsettings", function(is_installed)
        if is_installed == true then
            awful.spawn.with_shell(refresh_gsettings)
        end
    end)

    helpers.run.is_installed("xfconf-query", function(is_installed)
        if is_installed == true then
            awful.spawn.with_shell(refresh_xfsettings)
        end
    end)

    helpers.run.is_installed("xsettingsd", function(is_installed)
        if is_installed == true then
            local path = os.tmpname()
            local file = helpers.file.new_for_path(path)
            file:write('Net/ThemeName "FlatColor" \n', function(error)
                if error == nil then
                    awful.spawn(string.format("timeout 0.2s xsettingsd -c %s", path), false)
                end
            end)
        end
    end)
end

local function reload_awesome_colorscheme(self)
    local old_colorscheme = self._private.colorscheme
    local new_colorscheme = self._private.colors[self._private.selected_wallpaper]
    local old_colorscheme_to_new_map = {}
    for index, color in pairs(old_colorscheme) do
        old_colorscheme_to_new_map[color] = new_colorscheme[index]
    end
    old_colorscheme_to_new_map["#FFFFFF"] = "#FFFFFF"
    old_colorscheme_to_new_map["#000000"] = "#000000"

    capi.awesome.emit_signal("colorscheme::changed", old_colorscheme_to_new_map, new_colorscheme)
    beautiful.init(helpers.filesystem.get_awesome_config_dir("ui") .. "theme.lua")
    self._private.colorscheme = new_colorscheme
    helpers.settings:set_value("theme-colorscheme", self._private.colorscheme)
end

local function on_finished_generating(self)
    if self._private.command_after_generation ~= nil then
        awful.spawn.with_shell(self._private.command_after_generation)
    end

    reload_gtk()
end

local function generate_sequences(self)
    local function set_special(index, color, alpha)
        if (index == 11 or index == 708) and alpha ~= 100 then
            return string.format("\27]%s;[%s]%s\27\\", index, alpha, color)
        end

        return string.format("\27]%s;%s\27\\", index, color)
    end

    local function set_color(index, color)
        return string.format("\27]4;%s;%s\27\\", index, color)
    end

    local colors = self._private.colors[self._private.selected_wallpaper]
    local sequences = {}

    for index, color in ipairs(colors) do
        table.insert(sequences, set_color(index - 1, color))
    end

    table.insert(sequences, set_special(10, colors[16]))
    table.insert(sequences, set_special(11, colors[1], 0))
    table.insert(sequences, set_special(12, colors[16]))
    table.insert(sequences, set_special(13, colors[16]))
    table.insert(sequences, set_special(17, colors[16]))
    table.insert(sequences, set_special(19, colors[1]))
    table.insert(sequences, set_color(232, colors[1]))
    table.insert(sequences, set_color(256, colors[16]))
    table.insert(sequences, set_color(257, colors[1]))
    table.insert(sequences, set_special(708, colors[1], 0))

    local string = table.concat(sequences)

    local file = helpers.file.new_for_path(GENERATED_TEMPLATES_PATH .. "sequences")
    file:write(string)

    -- Backwards compatibility with wal/wpgtk
    local file = helpers.file.new_for_path(WAL_CACHE_PATH .. "sequences")
    file:write(string)

    for index = 0, 9 do
        local file = helpers.file.new_for_path("/dev/pts/" .. index)
        file:write(string)
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

    helpers.filesystem.iterate_contents(BASE_TEMPLATES_PATH, function(file)
        local name = file:get_name()
        if name:match(".base") ~= nil then
            local template_path = BASE_TEMPLATES_PATH .. name
            local file = helpers.file.new_for_path(template_path)
            file:read(function(error, content)
                if error == nil then
                    local lines = {}
                    local copy_to = nil

                    if content ~= nil then
                        for line in content:gmatch("[^\r\n$]+") do
                            if line:match("{{") then
                                line = line:gsub("{{", "{")
                            end
                            if line:match("}}") then
                                line = line:gsub("}}", "}")
                            end

                            if line:match("copy_to=") then
                                copy_to = line:gsub("copy_to=", "")
                                line = ""
                            end

                            local colors = self._private.colors[self._private.selected_wallpaper]

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
                                line = line:gsub("{wallpaper}", self._private.wallpaper)
                            end

                            table.insert(lines, line)
                        end
                    end

                    -- Store the output as a string
                    local output = table.concat(lines, "\n")

                    -- Get the name of the file
                    name = name:gsub(".base", "")

                    -- Save to ~/.cache/awesome/templates
                    local file = helpers.file.new_for_path(GENERATED_TEMPLATES_PATH .. name)
                    file:write(output)

                    -- Backwards compatibility with wal/wpgtk
                    local file = helpers.file.new_for_path(WAL_CACHE_PATH .. name)
                    file:write(output)

                    -- Save to addiontal location specified in the template file
                    if copy_to ~= nil then
                        copy_to = copy_to:gsub("~", os.getenv("HOME"))
                        local file = helpers.file.new_for_path(copy_to)
                        file:write(output)
                    end
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
    awful.spawn(string.format("cp -r %s %s", GTK_THEME_PATH, INSTALLED_GTK_THEME_PATH), false)
end

local function image_wallpaper(self, screen)
    awful.wallpaper {
        screen = screen,
        widget = {
            widget = wibox.widget.imagebox,
            resize = true,
            horizontal_fit_policy = "fit",
            vertical_fit_policy = "fit",
            image = self._private.wallpaper
        }
    }
end

local function color_wallpaper(self, screen)
    awful.wallpaper {
        screen = screen,
        widget = {
            widget = wibox.container.background,
            bg = self._private.color
        }
    }
end

local function sun_wallpaper(screen)
    awful.wallpaper {
        screen = screen,
        widget = wibox.widget {
            fit = function(_, width, height)
                return width, height
            end,
            draw = function(_, _, cr, width, height)
                cr:set_source(gcolor {
                    type = 'linear',
                    from = {0, 0},
                    to = {0, height},
                    stops = {{0, beautiful.colors.background}, {0.75, beautiful.colors.surface},
                             {1, beautiful.colors.background}}
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
                    stops = {{0, beautiful.colors.random_accent_color()}, {1, beautiful.colors.random_accent_color()}}
                })
                cr:arc(width / 2, height / 2, height * .35, 0, math.pi * 2)
                cr:fill()

                -- Draw the grid
                local lines = width / 8
                cr:reset_clip()
                cr:set_line_width(0.5)
                cr:set_source(gcolor(beautiful.colors.random_accent_color()))

                for i = 1, lines do
                    cr:move_to((-width) + i * math.sin(i * (math.pi / (lines * 2))) * 30, height)
                    cr:line_to(width / 4 + i * ((width / 2) / lines), height * 0.75 + 2)
                    cr:stroke()
                end

                for i = 1, 5 do
                    cr:move_to(0, height * 0.75 + i * 10 + i * 2)
                    cr:line_to(width, height * 0.75 + i * 10 + i * 2)
                    cr:stroke()
                end
            end
        }
    }
end

local function binary_wallpaper(screen)
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

    awful.wallpaper {
        screen = screen,
        bg = beautiful.colors.background,
        fg = beautiful.colors.random_accent_color(),
        widget = wibox.widget {
            widget = wibox.layout.stack,
            {
                widget = wibox.container.background,
                fg = beautiful.colors.random_accent_color(),
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
    }
end

local function scan_for_wallpapers(self)
    self._private.images = {}

    -- Make sure Awesome doesn't work too hard adding widgets
    -- if there are more changes coming soon
    local emit_signal_timer = gtimer {
        timeout = 0.5,
        autostart = false,
        single_shot = true,
        callback = function()
            if #self._private.images == 0 then
                self:emit_signal("wallpapers::empty")
            else
                table.sort(self._private.images, function(a, b)
                    return a < b
                end)

                self:emit_signal("wallpapers", self._private.images)
                self:select_wallpaper(self:get_wallpaper())
            end
        end
    }

    helpers.filesystem.iterate_contents(WALLPAPERS_PATH, function(file)
        local wallpaper_path = WALLPAPERS_PATH .. file:get_name()
        local mimetype = Gio.content_type_guess(wallpaper_path)
        if PICTURES_MIMETYPES[mimetype] ~= nil then
            table.insert(self._private.images, wallpaper_path)
        end
    end, {}, function()
        emit_signal_timer:again()
    end)
end

local function watch_wallpaper_changes(self)
    local wallpaper_watcher = helpers.inotify:watch(WALLPAPERS_PATH,
        {helpers.inotify.Events.create, helpers.inotify.Events.delete, helpers.inotify.Events.moved_from,
         helpers.inotify.Events.moved_to})

    wallpaper_watcher:connect_signal("event", function()
        scan_for_wallpapers(self)
    end)
end

function theme:set_wallpaper(type)
    if type == "image" then
        self:save_colorscheme()
        self._private.wallpaper = self._private.selected_wallpaper
        helpers.settings:set_value("theme-wallpaper", self._private.wallpaper)

        local file = helpers.file.new_for_path(self._private.wallpaper)
        file:copy(BACKGROUND_PATH, {
            overwrite = true
        })
    elseif type == "tiled" then
    elseif type == "color" then
        self._private.color = self._private.selected_color
        helpers.settings:set_value("theme-color", self._private.color)
    elseif type == "digital_sun" then
    elseif type == "binary" then
    end

    self._private.wallpaper_type = type
    helpers.settings:set_value("theme-wallpaper-type", type)

    for s in capi.screen do
        capi.screen.emit_signal("request::wallpaper", s)
    end
end

function theme:set_colorscheme()
    reload_awesome_colorscheme(self)
    install_gtk_theme()
    generate_templates(self)
    generate_sequences(self)
end

function theme:select_wallpaper(wallpaper)
    self._private.selected_wallpaper = wallpaper
    generate_colorscheme(self, wallpaper)
end

function theme:save_colorscheme()
    local file = helpers.file.new_for_path(COLORSCHEME_DATA_PATH)
    file:write(helpers.json.encode(self._private.colors, {
        indent = true
    }))
end

function theme:reset_colorscheme()
    local bg = self._private.colors[self._private.selected_wallpaper][1]
    local light = not helpers.color.is_dark(bg)
    generate_colorscheme(self, self._private.selected_wallpaper, true, light)
end

function theme:toggle_dark_light()
    local bg = self._private.colors[self._private.selected_wallpaper][1]
    local light = helpers.color.is_dark(bg)
    generate_colorscheme(self, self._private.selected_wallpaper, true, light)
end

function theme:edit_color(index)
    local color = self._private.colors[self._private.selected_wallpaper][index]
    local cmd = string.format([[yad --title='Pick A Color'  --width=500 --height=500 --color --init-color=%s
        --mode=hex --button=Cancel:1 --button=Select:0]], color)

    awful.spawn.easy_async(cmd, function(stdout, stderr)
        stdout = stdout:gsub("%s+", "")
        if stdout ~= "" and stdout ~= nil then
            self._private.colors[self._private.selected_wallpaper][index] = stdout
            self:emit_signal("color::" .. index .. "::updated", stdout)
        end
    end)
end

function theme:set_command_after_generation(text)
    self._private.command_after_generation = text
    helpers.settings:set_value("theme-command-after-generation", self._private.command_after_generation)
end

function theme:get_colorscheme()
    return self._private.colorscheme
end

function theme:get_wallpaper()
    return self._private.wallpaper
end

function theme:get_short_wallpaper_name(wallpaper_path)
    return wallpaper_path:gsub(WALLPAPERS_PATH, "")
end

function theme:get_wallpapers()
    return self._private.images or {}
end

function theme:get_command_after_generation()
    return self._private.command_after_generation
end

function theme:get_wallpaper_index()
    for index, wallpaper in ipairs(self._private.images) do
        if wallpaper == self:get_wallpaper() then
            return index
        end
    end
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, theme, true)

    ret._private = {}

    ret._private.wallpaper = helpers.settings:get_value("theme-wallpaper"):gsub("~", os.getenv("HOME"))
    ret._private.wallpaper_type = helpers.settings:get_value("theme-wallpaper-type")
    ret._private.command_after_generation = helpers.settings:get_value("theme-command-after-generation")
    ret._private.color = helpers.settings:get_value("theme-color")

    local colorscheme_from_gsettings = helpers.settings:get_value("theme-colorscheme")
    local colorscheme = {}
    for index, color in colorscheme_from_gsettings:pairs() do
        table.insert(colorscheme, color)
    end
    ret._private.colorscheme = colorscheme

    local file = helpers.file.new_for_path(COLORSCHEME_DATA_PATH)
    file:read(function(error, content)
        ret._private.colors = ret._private.colorscheme
        if error == nil then
            ret._private.colors = helpers.json.decode(content)
        end
    end)

    ret._private.images = {}
    ret._private.selected_wallpaper = nil

    scan_for_wallpapers(ret)
    watch_wallpaper_changes(ret)

    capi.screen.connect_signal("request::wallpaper", function(s)
        if ret._private.wallpaper_type == "image" then
            image_wallpaper(ret, s)
        elseif ret._private.wallpaper_type == "tiled" then
            sun_wallpaper(s)
        elseif ret._private.wallpaper_type == "color" then
            color_wallpaper(ret, s)
        elseif ret._private.wallpaper_type == "digital_sun" then
            sun_wallpaper(s)
        elseif ret._private.wallpaper_type == "binary" then
            binary_wallpaper(s)
        end
    end)

    for s in capi.screen do
        capi.screen.emit_signal("request::wallpaper", s)
    end

    return ret
end

if not instance then
    instance = new()
end
return instance
