-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local unpack = unpack or table.unpack -- luacheck: globals unpack (compatibility with Lua 5.1)
local gfilesystem = require("gears.filesystem")
local gcolor = require("gears.color")
local beautiful = require("beautiful")
local theme_daemon = require("daemons.system.theme")
local helpers = require("helpers")
local filesystem = require("external.filesystem")
local layout_machi = require("external.layout-machi")
local dpi = beautiful.xresources.apply_dpi
local pairs = pairs
local math = math

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

        background = helpers.color.add_opacity(colors[1], theme_daemon:get_ui_opacity()),
        background_blur = helpers.color.add_opacity(colors[1], 0.9),
        background_no_opacity = colors[1],

        surface = helpers.color.add_opacity(colors[9], theme_daemon:get_ui_opacity()),
        surface_no_opacity = colors[9],

        error = colors[2],

        white = "#FFFFFF",
        black = "#000000",
        transparent = colors[1] .. "00",

        on_background = colors[8],
        on_background_dark = helpers.color.is_dark(colors[1]) and helpers.color.pywal_darken(colors[8], 0.4) or helpers.color.pywal_lighten(colors[8], 0.4),
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
    theme.font = theme.font_name .. 12
    theme.secondary_font_name = "Oswald Medium "
    theme.secondary_font = theme.secondary_font_name .. 12
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
        check = { icon = "" },
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
        magnifying_glass = { icon = "" }
    }

    theme.taglist_icons = {
        theme.icons.firefox, theme.icons.vscode, theme.icons.git,
        theme.icons.discord, theme.icons.spotify, theme.icons.steam,
        theme.icons.gamepad_alt, theme.icons.lights_holiday
    }

    theme.app_icons = {
        ["atom"] = theme.icons.atom,
        ["alacritty"] = theme.icons.laptop_code,
        ["artemisuiexe"] = theme.icons.lights_holiday,
        ["authydesktop"] = theme.icons.unlock,
        ["archivemanager"] = theme.icons.archeive,
        ["bitwarden"] = theme.icons.unlock,
        ["blender"] = theme.icons.cube,
        ["bluemanmanager"] = theme.icons.bluetooth.on,
        ["btop"] = theme.icons.system_monitor,
        ["bravebrowser"] = theme.icons.chrome,
        ["code"] = theme.icons.vscode,
        ["colorpicker"] = theme.icons.palette,
        ["chromium"] = theme.icons.chrome,
        ["dconfeditor"] = theme.icons.computer,
        ["discord"] = theme.icons.discord,
        ["emacs"] = theme.icons.emacs,
        ["eog"] = theme.icons.image,
        ["feh"] = theme.icons.image,
        ["filepicker"] = theme.icons.file_manager,
        ["files"] = theme.icons.file_manager,
        ["firefox"] = theme.icons.firefox,
        ["flameshot"] = theme.icons.camera_retro,
        ["folderpicker"] = theme.icons.file_manager,
        ["gimp"] = theme.icons.photo_film,
        ["gitkraken"] = theme.icons.gitkraken,
        ["gitqlient"] = theme.icons.git,
        ["gnomecalculator"] = theme.icons.calculator,
        ["gnomesystemmonitor"] = theme.icons.system_monitor,
        ["gparted"] = theme.icons.disc_drive,
        ["grandtheftautov"] = theme.icons.gamepad_alt,
        ["gwenview"] = theme.icons.image,
        ["heroic"] = theme.icons.gamepad_alt,
        ["htop"] = theme.icons.system_monitor,
        ["goverlay"] = theme.icons.gamepad_alt,
        ["jetbrainsstudio"] = theme.icons.code,
        ["keepassxc"] = theme.icons.unlock,
        ["kitty"] = theme.icons.laptop_code,
        ["kotatogramdesktop"] = theme.icons.telegram,
        ["lazygit"] = theme.icons.git,
        ["libreofficewriter"] = theme.icons.word,
        ["libreofficeimpress"] = theme.icons.powerpoint,
        ["libreofficecalc"] = theme.icons.excel,
        ["lutris"] = theme.icons.gamepad_alt,
        ["lxappearance"] = theme.icons.palette,
        ["mopidy"] = theme.icons.spotify,
        ["mpv"] = theme.icons.video,
        ["ncmpcpp"] = theme.icons.spotify,
        ["nemo"] = theme.icons.file_manager,
        ["networkmanagerdmenu"] = theme.icons.router,
        ["nmconnectioneditor"] = theme.icons.router,
        ["notepadqq"] = theme.icons.note,
        ["nvidiasettings"] = theme.icons.nvidia,
        ["nvim"] = theme.icons.vim,
        ["obs"] = theme.icons.video,
        ["openrgb"] = theme.icons.lights_holiday,
        ["eog"] = theme.icons.image,
        ["parcellite"] = theme.icons.clipboard,
        ["pavucontrol"] = theme.icons.speaker,
        ["protontricks"] = theme.icons.gamepad_alt,
        ["ranger"] = theme.icons.file_manager,
        ["screenshot"] = theme.icons.camera_retro,
        ["spotify"] = theme.icons.spotify,
        ["steam"] = theme.icons.steam,
        ["steamapp252950"] = theme.icons.gamepad_alt,
        ["thunar"] = theme.icons.file_manager,
        ["qbittorrent"] = theme.icons.download,
        ["qemusystemx8664"] = theme.icons.computer,
        ["qutebrowser"] = theme.icons.chrome,
        ["qtcreator"] = theme.icons.code,
        ["recorder"] = theme.icons.video,
        ["rockstargameslauncher"] = theme.icons.gamepad_alt,
        ["st"] = theme.icons.laptop_code,
        ["st256color"] = theme.icons.laptop_code,
        ["telegramdesktop"] = theme.icons.telegram,
        ["termite"] = theme.icons.laptop_code,
        ["thunderbird"] = theme.icons.envelope,
        ["thememanager"] = theme.icons.palette,
        ["urxvt"] = theme.icons.laptop_code,
        ["virtualboxmanager"] = theme.icons.computer,
        ["vivaldistable"] = theme.icons.chrome,
        ["vim"] = theme.icons.vim,
        ["vlc"] = theme.icons.video,
        ["wireshark"] = theme.icons.router,
        ["wpg"] = theme.icons.spraycan,
        ["webtorrent"] = theme.icons.video_download_icon,
        ["welcome"] = theme.icons.computer,
        ["xcolor"] = theme.icons.palette,
        ["xfce4settingsmanager"] = theme.icons.computer,
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
end

local function assets()
    local assets_folder = filesystem.filesystem.get_awesome_config_dir("assets/images")
    theme.mountain_background = assets_folder .. "mountain.png"
    theme.overview = assets_folder .. "overview.png"

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
    theme.tabbar_font = theme.font_name .. 11 -- font of the tabbar
    theme.tabbar_size = 40 -- size of the tabbar
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

colors()
fonts()
icons()
assets()
widgets()

return theme