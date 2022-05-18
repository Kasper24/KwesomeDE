local Gio = require("lgi").Gio
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gcolor = require("gears.color")
local gtimer = require("gears.timer")
local gfilesystem = require("gears.filesystem")
local wibox = require("wibox")
local beautiful = require("beautiful")
local settings = require("services.settings")
local inotify = require("services.inotify")
local color_libary = require("modules.color")
local helpers = require("helpers")
local string = string
local table = table
local capi = { awesome = awesome, screen = screen, client = client }

local theme = { }
local instance = nil

local DATA_PATH = helpers.filesystem.get_cache_dir("colorschemes") .. "data.json"

local pictures_mimetypes =
{
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
    ["image/webp"] = "lximage", -- webp
}

local function update()
    local home = gfilesystem.get_xdg_config_home()

    -- Set lightdm glorious wallpaper
    awful.spawn("sudo cp " .. home .. "/wpg/.current /usr/share/backgrounds/gnome/wpgtk.jpg", false)

    -- Set refind wallpaper
    awful.spawn("sudo convert " .. home .. "/wpg/.current /boot/efi/EFI/refind/themes/rEFInd-sunset/background.png", false)

    -- Update applications themes
    -- Better discord doesn't like if the theme file is a link, so have to copy it each time
    --awful.spawn("cp " .. home .. "/wpg/templates/discord.theme.css " ..  .."/BetterDiscord/themes/wpgtk_discord.theme.css", false)
    awful.spawn("discocss", false)
    awful.spawn("telegram-palette-gen --wal", false)
    awful.spawn("spicetify update", false)
    awful.spawn("pywalfox update", false)
end

local function run_scripts_after_template_generation(self)
    if self._private.command_after_generation ~= nil then
        awful.spawn.with_shell(self._private.command_after_generation, false)
    end

    gtimer { timeout = 2,autostart = true,single_shot = true, callback = function()
        capi.awesome.restart()
    end }
end

local function replace_template_colors(self, line)
    for index = 0, 15 do
        local color = self._private.colors[self._private.selected_wallpaper.path][index + 1]
        color = color_libary.color { hex = color }

        if line:match("{color" .. index .. ".rgba}") then
            local string = string.format("%s, %s, %s, %s", color.r, color.g, color.b, color.a)
            return line:gsub("{color" .. index .. ".rgba}", string)
        elseif line:match("{color" .. index .. ".rgb}") then
            local string = string.format("%s, %s, %s", color.r, color.g, color.b)
            return line:gsub("{color" .. index .. ".rgb}", string)
        elseif line:match("{color" .. index .. ".octal}") then
            local string = string.format("%s, %s, %s, %s", color.r, color.g, color.b, color.a)
            return line:gsub("{color" .. index .. "%.octal}", string)
        elseif line:match("{color" .. index .. ".xrgba}") then
            local string = string.format("%s/%s/%s/%s", color.r, color.g, color.b, color.a)
            return line:gsub("{color" .. index .. ".xrgba}", string)
        elseif line:match("{color" .. index .. ".strip}") then
            local string = color.hex:gsub("#", "")
            return line:gsub("{color" .. index .. ".strip}", string)
        elseif line:match("{color" .. index .. ".red}") then
            return line:gsub("{color" .. index .. ".red}", color.r)
        elseif line:match("{color" .. index .. ".green}") then
            return line:gsub("{color" .. index .. ".green}", color.g)
        elseif line:match("{color" .. index .. ".blue}") then
            return line:gsub("{color" .. index .. ".blue}", color.b)
        elseif line:match("{color" .. index .. "}") then
            return line:gsub("{color" .. index .. "}", color.hex)
        end
    end
end

local function generate_templates(self)
    for index, template in ipairs(self._private.templates) do
        helpers.filesystem.read_file(template, function(content)
            local lines = {}
            for line in content:gmatch("[^\r\n$]+") do

                local color = replace_template_colors(self, line)
                if color ~= nil then
                    line = color
                end

                if line:match("{{") then
                    line = line:gsub("{{", "{")
                elseif line:match("}}") then
                    line = line:gsub("}}", "}")
                end

                -- if line:match("{background}") then
                --     local color = self._private.colors[self._private.selected_wallpaper.path][1]
                --     line = line:gsub("{color" .. index .. "}", color)
                -- elseif line:match("{foreground}") then
                --     local color = self._private.colors[self._private.selected_wallpaper.path][16]
                --     line = line:gsub("{color" .. index .. "}", color)
                -- elseif line:match("{cursor}") then
                --     local color = self._private.colors[self._private.selected_wallpaper.path][16]
                --     line = line:gsub("{color" .. index .. "}", color)
                -- end

                table.insert(lines, line)
            end

            local new_name = template:gsub(".base", "") .. ""
            local new_content = ""
            for _, line in ipairs(lines) do
                new_content = new_content .. line .. "\n"
            end
            helpers.filesystem.save_file(new_name, new_content, function()
                if index == #self._private.templates then
                    run_scripts_after_template_generation(self)
                end
            end)
        end)
    end
end

local function button_colorscheme_from_wallpaper(self, wallpaper, reset)
    if self._private.colors[wallpaper.path] ~= nil and reset ~= true then
        self:emit_signal("colorscheme::generated", self._private.colors[wallpaper.path])
        self:emit_signal("wallpaper::selected", wallpaper)
        return
    end

    self:emit_signal("colorscheme::generating")

    local color_count = 16

    local function imagemagick()
        local colors = {}
        local cmd = string.format("magick %s -resize 25%% -colors %d -unique-colors txt:-", wallpaper.path, color_count)
        awful.spawn.easy_async_with_shell(cmd, function(stdout)
            for line in stdout:gmatch("[^\r\n]+") do
                local hex = line:match("#(.*) s")
                if hex ~= nil then
                    hex = "#" .. string.sub (hex, 1, 6)
                    table.insert(colors, hex)
                end
            end

            if #colors < 16 then
                if color_count < 37 then
                    print("Imagemagick couldn't generate a palette.")
                    print("Trying a larger palette size " .. color_count)
                    color_count = color_count + 1
                    imagemagick()
                    return
                else
                    print("Imagemagick couldn't generate a suitable palette.")
                    self:emit_signal("colorscheme::failed_to_generate", wallpaper.path)
                    return
                end
            end

            colors[2] = colors[9]
            colors[3] = colors[10]
            colors[4] = colors[11]
            colors[5] = colors[12]
            colors[6] = colors[13]
            colors[7] = colors[14]
            colors[8] = colors[15]
            colors[9] = colors[16]

            colors[10] = colors[2]
            colors[11] = colors[3]
            colors[12] = colors[4]
            colors[13] = colors[5]
            colors[14] = colors[6]
            colors[15] = colors[7]

            if string.sub(colors[1], 2, 2) ~= "0" then
                colors[1] = helpers.color.pywal_darken(colors[1], 0.4)
            end
            colors[8] = helpers.color.pywal_blend(colors[8], "#EEEEEE")
            colors[9] = helpers.color.pywal_darken(colors[8], 0.3)
            colors[16] = colors[8]

            for index = 10, 16 do
                local color = color_libary.color { hex = colors[index - 8] }
                colors[index] = helpers.color.pywal_alter_brightness(colors[index - 8], color.l * 0.2, 0.6)
            end

            colors[9] = helpers.color.pywal_alter_brightness(colors[1], 0.098039216)
            colors[16] = helpers.color.pywal_alter_brightness(colors[8], 0.24)

            self:emit_signal("colorscheme::generated", colors)
            self:emit_signal("wallpaper::selected", wallpaper)

            self._private.colors[wallpaper.path] = colors
            helpers.filesystem.save_file(
                DATA_PATH,
                helpers.json.encode(self._private.colors, { indent = true })
            )
        end)
    end

    imagemagick()
end

local function image_wallpaper(self, screen)
    awful.wallpaper
    {
        screen = screen,
        widget =
        {
            widget = wibox.widget.imagebox,
            resize = true,
            horizontal_fit_policy = "fit",
            vertical_fit_policy = "fit",
            image = self._private.wallpaper
        }
    }
end

local function color_wallpaper(screen)
    awful.wallpaper
    {
        screen = screen,
        widget =
        {
            widget = wibox.container.background,
            bg = self._private.color
        }
    }
end

local function sun_wallpaper(screen)
    awful.wallpaper
    {
        screen = screen,
        widget = wibox.widget
        {
            fit = function(_, width, height)
                return width, height
            end,
            draw = function(_, _, cr, width, height)
                cr:set_source(gcolor {
                    type  = 'linear',
                    from  = { 0, 0      },
                    to    = { 0, height },
                    stops = {
                        { 0   , beautiful.colors.background },
                        { 0.75, beautiful.colors.surface },
                        { 1   , beautiful.colors.background }
                    }
                })
                cr:paint()
                -- Clip the first 33% of the screen
                cr:rectangle(0,0, width, height/3)

                -- Clip-out some increasingly large sections of add the sun "bars"
                for i=0, 6 do
                    cr:rectangle(0, height*.28 + i*(height*.055 + i/2), width, height*.055)
                end
                cr:clip()

             -- Draw the sun
                cr:set_source(gcolor {
                    type  = 'linear' ,
                    from  = { 0, 0      },
                    to    = { 0, height },
                    stops = {
                        { 0, beautiful.random_accent_color() },
                        { 1, beautiful.random_accent_color() }
                    }
                })
                cr:arc(width/2, height/2, height*.35, 0, math.pi*2)
                cr:fill()

                -- Draw the grid
                local lines = width/8
                cr:reset_clip()
                cr:set_line_width(0.5)
                cr:set_source(gcolor(beautiful.random_accent_color()))

                for i=1, lines do
                    cr:move_to((-width) + i* math.sin(i * (math.pi/(lines*2)))*30, height)
                    cr:line_to(width/4 + i*((width/2)/lines), height*0.75 + 2)
                    cr:stroke()
                end

                for i=1, 5 do
                    cr:move_to(0, height*0.75 + i*10 + i*2)
                    cr:line_to(width, height*0.75 + i*10 + i*2)
                    cr:stroke()
                end
            end
        }
    }
end

local function binary_wallpaper(screen)
    local function binary()
        local ret = {}
        for _= 1, 15 do
            for _= 1, 57 do
                table.insert(ret, math.random() > 0.5 and 1 or 0)
            end
            table.insert(ret, "\n")
        end

        return table.concat(ret)
    end

    awful.wallpaper
    {
        screen = screen,
        bg = beautiful.colors.background,
        fg = beautiful.random_accent_color(),
        widget = wibox.widget
        {
            widget = wibox.layout.stack,
            {
                widget = wibox.container.background,
                fg = beautiful.random_accent_color(),
                {
                    widget = wibox.widget.textbox,
                    align  = "center",
                    valign = "center",
                    markup = "<tt><b>[SYSTEM FAILURE]</b></tt>",
                },
            },
            {
                widget = wibox.widget.textbox,
                wrap = "word",
                text = binary(),
            },
        },
    }
end

local function scan_for_wallpapers(self)
    if #self._private.wallpapers_paths == 0 then
        self:emit_signal("wallpapers::empty")
        return
    end

    self._private.images = {}

    local emit_signal_timer = gtimer
    {
        timeout = 1,
        autostart = false,
        single_shot = true,
        callback = function()
            table.sort(self._private.images, function(a, b)
                return a.path < b.path
            end)
            self:emit_signal("wallpapers", self._private.images)
        end
    }

    for index, path in ipairs(self._private.wallpapers_paths) do
        helpers.filesystem.scan(path, function(result)
            for _index, wallpaper_path in pairs(result) do
                local found = false
                for _, image in ipairs(self._private.images) do
                    if image.path == wallpaper_path then
                        found = true
                    end
                end

                local mimetype = Gio.content_type_guess(wallpaper_path)
                if found == false and pictures_mimetypes[mimetype] ~= nil then
                    table.insert(self._private.images,
                    {
                        name = string.sub(wallpaper_path,
                                helpers.string.find_last(wallpaper_path, "/") + 1, #wallpaper_path),
                        path = wallpaper_path,
                    })
                end

                if index == #self._private.wallpapers_paths and _index == #result then
                    emit_signal_timer:again()
                end
            end
        end, true)
    end
end

local function watch_wallpaper_changes(self)
    for _, wallpaper_watcher in ipairs(self._private.wallpapers_watchers) do
        wallpaper_watcher:stop()
    end

    for _, path in ipairs(self._private.wallpapers_paths) do
        local wallpaper_watcher = inotify:watch(path,
        {
            inotify.Events.create,
            inotify.Events.delete,
            inotify.Events.moved_from,
            inotify.Events.moved_to,
        })

        wallpaper_watcher:connect_signal("event", function(_, event, path, file)
            scan_for_wallpapers(self)
        end)

        table.insert(self._private.wallpapers_watchers, wallpaper_watcher)
    end
end

function theme:set_wallpaper(type)
    if type == "image" then
        self:save_colorscheme()
        self._private.wallpaper = self._private.selected_wallpaper.path
        settings:set_value("theme.wallpaper", self._private.wallpaper)
    elseif type == "tiled" then
    elseif type == "color" then
        self._private.color = self._private.selected_color
        settings:set_value("theme.color", self._private.color)
    elseif type == "digital_sun" then
    elseif type == "binary" then
    end

    self._private.type = type
    settings:set_value("theme.wallpaper_type", type)

    for s in capi.screen do
        capi.screen.emit_signal("request::wallpaper", s)
    end
end

function theme:set_colorscheme()
    self._private.colorscheme = self._private.colors[self._private.selected_wallpaper.path]
    settings:set_value("theme.colorscheme", self._private.colorscheme)
    generate_templates(self)
end

function theme:select_wallpaper(wallpaper)
    self._private.selected_wallpaper = wallpaper
    button_colorscheme_from_wallpaper(self, wallpaper)
end

function theme:save_colorscheme()
    helpers.filesystem.save_file(
        DATA_PATH,
        helpers.json.encode(self._private.colors, { indent = true })
    )
end

function theme:reset_colorscheme()
    button_colorscheme_from_wallpaper(self, self._private.selected_wallpaper, true)
end

function theme:edit_color(index)
    local color = self._private.colors[self._private.selected_wallpaper.path][index]
    local cmd = string.format([[yad --title='Pick A Color'  --width=500 --height=500 --color --init-color=%s
        --mode=hex --button=Cancel:1 --button=Select:0]], color)

    awful.spawn.easy_async(cmd, function(stdout, stderr)
        stdout = stdout:gsub("%s+", "")
        if stdout ~= "" and stdout ~= nil then
            self._private.colors[self._private.selected_wallpaper.path][index] = stdout
            self:emit_signal("color::" .. index .. "::updated", stdout)
        end
    end)
end

function theme:add_wallpapers_path()
    awful.spawn.easy_async("yad --file --directory", function(stdout)
        for line in stdout:gmatch("[^\r\n]+") do
            if line ~= "" then
                for _, wallpapers_path in ipairs(self._private.wallpapers_paths) do
                    if wallpapers_path == line then
                        self:emit_signal("wallpapers_paths::already_exists", line)
                        return
                    end
                end

                table.insert(self._private.wallpapers_paths, line)
                settings:set_value("theme.wallpapers_paths", self._private.wallpapers_paths)
                self:emit_signal("wallpapers_paths::added", line)
                -----------
                watch_wallpaper_changes(self)
                scan_for_wallpapers(self)
            end
        end
    end)
end

function theme:remove_wallpapers_path(path)
    for index, value in ipairs(self._private.wallpapers_paths) do
        if value == path then
            table.remove(self._private.wallpapers_paths, index)
            settings:set_value("theme.wallpapers_paths", self._private.wallpapers_paths)
            self:emit_signal("wallpapers_paths::" .. path .. "::removed")
            watch_wallpaper_changes(self)
            scan_for_wallpapers(self)
            break
        end
    end
end

function theme:add_template()
    awful.spawn.easy_async("yad --file --mime-filter text/plain", function(stdout)
        for line in stdout:gmatch("[^\r\n]+") do
            if line ~= "" then
                for _, template in ipairs(self._private.templates) do
                    if template == line then
                        self:emit_signal("templates::already_exists", line)
                        return
                    end
                end

                if line:match(".base") == nil then
                    self:emit_signal("templates::not_base", line)
                    return
                end

                table.insert(self._private.templates, line)
                settings:set_value("theme.templates", self._private.templates)
                self:emit_signal("templates::added", line)
            end
        end
    end)
end

function theme:remove_template(template)
    for index, value in ipairs(self._private.templates) do
        if value == template then
            table.remove(self._private.templates, index)
            settings:set_value("theme.templates", self._private.templates)
            self:emit_signal("templates::" .. template .. "::removed")
            break
        end
    end
end

function theme:set_command_after_generation(text)
    self._private.command_after_generation = text
    settings:set_value("theme.command_after_generation", self._private.command_after_generation)
end

function theme:get_colorscheme()
    return self._private.colorscheme
end

function theme:get_wallpaper()
    return self._private.wallpaper
end

function theme:get_wallpapers()
    return self._private.images or {}
end

function theme:get_wallpapers_paths()
    return self._private.wallpapers_paths
end

function theme:get_templates()
    return self._private.templates
end

function theme:get_command_after_generation()
    return self._private.command_after_generation
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, theme, true)

    ret._private = {}
    ret._private.wallpapers_watchers = {}
    ret._private.colors = {}

    helpers.filesystem.read_file(DATA_PATH, function(content)
        if content == nil then
            return
        end

        local data = helpers.json.decode(content)
        if data == nil then
            return
        end

        ret._private.colors = data
    end)

    local default_wallpapers_paths = helpers.filesystem.get_awesome_config_dir("presentation/assets/wallpapers")
    local saved_wallpapers_paths = settings:get_value("theme.wallpapers_paths")
    if #{saved_wallpapers_paths or {}} == 0 or saved_wallpapers_paths == nil then
        ret._private.wallpapers_paths = { default_wallpapers_paths }
    else
        ret._private.wallpapers_paths = settings:get_value("theme.wallpapers_paths")
    end

    ret._private.templates = settings:get_value("theme.templates") or {}
    ret._private.wallpaper_type = settings:get_value("theme.wallpaper_type") or "wallpaper"
    ret._private.wallpaper = settings:get_value("theme.wallpaper") or
                            "/home/kasper/.config/wpg/.current"
    ret._private.colorscheme = settings:get_value("theme.colorscheme") or
    {
        "#110104",
        "#DF712D",
        "#B88836",
        "#FEB449",
        "#FCA33E",
        "#F98B35",
        "#DE9E43",
        "#F6E09C",
        "#43010D",
        "#FF8E28",
        "#FEB436",
        "#FFED49",
        "#FFD53C",
        "#FFB231",
        "#FFD044",
        "#FFFFC5"
    }
    ret._private.command_after_generation = settings:get_value("theme.command_after_generation") or nil

    ret._private.color = settings:get_value("theme.color") or "#000000"

    scan_for_wallpapers(ret)
    watch_wallpaper_changes(ret)

    capi.screen.connect_signal("request::wallpaper", function(s)
        if ret._private.wallpaper_type == "image" then
            image_wallpaper(ret, s)
        elseif ret._private.wallpaper_type == "tiled" then
            sun_wallpaper(s)
        elseif ret._private.wallpaper_type == "color" then
            color_wallpaper(s)
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
