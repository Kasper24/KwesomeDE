-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
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
local tonumber = tonumber
local string = string
local ipairs = ipairs
local pairs = pairs
local table = table
local os = os
local capi = {
    awesome = awesome,
    root = root,
    screen = screen,
    client = client
}

local theme = {}
local instance = nil

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
    if self:get_colorschemes()[wallpaper] ~= nil and reset ~= true then
        self:emit_signal("colorscheme::generated", self:get_colorschemes()[wallpaper])
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

            self:get_colorschemes()[wallpaper] = colors
            self:save_colorscheme()
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

local function reload_awesome_colorscheme()
    local old_colorscheme = beautiful.colors
    beautiful.init(helpers.filesystem.get_awesome_config_dir("ui") .. "theme.lua")
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

    local file = helpers.file.new_for_path(GENERATED_TEMPLATES_PATH .. "sequences")
    file:write(string)

    -- Backwards compatibility with wal/wpgtk
    local file = helpers.file.new_for_path(WAL_CACHE_PATH .. "sequences")
    file:write(string)

    for index = 0, 9 do
        local file = helpers.file.new_for_path("/dev/pts/" .. index)
        file:write_root(sequences)
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
                    local copy_to = {}

                    if content ~= nil then
                        for line in content:gmatch("[^\r\n$]+") do
                            if line:match("{{") then
                                line = line:gsub("{{", "{")
                            end
                            if line:match("}}") then
                                line = line:gsub("}}", "}")
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
                    for _, path in ipairs(copy_to) do
                        path = path:gsub("~", os.getenv("HOME"))
                        local file = helpers.file.new_for_path(path)
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

local function scan_wallpapers(self)
    self._private.wallpapers = {}

    -- Make sure Awesome doesn't work too hard adding widgets
    -- if there are more changes coming soon
    local emit_signal_timer = gtimer {
        timeout = 0.5,
        autostart = false,
        single_shot = true,
        callback = function()
            if #self._private.wallpapers == 0 then
                self:emit_signal("wallpapers::empty")
            else
                table.sort(self._private.wallpapers, function(a, b)
                    return a < b
                end)

                self:set_selected_colorscheme(self:get_selected_colorscheme())
                self:emit_signal("wallpapers", self._private.wallpapers)
            end
        end
    }

    helpers.filesystem.iterate_contents(WALLPAPERS_PATH, function(file)
        local wallpaper_path = WALLPAPERS_PATH .. file:get_name()
        local mimetype = Gio.content_type_guess(wallpaper_path)
        if PICTURES_MIMETYPES[mimetype] ~= nil then
            table.insert(self._private.wallpapers, wallpaper_path)
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
        scan_wallpapers(self)
    end)
end

--Colorschemes
function theme:save_colorscheme()
    helpers.settings:set_value("theme-colorschemes", self._private.colorschemes)
end

function theme:get_colorschemes()
    if self._private.colorschemes == nil then
        local colorscheme_from_gsettings = helpers.settings:get_direct("theme-colorschemes")
        local colorschemes = {}
        for path, colorscheme in colorscheme_from_gsettings:pairs() do
            path = path:gsub("~", os.getenv("HOME"))
            colorschemes[path] = {}
            for index, color in colorscheme:ipairs() do
                colorschemes[path][index] = color
            end
        end
        self._private.colorschemes = colorschemes
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
    local color = self:get_selected_colorscheme_colors()[index]
    local cmd = string.format([[yad --title='Pick A Color'  --width=500 --height=500 --color --init-color=%s
        --mode=hex --button=Cancel:1 --button=Select:0]], color)

    awful.spawn.easy_async(cmd, function(stdout, stderr)
        stdout = stdout:gsub("%s+", "")
        if stdout ~= "" and stdout ~= nil then
            self:get_selected_colorscheme_colors()[index] = stdout
            self:emit_signal("color::" .. index .. "::updated", stdout)
        end
    end)
end

-- Wallpaper
function theme:set_wallpaper(type)
    self._private.active_wallpaper = self:get_selected_colorscheme()
    helpers.settings:set_value("theme-active-wallpaper", self:get_selected_colorscheme())

    self._private.wallpaper_type = type
    helpers.settings:set_value("theme-wallpaper-type", type)

    -- local file = helpers.file.new_for_path(self:get_active_wallpaper())
    -- file:copy(BACKGROUND_PATH, {
    --     overwrite = true
    -- })

    self._private.wallpaper_surface = wibox.widget.draw_to_image_surface(widget, screen.geometry.width, screen.geometry.height)
    wibox.widget.draw_to_svg_file(self._private.wallpaper_surface, BACKGROUND_PATH, screen.primary.geometry.width, screen.primary.geometry.height)

    for s in capi.screen do
        capi.screen.emit_signal("_request::wallpaper", s)
    end
end

function theme:get_wallpaper_surface()
    return self._private.wallpaper_surface
end

function theme:get_wallpaper_type()
    if self._private.wallpaper_type == nil then
        self._private.wallpaper_type = helpers.settings:get_value("theme-wallpaper-type")
    end

    return self._private.wallpaper_type
end

function theme:get_active_wallpaper()
    if self._private.active_wallpaper == nil then
        self._private.active_wallpaper = helpers.settings:get_value("theme-active-wallpaper"):gsub("~", os.getenv("HOME"))
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
    helpers.settings:set_value("theme-active-colorscheme", colorscheme)

    self:save_colorscheme()

    reload_awesome_colorscheme()
    install_gtk_theme()
    generate_templates(self)
    generate_sequences(self:get_active_colorscheme_colors())
end

function theme:get_active_colorscheme()
    if self._private.active_colorscheme == nil then
        self._private.active_colorscheme = helpers.settings:get_value("theme-active-colorscheme"):gsub("~", os.getenv("HOME"))
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

-- UI dpi
function theme:set_dpi(dpi)
    self._private.dpi = dpi
    helpers.settings:set_value("theme-dpi", dpi)
end

function theme:get_dpi()
    if self._private.dpi == nil then
        self._private.dpi = tonumber(helpers.settings:get_value("theme-dpi"))
    end

    return self._private.dpi
end

-- UI opacity
function theme:set_ui_opacity(opacity)
    self._private.ui_opacity = opacity
    helpers.settings:set_value("theme-ui-opacity", opacity)
    reload_awesome_colorscheme()
end

function theme:get_ui_opacity()
    if self._private.ui_opacity == nil then
        self._private.ui_opacity = helpers.settings:get_value("theme-ui-opacity")
    end

    return self._private.ui_opacity
end

-- UI border radius
function theme:set_ui_border_radius(border_radius)
    self._private.ui_border_radius = border_radius
    helpers.settings:set_value("theme-ui-border-radius", border_radius)
    reload_awesome_colorscheme()
end

function theme:get_ui_border_radius()
    if self._private.ui_border_radius == nil then
        self._private.ui_border_radius = tonumber(helpers.settings:get_value("theme-ui-border-radius"))
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
        helpers.settings:set_value("theme-useless-gap", useless_gap)
    end
end

function theme:get_useless_gap()
    if self._private.useless_gap == nil then
        self._private.useless_gap = tonumber(helpers.settings:get_value("theme-useless-gap"))
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
        helpers.settings:set_value("theme-client-gap", client_gap)
    end
end

function theme:get_client_gap()
    if self._private.client_gap == nil then
        self._private.client_gap = tonumber(helpers.settings:get_value("theme-client-gap"))
    end

    return self._private.client_gap
end

-- UI animations
function theme:set_ui_animations(animations, save)
    helpers.animation:set_instant(not animations)

    if save ~= false then
        self._private.ui_animations = animations
        helpers.settings:set_value("theme-ui-animations", animations)
    end
end

function theme:get_ui_animations()
    if self._private.ui_animations == nil then
        self._private.ui_animations = helpers.settings:get_value("theme-ui-animations")
    end

    return self._private.ui_animations
end

-- Command after generation
function theme:set_command_after_generation(command_after_generation)
    self._private.command_after_generation = command_after_generation
    helpers.settings:set_value("theme-command-after-generation", command_after_generation)
end

function theme:get_command_after_generation()
    if self._private.command_after_generation == nil then
        self._private.command_after_generation = helpers.settings:get_value("theme-command-after-generation")
    end

    return self._private.command_after_generation
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, theme, true)

    ret._private = {}

    ret:set_client_gap(ret:get_client_gap(), false)

    scan_wallpapers(ret)
    watch_wallpaper_changes(ret)

    capi.screen.connect_signal("_request::wallpaper", function(s)
        if ret:get_wallpaper_type() == "image" then
            image_wallpaper(ret, s)
        elseif ret:get_wallpaper_type() == "mountain" then
            mountain_wallpaper(ret, s)
        elseif ret:get_wallpaper_type() == "digital_sun" then
            digital_sun_wallpaper(ret, s)
        elseif ret:get_wallpaper_type() == "binary" then
            binary_wallpaper(ret, s)
        end

        capi.awesome.emit_signal("wallpaper::changed")
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance
