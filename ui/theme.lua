-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local unpack = unpack or table.unpack -- luacheck: globals unpack (compatibility with Lua 5.1)
local lgi = require("lgi")
local Gtk = lgi.require("Gtk", "3.0")
local gfilesystem = require("gears.filesystem")
local gcolor = require("gears.color")
local gsurface = require("gears.surface")
local beautiful = require("beautiful")
local theme_daemon = require("daemons.system.theme")
local ui_daemon = require("daemons.system.ui")
local helpers = require("helpers")
local filesystem = require("external.filesystem")
local layout_machi = require("external.layout-machi")
local dpi = beautiful.xresources.apply_dpi
local pairs = pairs
local math = math
local capi = {
    awesome = awesome
}

local theme = {}

local function colors()
    local colors = theme_daemon:get_active_colorscheme_colors()

    theme.colors = {
        red = colors[2],
        bright_red = colors[10],

        green = colors[3],
        bright_green = colors[11],

        yellow = colors[4],
        bright_yellow = colors[12],

        blue = colors[5],
        bright_blue = colors[13],

        magenta = colors[6],
        bright_magenta = colors[14],

        cyan = colors[7],
        bright_cyan = colors[15],

        background = helpers.color.change_opacity(colors[1], ui_daemon:get_opacity()),
        background_blur = helpers.color.change_opacity(colors[1], 0.9),
        background_no_opacity = colors[1],

        surface = helpers.color.change_opacity(colors[9], ui_daemon:get_opacity()),
        surface_no_opacity = colors[9],

        error = colors[2],

        white = "#FFFFFF",
        black = "#000000",
        transparent = colors[1] .. "00",

        on_background = colors[8],
        on_background_dark = helpers.color.darken_or_lighten(colors[1], 0.4),
        on_surface = colors[8],
        on_error = colors[1],
        on_accent = colors[1]
    }

    function theme.colors.random_accent_color(accent_colors)
        accent_colors = accent_colors or colors
        local accents = {unpack(accent_colors, 10, 15)}
        return accents[math.random(1, #accents)]
    end
end

local function fonts()
    theme.font_name = "Iosevka "
    theme.font = theme.font_name .. dpi(12)
    theme.secondary_font_name = "Oswald Medium "
    theme.secondary_font = theme.secondary_font_name .. dpi(12)
    theme.font_awesome_6_brands_font_name = "Font Awesome 6 Brands "
end

local function icons()
    theme.icons = {
        thermometer = {
            quarter = { icon = "︁", size = 30 },
            half = { icon = "", size = 30 },
            three_quarter = { icon = "︁", size = 30 },
            full = { icon = "︁", size = 30 },
        },
        network = {
            wifi_off = { icon = "" },
            wifi_low = { icon = "" },
            wifi_medium = { icon = "" },
            wifi_high = { icon = "" },
            wired_off = { icon = "" },
            wired = { icon = "" },
        },
        bluetooth = {
            on = { icon = "", font = "Nerd Font Mono " },
            off = { icon = "", font = "Nerd Font Mono " },
        },
        battery = {
            bolt = { icon = "" },
            quarter = { icon = "" },
            half = { icon = "" },
            three_quarter = { icon = "" },
            full = { icon = "" },
        },
        volume = {
            off = { icon = "" },
            low = { icon = "" },
            normal = { icon = "" },
            high = { icon = "" },
        },
        bluelight = {
            on = { icon = "" },
            off = { icon = "" },
        },
        airplane = {
            on = { icon = "" },
            off = { icon = "" },
        },
        microphone = {
            on = { icon = "" },
            off = { icon = "" },
        },
        lightbulb = {
            on = { icon = "" },
            off = { icon = "" },
        },
        toggle = {
            on = { icon = "" },
            off = { icon = "" },
        },
        circle = {
            plus = { icon = "" },
            minus = { icon = "" },
        },
        caret = {
            left  = { icon = "" },
            right = { icon = "" },
        },
        chevron = {
            down = { icon = "" },
            right = { icon = "" },
        },
        window = { icon = "" },
        file_manager = { icon = "" },
        terminal = { icon = "" },
        firefox = { icon = "︁", font = theme.font_awesome_6_brands_font_name },
        chrome = { icon = "", font = theme.font_awesome_6_brands_font_name },
        code = { icon = "", size = 25 },
        git = { icon = "", font = theme.font_awesome_6_brands_font_name },
        gitkraken = { icon = "︁", font = theme.font_awesome_6_brands_font_name },
        discord = { icon = "︁", font = theme.font_awesome_6_brands_font_name },
        telegram = { icon = "︁", font = theme.font_awesome_6_brands_font_name },
        spotify = { icon = "", font = theme.font_awesome_6_brands_font_name },
        steam = { icon = "︁", font = theme.font_awesome_6_brands_font_name },
        vscode = { icon = "﬏", size = 40 },
        github = { icon = "", font = theme.font_awesome_6_brands_font_name },
        gitlab = { icon = "", font = theme.font_awesome_6_brands_font_name },
        youtube = { icon = "", font = theme.font_awesome_6_brands_font_name },
        nvidia = { icon = "︁" },
        system_monitor = { icon = "︁" },
        calculator = { icon = "" },
        vim = { icon = "" },
        emacs = { icon = "" },

        forward = { icon = "" },
        backward = { icon = "" },
        _repeat = { icon = "" },
        shuffle = { icon = "" },

        sun = { icon = "" },
        cloud_sun = { icon = "" },
        sun_cloud = { icon = "" },
        cloud_sun_rain = { icon = "" },
        cloud_bolt_sun = { icon = "" },
        cloud = { icon = "" },
        raindrops = { icon = "" },
        snowflake = { icon = "" },
        cloud_fog = { icon = "" },
        moon = { icon = "" },
        cloud_moon = { icon = "" },
        moon_cloud = { icon = "" },
        cloud_moon_rain = { icon = "" },
        cloud_bolt_moon = { icon = "" },

        poweroff = { icon = "" },
        reboot = { icon = "" },
        suspend = { icon = "" },
        exit = { icon = "" },
        lock = { icon = "" },

        code_pull_request = { icon = "︁" },
        commit = { icon = "" },
        star = { icon = "︁" },
        code_branch = { icon = "" },

        gamepad_alt = { icon = "" },
        lights_holiday = { icon = "" },
        download = { icon = "︁" },
        video_download = { icon = "︁" },
        speaker = { icon = "︁" },
        archeive = { icon = "︁" },
        unlock = { icon = "︁" },
        spraycan = { icon = "" },
        note = { icon = "︁" },
        image = { icon = "︁" },
        envelope = { icon = "" },
        word = { icon = "︁" },
        powerpoint = { icon = "︁" },
        excel = { icon = "︁" },
        camera_retro = { icon = "" },
        keyboard = { icon = "" },
        brightness = { icon = "" },
        circle_exclamation = { icon = "︁" },
        bell = { icon = "" },
        router = { icon = "︁" },
        message = { icon = "︁" },
        xmark = { icon = "" },
        microchip = { icon = "" },
        memory = { icon = "" },
        disc_drive = { icon = "" },
        gear = { icon = "" },
        user = { icon = "" },
        scissors = { icon = "" },
        clock = { icon = "" },
        box = { icon = "" },
        left = { icon = "" },
        video = { icon = "" },
        industry = { icon = "" },
        calendar = { icon = "" },
        hammer = { icon = "" },
        folder_open = { icon = "" },
        launcher = { icon = "" },
        check = { icon = "" },
        trash = { icon = "" },
        list_music = { icon = "" },
        arrow_rotate_right = { icon = "" },
        table_layout = { icon = "" },
        tag = { icon = "" },
        xmark_fw = { icon = "" },
        clouds = { icon = "" },
        circle_check = { icon = "" },
        laptop_code = { icon = "" },
        location_dot = { icon = "" },
        server = { icon = "" },
        usb = { icon = "", font = theme.font_awesome_6_brands_font_name },
        usb_drive = { icon = "" },
        signal_stream = { icon = "" },
        car_battery =  { icon = "" },
        computer = { icon = "" },
        palette = { icon = "" },
        cube = { icon = "" },
        photo_film = { icon = "" },
        clipboard = { icon = ""},
        atom = { icon = "" },
        magnifying_glass = { icon = "" },
        file = { icon = "" },
        bolt = { icon = "" }
    }

    theme.taglist_icons = {
        "google-chrome",
        "vscode",
        "github-desktop",
        "discord",
        "spotify",
        "steam",
        "applications-games",
        "openrgb"
    }

    local function set_icon_default_props(icon, color)
        if icon.color == nil then
            icon.color = color or theme.colors.random_accent_color()
        end
        if icon.font == nil then
            icon.font = "Font Awesome 6 Pro Solid "
        end
        if icon.size == nil then
            icon.size = 20
        end
    end

    for _, icon in pairs(theme.icons) do
        if icon.icon == nil then
            local color = theme.colors.random_accent_color()
            for _, _icon in pairs(icon) do
                set_icon_default_props(_icon, color)
            end
        else
            set_icon_default_props(icon)
        end
    end

    local gtk_theme = Gtk.IconTheme.new()
    gtk_theme:set_search_path({filesystem.filesystem.get_awesome_config_dir("assets")})
    Gtk.IconTheme.set_custom_theme(gtk_theme, "candy-icons")

    function theme.get_svg_icon(names)
        local icon_info = nil
        if #names == 1 then
            icon_info = gtk_theme:lookup_icon(names[1], 48, 0)
        elseif #names > 1 then
            icon_info = gtk_theme:choose_icon(names, 48, 0);
        end

        if icon_info then
            local icon_path = icon_info:get_filename()

            if not beautiful.svg_icons[icon_path] then
                beautiful.svg_icons[icon_path] = {
                    names = names,
                    path = icon_path,
                    color = beautiful.colors.random_accent_color()
                }
            end

            return beautiful.svg_icons[icon_path]
        end

        return nil
    end

    function theme.get_app_svg_icon(names)
        table.insert(names, "application-x-ktheme")
        return theme.get_svg_icon(names)
    end

    if not theme.svg_icons then
        theme.svg_icons = {}
    end
end

local function assets()
    local assets_folder = filesystem.filesystem.get_awesome_config_dir("assets/images")
    theme.overview = gsurface(assets_folder .. "overview.png")
    theme.default_github_profile = gsurface(assets_folder .. "default_github_profile.png")
    theme.mountain_background = gsurface(assets_folder .. "mountain.png")

    local mountain_background_thumbnail_dir_path = filesystem.filesystem.get_cache_dir("thumbnails/mountain/100-70" )
    filesystem.filesystem.make_directory_with_parents(mountain_background_thumbnail_dir_path, function()
        helpers.ui.scale_image_save(assets_folder .. "mountain.png", mountain_background_thumbnail_dir_path .. "mountain", 100, 70, function(image)
            theme.mountain_background_thumbnail = image
        end)
    end)

    local themes_path = gfilesystem.get_themes_dir()
    theme.layout_fairh = themes_path.."default/layouts/fairhw.png"
    theme.layout_fairv = themes_path.."default/layouts/fairvw.png"
    theme.layout_floating  = themes_path.."default/layouts/floatingw.png"
    theme.layout_magnifier = themes_path.."default/layouts/magnifierw.png"
    theme.layout_max = themes_path.."default/layouts/maxw.png"
    theme.layout_fullscreen = themes_path.."default/layouts/fullscreenw.png"
    theme.layout_tilebottom = themes_path.."default/layouts/tilebottomw.png"
    theme.layout_tileleft   = themes_path.."default/layouts/tileleftw.png"
    theme.layout_tile = themes_path.."default/layouts/tilew.png"
    theme.layout_tiletop = themes_path.."default/layouts/tiletopw.png"
    theme.layout_spiral  = themes_path.."default/layouts/spiralw.png"
    theme.layout_dwindle = themes_path.."default/layouts/dwindlew.png"
    theme.layout_cornernw = themes_path.."default/layouts/cornernww.png"
    theme.layout_cornerne = themes_path.."default/layouts/cornernew.png"
    theme.layout_cornersw = themes_path.."default/layouts/cornersww.png"
    theme.layout_cornerse = themes_path.."default/layouts/cornersew.png"
    theme.layout_machi = gcolor.recolor_image(layout_machi.get_icon(), theme.colors.on_background)
    theme.fg_normal = theme.colors.on_background -- bling uses this to recolor their layout icons
    beautiful.theme_assets.recolor_layout(theme, theme.colors.on_background)
end

local function widgets()
    theme.bg_systray = theme.colors.transparent
    theme.systray_icon_spacing = dpi(20)
    theme.systray_max_rows = 3

    theme.tabbed_spawn_in_tab = false -- whether a new client should spawn into the focused tabbing container
    theme.tabbar_ontop = true
    theme.tabbar_radius = 0 -- border radius of the tabbar
    theme.tabbar_style = "default" -- style of the tabbar ("default", "boxes" or "modern")
    theme.tabbar_font = theme.font -- font of the tabbar
    theme.tabbar_size = dpi(40) -- size of the tabbar
    theme.tabbar_position = "top" -- position of the tabbar
    theme.tabbar_bg_normal = theme.colors.background
    theme.tabbar_bg_focus = theme.colors.random_accent_color()
    theme.tabbar_fg_normal = theme.colors.on_background
    theme.tabbar_fg_focus = theme.colors.background
    theme.tabbar_disable = false

    theme.mstab_bar_ontop = false -- whether you want to allow the bar to be ontop of clients
    theme.mstab_dont_resize_slaves = false -- whether the tabbed stack windows should be smaller than the
    theme.mstab_bar_padding = dpi(0) -- how much padding there should be between clients and your tabbar
    theme.mstab_border_radius = theme.border_radius -- border radius of the tabbar
    theme.mstab_bar_height = dpi(60) -- height of the tabbar
    theme.mstab_tabbar_position = "top" -- position of the tabbar (mstab currently does not support left,right)
    theme.mstab_tabbar_style = "default" -- style of the tabbar ("default", "boxes" or "modern")

    theme.machi_editor_border_color = theme.border_color_active
    theme.machi_editor_border_opacity = 0.75
    theme.machi_editor_active_color = theme.colors.background
    theme.machi_editor_active_opacity = 0.5
    theme.machi_editor_open_color = theme.colors.background
    theme.machi_editor_open_opacity = 0.5

    theme.machi_switcher_border_color = theme.border_color_active
    theme.machi_switcher_border_opacity = 0.25
    theme.machi_switcher_fill_color = theme.colors.background
    theme.machi_switcher_fill_opacity = 0.5
    theme.machi_switcher_box_bg = theme.colors.background
    theme.machi_switcher_box_opacity = 0.85
    theme.machi_switcher_fill_color_hl = theme.colors.background
    theme.machi_switcher_fill_hl_opacity = 1
end

function theme.reload()
    local old_colorscheme = beautiful.colors
    beautiful.init(filesystem.filesystem.get_awesome_config_dir("ui") .. "theme.lua")
    local new_colorscheme = beautiful.colors

    local old_colorscheme_to_new_map = {}
    for index, color in pairs(old_colorscheme) do
        old_colorscheme_to_new_map[color] = new_colorscheme[index]
    end
    for _, icon in pairs(theme.svg_icons) do
        icon.color = old_colorscheme_to_new_map[icon.color]
    end

    capi.awesome.emit_signal("colorscheme::changed", old_colorscheme_to_new_map)
end

colors()
fonts()
icons()
assets()
widgets()

return theme
