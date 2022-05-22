local gcolor = require("gears.color")
local beautiful = require("beautiful")
local theme_daemon = require("daemons.system.theme")
local settings = require("services.settings")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local string = string
local math = math

local theme = {}

local function colors()
    local colors = theme_daemon:get_colorscheme()

    theme.colors =
    {
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

        background = colors[1],
        surface = colors[9],
        error = colors[2],
        transparent = "#00000000",

        on_background = colors[8],
        on_surface = colors[8],
        on_error = colors[1],
        on_accent = helpers.color.is_dark(colors[1]) and colors[1] or colors[8],
    }

    function theme.random_accent_color()
        local accents =
        {
            colors[2],
            colors[3],
            -- colors[4],
            colors[5],
            colors[6],
            colors[7],
            colors[10],
            colors[11],
            -- colors[12],
            colors[13],
            colors[14],
            colors[15]
        }

        local i = math.random(1, #accents)
        return accents[i]
    end
end

local function icons()
    local font_awesome_6_solid_font_name = "Font Awesome 6 Pro Solid "
    local font_awesome_6_brands_font_name = "Font Awesome 6 Brands "
    local nerd_font_name = "Nerd Font Mono "

    theme.window_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.file_manager_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.terminal_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.firefox_icon = { icon = "︁", font = font_awesome_6_brands_font_name }
    theme.chrome_icon = { icon = "", font = font_awesome_6_brands_font_name }
    theme.code_icon = { icon = "", font = font_awesome_6_solid_font_name, size = 25 }
    theme.git_icon = { icon = "", font = font_awesome_6_brands_font_name }
    theme.gitkraken_icon = { icon = "︁", font = font_awesome_6_brands_font_name }
    theme.discord_icon = { icon = "︁", font = font_awesome_6_brands_font_name }
    theme.telegram_icon = { icon = "︁", font = font_awesome_6_brands_font_name }
    theme.spotify_icon = { icon = "", font = font_awesome_6_brands_font_name }
    theme.steam_icon = { icon = "︁", font = font_awesome_6_brands_font_name }
    theme.gamepad_alt_icon = { icon = "", font = font_awesome_6_solid_font_name, size = 20 }
    theme.led_icon = { icon = "", font = font_awesome_6_brands_font_name, size = 30 }
    theme.download_icon = { icon = "︁", font = font_awesome_6_solid_font_name }
    theme.system_monitor_icon = { icon = "︁", font = font_awesome_6_solid_font_name }
    theme.calculator_icon = { icon = "🖩︁", font = font_awesome_6_solid_font_name }
    theme.computer_icon = { icon = "︁", font = font_awesome_6_solid_font_name }
    theme.video_download_icon = { icon = "︁", font = font_awesome_6_solid_font_name }
    theme.speaker_icon = { icon = "︁", font = font_awesome_6_solid_font_name }
    theme.archeive_icon = { icon = "︁", font = font_awesome_6_solid_font_name }
    theme.palette_icon = { icon = "🎨︁", font = font_awesome_6_solid_font_name }
    theme.unlock_icon = { icon = "︁", font = font_awesome_6_solid_font_name }
    theme.list_icon = { icon = "︁", font = font_awesome_6_solid_font_name }
    theme.nvidia_icon = { icon = "︁", font = font_awesome_6_solid_font_name }
    theme.spraycan_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.note_icon = { icon = "︁", font = font_awesome_6_solid_font_name }
    theme.image_icon = { icon = "︁", font = font_awesome_6_solid_font_name }
    theme.envelope_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.word_icon = { icon = "︁", font = font_awesome_6_solid_font_name }
    theme.powerpoint_icon = { icon = "︁", font = font_awesome_6_solid_font_name }
    theme.excel_icon = { icon = "︁", font = font_awesome_6_solid_font_name }
    theme.camera_retro_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.wifi_off_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.wifi_low_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.wifi_medium_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.wifi_high_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.wired_off_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.wired_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.bluetooth_icon = { icon = "", font = nerd_font_name }
    theme.bluetooth_off_icon = { icon = "", font = nerd_font_name }
    theme.battery_bolt_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.battery_quarter_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.battery_half_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.battery_three_quarter_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.battery_full_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.volume_off_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.volume_low_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.volume_normal_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.volume_high_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.keyboard_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.brightness_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.microphone_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.microphone_off_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.poweroff_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.reboot_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.suspend_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.exit_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.lock_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.mug_saucer_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.circle_exclamation_icon = { icon = "︁", font = font_awesome_6_solid_font_name }
    theme.play_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.pause_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.forward_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.backward_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.chevron_right_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.chevron_circle_left_icon = { icon = "︁", font = font_awesome_6_solid_font_name }
    theme.chevron_circle_right_icon = { icon = "︁", font = font_awesome_6_solid_font_name }
    theme.airplane_off_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.airplane_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.bluelight_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.bluelight_off_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.corona_cases_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.skull_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.lightbulb_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.lightbulb_off_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.bell_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.grid_icon = { icon = "︁", font = font_awesome_6_solid_font_name }
    theme.bars_icon = { icon = "︁", font = font_awesome_6_solid_font_name }
    theme.router_icon = { icon = "︁", font = font_awesome_6_solid_font_name }
    theme.code_pull_request_icon = { icon = "︁", font = font_awesome_6_solid_font_name }
    theme.message_icon = { icon = "︁", font = font_awesome_6_solid_font_name }
    theme.star_icon = { icon = "︁", font = font_awesome_6_solid_font_name }
    theme.code_branch_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.paint_icon = { icon = "︁", font = font_awesome_6_solid_font_name }
    theme.right_long_icon = { icon = "︁", font = font_awesome_6_solid_font_name }
    theme.pen_to_square_icon = { icon = "︁", font = font_awesome_6_solid_font_name }
    theme.triangle_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.circle_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.xmark_icon = { icon = "", font = nerd_font_name }
    theme.arch_icon = { icon = "", font = nerd_font_name }
    theme.home_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.microchip_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.memory_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.disc_drive_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.thermometer_quarter_icon = { icon = "︁", font = font_awesome_6_solid_font_name, size = 30 }
    theme.thermometer_half_icon = { icon = "", font = font_awesome_6_solid_font_name, size = 30 }
    theme.thermometer_three_quarter_icon = { icon = "︁", font = font_awesome_6_solid_font_name, size = 30 }
    theme.thermometer_full_icon = { icon = "︁", font = font_awesome_6_solid_font_name, size = 30 }
    theme.boombox_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.burn_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.gear_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.commit_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.reddit_icon = { icon = "", font = font_awesome_6_brands_font_name }
    theme.youtube_icon = { icon = "", font = font_awesome_6_brands_font_name }
    theme.amazon_icon = { icon = "", font = font_awesome_6_brands_font_name }
    theme.gitlab_icon = { icon = "", font = font_awesome_6_brands_font_name }
    theme.check_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.user_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.scissors_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.clock_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.box_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.left_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.circle_plus_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.circle_minus_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.video_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.industry_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.chart_line_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.repeat_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.shuffle_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.wrench_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.calendar_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.file_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.hammer_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.command_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.clipboard_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.folder_open_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.launcher_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.caret_left_icon  = { icon = "", font = font_awesome_6_solid_font_name }
    theme.caret_right_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.flameshot_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.check_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.bars_staggered_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.square_icon = { icon = "", font = font_awesome_6_solid_font_name}
    theme.trash_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.list_music_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.arrow_rotate_right_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.table_layout_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.tag_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.xmark_icon_fw = { icon = "", font = font_awesome_6_solid_font_name }
    theme.github_icon = { icon = "", font = font_awesome_6_brands_font_name }
    theme.clouds_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.circle_check_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.chevron_up_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.chevron_down_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.laptop_code_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.location_dot_icon = { icon = "", font = font_awesome_6_solid_font_name}
    theme.server_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.toggle_on_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.toggle_off_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.usb_icon = { icon = "", font = font_awesome_6_brands_font_name }
    theme.usb_drive_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.signal_stream_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.car_battery_icon =  { icon = "", font = font_awesome_6_solid_font_name }

    theme.sun_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.cloud_sun_icon = { icon = "", font = font_awesome_6_solid_font_name}
    theme.sun_cloud_icon = { icon = "", font = font_awesome_6_solid_font_name}
    theme.cloud_sun_rain_icon = { icon = "", font = font_awesome_6_solid_font_name}
    theme.cloud_bolt_sun_icon = { icon = "", font = font_awesome_6_solid_font_name }

    theme.cloud_icon = { icon = "", font = font_awesome_6_solid_font_name}
    theme.raindrops_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.snowflake_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.cloud_fog_icon = { icon = "", font = font_awesome_6_solid_font_name }

    theme.moon_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.cloud_moon_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.moon_cloud_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.cloud_moon_rain_icon = { icon = "", font = font_awesome_6_solid_font_name }
    theme.cloud_bolt_moon_icon = { icon = "", font = font_awesome_6_solid_font_name }
end

local function assets()
    local assets_folder = helpers.filesystem.get_awesome_config_dir("presentation/assets")

    theme.profile_icon = assets_folder .. "profile.png"
    theme.overview_pictures =
    {
        assets_folder .. "1.png",
        assets_folder .. "2.png",
        assets_folder .. "3.png",
        assets_folder .. "4.png",
        assets_folder .. "5.png",
        assets_folder .. "6.png",
        assets_folder .. "7.png",
        assets_folder .. "8.png",
        assets_folder .. "9.png"
    }
end

local function apps()
    theme.apps =
    {
        kitty = { command = "kitty", class = "kitty", icon = theme.laptop_code_icon },
        alacritty = { command = "alacritty", class = "Alacritty", icon = theme.laptop_code_icon },
        termite = { command = "termite", class = "Termite", icon = theme.laptop_code_icon },
        urxvt = { command = "urxvt", class = "URxvt", icon = theme.laptop_code_icon },
        st = { command = "st", class = "st", icon = theme.laptop_code_icon },
        st_256color = { command = "st-256color", class = "st-256color", icon = theme.laptop_code_icon },
        htop = { command = "kitty --class htop htop", class = "htop", icon = theme.system_monitor_icon },
        nm_connection_editor = { command = "nm-connection-editor", class = "Nm-connection-editor", icon = theme.router_icon },
        network_manager_dmenu = { name = "network", command = "networkmanager_dmenu", class = "Rofi", icon = theme.router_icon },
        pavucontrol = { command = "pavucontrol", class = "Pavucontrol", icon = theme.speaker_icon },
        blueman_manager = { name = "bluetooth", command = "blueman-manager", class = "Blueman-manager", icon = theme.bluetooth_icon },
        file_roller = { command = "file-roller", class = "File-roller", icon = theme.archeive_icon },
        lxappearance = { command = "Lxappearance", class = "lxappearance", icon = theme.palette_icon },
        nvidia_settings = { command = "nvidia-settings", class = "Nvidia-settings", icon = theme.nvidia_icon },
        wpgtk = { command = "wpg", class = "Wpg", icon = theme.spraycan_icon },
        feh = { command = "feh", class = "feh", icon = theme.image_icon },
        eye_of_gnome = { command = "eog", class = "Eog" , icon = theme.image_icon},
        gwenview = { command = "gwenview", class = "gwenview", icon = theme.image_icon },
        flameshot_gui = { command = "flameshot gui -p ~/Pictures", class = "flameshot", icon = theme.camera_retro_icon },
        flameshot = { command = "flameshot full -c -p ~/Pictures", class = "flameshot", icon = theme.camera_retro_icon },
        gnome_calculator = { command = "gnome-calculator", class = "Gnome-calculator", icon = theme.calculator_icon },
        gnome_system_monitor = { name = "system-monitor", command = "gnome-system-monitor", class = "Gnome-system-monitor", icon = theme.system_monitor_icon },
        notepadqq = { command = "notepadqq", class = "Notepadqq", icon = theme.note_icon },
        ranger = { command = "kitty --class ranger ranger", class = "ranger", icon = theme.file_manager_icon },
        nemo = { command = "nemo", class = "Nemo", icon = theme.file_manager_icon },
        thunar = { class = "Thunar", icon = theme.file_manager_icon },
        files = { class = "files", icon = theme.file_manager_icon },
        firefox = { command = "firefox", class = "firefox", icon = theme.firefox_icon },
        vivaldi = { command = "vivaldi-stable", class = "Vivaldi-stable", icon = theme.chrome_icon },
        chromium = { class = "Chromium", icon = theme.chrome_icon },
        emacs = { class = "Emacs", icon = theme.code_icon },
        vim = { class = "vim", icon = theme.code_icon },
        vscode = { command = "code", class = "Code", icon = theme.code_icon },
        android_studio = { command = "android-studio", class = "jetbrains-studio", icon = theme.code_icon },
        qt_creator = { command = "qtcreator", class = "QtCreator", icon = theme.code_icon },
        lazygit = { command = "kitty --class gitqlient lazygit", class = "gitqlient", icon = theme.git_icon },
        gitkraken = { command = "gitkraken", class = "GitKraken", icon = theme.gitkraken_icon },
        discord = { command = "discocss", class = "discord", icon = theme.discord_icon },
        telegram = { command = "kotatogram-desktop", class = "KotatogramDesktop", icon = theme.telegram_icon },
        kotatogram = { command = "telegram-desktop", class = "TelegramDesktop", icon = theme.telegram_icon },
        spotify = { command = "spotify", class = "Spotify", icon = theme.spotify_icon },
        ncmpcpp = { command = "kitty --class mopidy ncmpcpp", class = "mopidy", icon = theme.spotify_icon },
        steam = { command = "steam", class = "Steam", icon = theme.steam_icon },
        lutris = { command = "lutris", class = "Lutris", icon = theme.gamepad_alt_icon },
        heroic = { command = "heroic", class = "heroic" , icon = theme.gamepad_alt_icon},
        rockstar_games_launcer = { name = "Rockstar Games Launcher", icon = theme.gamepad_alt_icon },
        rocket_league = { class = "steam_app_252950", icon = theme.gamepad_alt_icon },
        gta_v = { name = "Grand Theft Auto V", icon = theme.gamepad_alt_icon },
        openrgb = { command = "openrgb", class = "openrgb", icon = theme.led_icon },
        artemis = { command = "artemis", class = "artemis.ui.exe", icon = theme.led_icon },
        qbittorrent = { command = "qbittorrent", class = "qBittorrent", icon = theme.download_icon },
        webtorrent = { class = "WebTorrent", icon = theme.video_download_icon },
        virtualbox = { command = "virtualbox", class = "VirtualBox Manager", icon = theme.computer_icon },
        qemui = { class = "Qemu-system-x86_64", icon = theme.computer_icon },
        thunderbird = { command = "thunderbird", class = "Thunderbird", icon = theme.envelope_icon },
        bitwarden = { command = "bitwarden", class = "Bitwarden", icon = theme.unlock_icon },
        keepassxc = { command = "keepassxc", class = "KeePassXC", icon = theme.unlock_icon },
        libreoffice_writer = { command = "libreoffice", class = "libreoffice-writer", icon = theme.word_icon },
        libreoffice_impress = { command = "libreoffice", class = "libreoffice-impress", icon = theme.powerpoint_icon },
        libreoffice_calc = { command = "libreoffice", class = "libreoffice-calc", icon = theme.excel_icon },
        screenshot = { command = "", class = "Screenshot", icon = theme.camera_retro_icon },
        record = { command = "", class = "Record", icon = theme.video_icon },
        theme = { command = "", class = "Theme", icon = theme.spraycan_icon },
        xfce4_settings_manager = { command = "xfce4-settings-manager", class = "Xfce4-settings-manager", icon = theme.gear_icon}
    }

    function theme.get_font_icon_for_app_name(name)
        for key, value in pairs(theme.apps) do
            key = key:lower()
            name = name:lower()
            local _name = (value.name or ""):lower()
            local class = (value.class or ""):lower()
            local command = (value.command or ""):lower()

            if key:match(name) or _name:match(name) or class:match(name) or command:match(name) then
                return value.icon
            end
        end
    end
end

local function defaults()
    theme.hover_cursor = "hand2"
    theme.useless_gap = settings:get_value("useless_gap") or 0
    theme.font_name = "Iosevka "
    theme.font = theme.font_name .. 12
    theme.secondary_font_name = "Oswald Medium "
    theme.secondary_font = theme.secondary_font_name .. 12
    theme.bg_normal = theme.colors.background
    theme.bg_focus = theme.random_accent_color()
    theme.bg_urgent = theme.colors.background
    theme.bg_minimize = theme.colors.background
    theme.fg_normal = theme.colors.on_background
    theme.fg_focus = theme.colors.background
    theme.fg_urgent = nil
    theme.fg_minimize = nil
    theme.border_width = dpi(0)
    theme.border_color = theme.colors.surface
    theme.border_radius = dpi(5)
    theme.border_color_active = theme.random_accent_color()
    theme.border_color_normal = theme.colors.surface
    theme.border_color_urgent = nil
    theme.border_color_new = theme.border_color_normal
    theme.border_color_floating_active = theme.random_accent_color()
    theme.border_color_floating_normal = theme.colors.surface
    theme.border_color_floating_urgent = nil
    theme.border_color_floating_new = theme.border_color_floating_normal
    theme.border_color_maximized_active = theme.colors.transparent
    theme.border_color_maximized_normal = theme.colors.transparent
    theme.border_color_maximized_urgent = theme.colors.transparent
    theme.border_color_maximized_new = theme.colors.transparent
    theme.border_color_fullscreen_active = theme.colors.transparent
    theme.border_color_fullscreen_normal = theme.colors.transparent
    theme.border_color_fullscreen_urgent = theme.colors.transparent
    theme.border_color_fullscreen_new = theme.colors.transparent
    theme.border_width_normal = theme.border_width
    theme.border_width_active = theme.border_width
    theme.border_width_urgent = theme.border_width
    theme.border_width_new = theme.border_width
    theme.border_width_floating_normal = theme.border_width
    theme.border_width_floating_active = theme.border_width
    theme.border_width_floating_urgent = theme.border_width
    theme.border_width_floating_new = theme.border_width
    theme.border_width_maximized_normal = dpi(0)
    theme.border_width_maximized_active = dpi(0)
    theme.border_width_maximized_urgent = dpi(0)
    theme.border_width_maximized_new = dpi(0)
    theme.border_width_fullscreen_normal = dpi(0)
    theme.border_width_fullscreen_active = dpi(0)
    theme.border_width_fullscreen_urgent = dpi(0)
    theme.border_width_fullscreen_new = dpi(0)
end

local function opacity()
    theme.opacity_normal = 0.5
    theme.opacity_active = 0.9
    theme.opacity_urgent = 0.9
    theme.opacity_new = 0.9
    theme.opacity_floating_normal = 0.5
    theme.opacity_floating_active = 0.9
    theme.opacity_floating_urgent = 0.9
    theme.opacity_floating_new = 0.9
    theme.opacity_maximized_normal = nil
    theme.opacity_maximized_active = nil
    theme.opacity_maximized_urgent = nil
    theme.opacity_maximized_new = nil
    theme.opacity_fullscreen_normal = nil
    theme.opacity_fullscreen_active = nil
    theme.opacity_fullscreen_urgent = nil
    theme.opacity_fullscreen_new = nil
end

local function layoutlist()
    theme.layoutlist_fg_normal = nil
    theme.layoutlist_bg_normal = "#FFFFFF00"
    theme.layoutlist_fg_selected = nil
    theme.layoutlist_bg_selected = theme.colors.surface
    theme.layoutlist_disable_icon = false
    theme.layoutlist_disable_name = false
    theme.layoutlist_font = theme.font
    theme.layoutlist_font_selected = theme.font_name .. "Bold 16"
    theme.layoutlist_spacing = dpi(0)
    theme.layoutlist_shape = helpers.ui.rrect(beautiful.border_radius)
    theme.layoutlist_shape_border_width = 0
    theme.layoutlist_shape_border_color = 0
    theme.layoutlist_shape_selected = helpers.ui.rrect(beautiful.border_radius)
    theme.layoutlist_shape_border_width_selected = 0
    theme.layoutlist_shape_border_color_selected = 0

    beautiful.theme_assets.recolor_layout(theme, theme.colors.on_background)
end

local function notification()
    theme.notification_spacing = dpi(30)
end

local function systray()
    theme.bg_systray = theme.colors.background
    theme.systray_icon_spacing = dpi(20)
end

local function tabbed()
    theme.tabbed_spawn_in_tab = false -- whether a new client should spawn into the focused tabbing container
    theme.tabbar_ontop = true
    theme.tabbar_radius = 0 -- border radius of the tabbar
    theme.tabbar_style = "default" -- style of the tabbar ("default", "boxes" or "modern")
    theme.tabbar_font = theme.font_name .. 11 -- font of the tabbar
    theme.tabbar_size = 40 -- size of the tabbar
    theme.tabbar_position = "top" -- position of the tabbar
    theme.tabbar_bg_normal = theme.colors.background
    theme.tabbar_bg_focus = theme.random_accent_color()
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
end

local function tag_preview()
    theme.tag_preview_widget_border_radius = theme.border_radius
    theme.tag_preview_client_border_radius = theme.border_radius
    theme.tag_preview_client_opacity = 1
    theme.tag_preview_client_bg = theme.colors.background
    theme.tag_preview_client_border_color = nil
    theme.tag_preview_client_border_width = 0
    theme.tag_preview_widget_bg = theme.colors.background
    theme.tag_preview_widget_border_color = theme.border_color_active
    theme.tag_preview_widget_border_width = theme.border_width
    theme.tag_preview_widget_margin = dpi(15)
end

local function task_preview()
    theme.task_preview_widget_border_radius = theme.border_radius
    theme.task_preview_widget_bg = theme.colors.background
    theme.task_preview_widget_border_color = theme.border_color_active
    theme.task_preview_widget_border_width = theme.border_width
    theme.task_preview_widget_margin = dpi(15)
end

local function window_switcher()
    theme.window_switcher_widget_bg = theme.colors.background
    theme.window_switcher_widget_border_radius = theme.border_radius
    theme.window_switcher_widget_border_width = 0
    theme.window_switcher_name_normal_color = theme.colors.on_background
    theme.window_switcher_name_focus_color = theme.random_accent_color()
    theme.window_switcher_name_font = theme.font_name .. 13
end

local function machi()
    theme.machi_editor_border_color = theme.border_color_active
    theme.machi_editor_border_opacity = 0.75
    theme.machi_editor_active_color = helpers.color.darken(theme.colors.background, 20)
    theme.machi_editor_active_opacity = 0.5
    theme.machi_editor_open_color = theme.colors.background
    theme.machi_editor_open_opacity = 0.5

    theme.machi_switcher_border_color = theme.border_color_active
    theme.machi_switcher_border_opacity = 0.25
    theme.machi_switcher_fill_color = theme.colors.background
    theme.machi_switcher_fill_opacity = 0.5
    theme.machi_switcher_box_bg = theme.colors.background
    theme.machi_switcher_box_opacity = 0.85
    theme.machi_switcher_fill_color_hl = helpers.color.darken(theme.colors.background, 20)
    theme.machi_switcher_fill_hl_opacity = 1

    theme.layout_machi = gcolor.recolor_image(require("modules.layout-machi").get_icon(), theme.colors.on_background)
end

colors()
icons()
assets()
apps()
defaults()
opacity()
layoutlist()
notification()
systray()
tabbed()
tag_preview()
task_preview()
window_switcher()
machi()

return theme
