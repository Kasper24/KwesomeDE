-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gfs = require("gears.filesystem")
local gcolor = require("gears.color")
local beautiful = require("beautiful")
local theme_daemon = require("daemons.system.theme")
local color_libary = require("external.color")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local string = string
local math = math

local theme = {}

local function colors()
    local colors = theme_daemon:get_colorscheme()

    local function color_with_opacity(color, opacity)
        opacity = opacity or 0.9
        return color .. string.format("%x", math.floor(opacity * 255))
    end

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

        background = colors[1],
        background_with_opacity = color_with_opacity(colors[1]),
        surface = colors[9],
        error = colors[2],
        transparent = "#00000000",

        on_background = colors[8],
        on_surface = colors[8],
        on_error = colors[1],
        on_accent = helpers.color.is_dark(colors[1]) and colors[1] or colors[8]
    }
    function theme.colors.random_accent_color()
        local color_1 = color_libary.color {
            hex = theme.colors.bright_red
        }
        local color_2 = color_libary.color {
            hex = theme.colors.bright_green
        }

        local accents = {}

        if math.abs(color_1.h - color_2.h) < 50 then
            accents = {colors[10], colors[11], colors[12], colors[13], colors[14], colors[15]}
        else
            accents = {colors[13], colors[14]}
        end

        local i = math.random(1, #accents)
        return accents[i]
    end
end

local function icons()
    local themes_path = gfs.get_themes_dir()
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
    beautiful.theme_assets.recolor_layout(theme, theme.colors.on_background)

    local font_awesome_6_solid_font_name = "Font Awesome 6 Pro Solid "
    local font_awesome_6_brands_font_name = "Font Awesome 6 Brands "
    local nerd_font_name = "Nerd Font Mono "

    theme.icons = {
        thermometer = {
            quarter = {
                icon = "︁",
                font = font_awesome_6_solid_font_name,
                size = 30
            },
            half = {
                icon = "",
                font = font_awesome_6_solid_font_name,
                size = 30
            },
            three_quarter = {
                icon = "︁",
                font = font_awesome_6_solid_font_name,
                size = 30
            },
            full = {
                icon = "︁",
                font = font_awesome_6_solid_font_name,
                size = 30
            }
        },
        network = {
            wifi_off = {
                icon = "",
                font = font_awesome_6_solid_font_name
            },
            wifi_low = {
                icon = "",
                font = font_awesome_6_solid_font_name
            },
            wifi_medium = {
                icon = "",
                font = font_awesome_6_solid_font_name
            },
            wifi_high = {
                icon = "",
                font = font_awesome_6_solid_font_name
            },
            wired_off = {
                icon = "",
                font = font_awesome_6_solid_font_name
            },
            wired = {
                icon = "",
                font = font_awesome_6_solid_font_name
            }
        },
        bluetooth = {
            on = {
                icon = "",
                font = nerd_font_name
            },
            off = {
                icon = "",
                font = nerd_font_name
            }
        },
        battery = {
            bolt = {
                icon = "",
                font = font_awesome_6_solid_font_name
            },
            quarter = {
                icon = "",
                font = font_awesome_6_solid_font_name
            },
            half = {
                icon = "",
                font = font_awesome_6_solid_font_name
            },
            three_quarter = {
                icon = "",
                font = font_awesome_6_solid_font_name
            },
            full = {
                icon = "",
                font = font_awesome_6_solid_font_name
            }
        },
        volume = {
            off = {
                icon = "",
                font = font_awesome_6_solid_font_name
            },
            low = {
                icon = "",
                font = font_awesome_6_solid_font_name
            },
            normal = {
                icon = "",
                font = font_awesome_6_solid_font_name
            },
            high = {
                icon = "",
                font = font_awesome_6_solid_font_name
            }
        },
        bluelight = {
            on = {
                icon = "",
                font = font_awesome_6_solid_font_name
            },
            off = {
                icon = "",
                font = font_awesome_6_solid_font_name
            }
        },
        chevron_circle = {
            left = {
                icon = "︁",
                font = font_awesome_6_solid_font_name
            },
            right = {
                icon = "︁",
                font = font_awesome_6_solid_font_name
            }
        },
        airplane = {
            on = {
                icon = "",
                font = font_awesome_6_solid_font_name
            },
            off = {
                icon = "",
                font = font_awesome_6_solid_font_name
            }
        },
        microphone = {
            on = {
                icon = "",
                font = font_awesome_6_solid_font_name
            },
            off = {
                icon = "",
                font = font_awesome_6_solid_font_name
            }
        },
        lightbulb = {
            on = {
                icon = "",
                font = font_awesome_6_solid_font_name
            },
            off = {
                icon = "",
                font = font_awesome_6_solid_font_name
            }
        },
        toggle = {
            on = {
                icon = "",
                font = font_awesome_6_solid_font_name
            },
            off = {
                icon = "",
                font = font_awesome_6_solid_font_name
            }
        },
        circle = {
            plus = {
                icon = "",
                font = font_awesome_6_solid_font_name
            },
            minus = {
                icon = "",
                font = font_awesome_6_solid_font_name
            }
        },
        caret = {
            left = {
                icon = "",
                font = font_awesome_6_solid_font_name
            },
            right = {
                icon = "",
                font = font_awesome_6_solid_font_name
            }
        },
        chevron = {
            up = {
                icon = "",
                font = font_awesome_6_solid_font_name
            },
            down = {
                icon = "",
                font = font_awesome_6_solid_font_name
            },
            right = {
                icon = "",
                font = font_awesome_6_solid_font_name
            }
        },
        window = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        file_manager = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        terminal = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        firefox = {
            icon = "︁",
            font = font_awesome_6_brands_font_name
        },
        chrome = {
            icon = "",
            font = font_awesome_6_brands_font_name
        },
        code = {
            icon = "",
            font = font_awesome_6_solid_font_name,
            size = 25
        },
        git = {
            icon = "",
            font = font_awesome_6_brands_font_name
        },
        gitkraken = {
            icon = "︁",
            font = font_awesome_6_brands_font_name
        },
        discord = {
            icon = "︁",
            font = font_awesome_6_brands_font_name
        },
        telegram = {
            icon = "︁",
            font = font_awesome_6_brands_font_name
        },
        spotify = {
            icon = "",
            font = font_awesome_6_brands_font_name
        },
        steam = {
            icon = "︁",
            font = font_awesome_6_brands_font_name
        },
        vscode = {
            icon = "﬏",
            font = "JetBrainsMono Nerd Font 40",
            size = 40
        },
        github = {
            icon = "",
            font = font_awesome_6_brands_font_name
        },
        gitlab = {
            icon = "",
            font = font_awesome_6_brands_font_name
        },
        youtube = {
            icon = "",
            font = font_awesome_6_brands_font_name
        },
        nvidia = {
            icon = "︁",
            font = font_awesome_6_solid_font_name
        },
        system_monitor = {
            icon = "︁",
            font = font_awesome_6_solid_font_name
        },
        calculator = {
            icon = "🖩︁",
            font = font_awesome_6_solid_font_name
        },

        play = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        pause = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        forward = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        backward = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        _repeat = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        shuffle = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },

        sun = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        cloud_sun = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        sun_cloud = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        cloud_sun_rain = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        cloud_bolt_sun = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        cloud = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        raindrops = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        snowflake = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        cloud_fog = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        moon = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        cloud_moon = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        moon_cloud = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        cloud_moon_rain = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        cloud_bolt_moon = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },

        poweroff = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        reboot = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        suspend = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        exit = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        lock = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },

        triangle = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        circle = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        square = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },

        code_pull_request = {
            icon = "︁",
            font = font_awesome_6_solid_font_name
        },
        commit = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        star = {
            icon = "︁",
            font = font_awesome_6_solid_font_name
        },
        code_branch = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },

        gamepad_alt = {
            icon = "",
            font = font_awesome_6_solid_font_name,
            size = 20
        },
        lights_holiday = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        download = {
            icon = "︁",
            font = font_awesome_6_solid_font_name
        },
        computer = {
            icon = "︁",
            font = font_awesome_6_solid_font_name
        },
        video_download = {
            icon = "︁",
            font = font_awesome_6_solid_font_name
        },
        speaker = {
            icon = "︁",
            font = font_awesome_6_solid_font_name
        },
        archeive = {
            icon = "︁",
            font = font_awesome_6_solid_font_name
        },
        unlock = {
            icon = "︁",
            font = font_awesome_6_solid_font_name
        },
        spraycan = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        note = {
            icon = "︁",
            font = font_awesome_6_solid_font_name
        },
        image = {
            icon = "︁",
            font = font_awesome_6_solid_font_name
        },
        envelope = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        word = {
            icon = "︁",
            font = font_awesome_6_solid_font_name
        },
        powerpoint = {
            icon = "︁",
            font = font_awesome_6_solid_font_name
        },
        excel = {
            icon = "︁",
            font = font_awesome_6_solid_font_name
        },
        camera_retro = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        keyboard = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        brightness = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        circle_exclamation = {
            icon = "︁",
            font = font_awesome_6_solid_font_name
        },
        bell = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        router = {
            icon = "︁",
            font = font_awesome_6_solid_font_name
        },
        message = {
            icon = "︁",
            font = font_awesome_6_solid_font_name
        },
        xmark = {
            icon = "",
            font = nerd_font_name
        },
        microchip = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        memory = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        disc_drive = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        gear = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        check = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        user = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        scissors = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        clock = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        box = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        left = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        video = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        industry = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        calendar = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        hammer = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        folder_open = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        launcher = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        check = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        trash = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        list_music = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        arrow_rotate_right = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        table_layout = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        tag = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        xmark_fw = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        clouds = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        circle_check = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        laptop_code = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        location_dot = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        server = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        usb = {
            icon = "",
            font = font_awesome_6_brands_font_name
        },
        usb_drive = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        signal_stream = {
            icon = "",
            font = font_awesome_6_solid_font_name
        },
        car_battery = {
            icon = "",
            font = font_awesome_6_solid_font_name
        }
    }

    for _, icon in pairs(theme.icons) do
        local color = theme.colors.random_accent_color()
        if icon.icon == nil then
            for _, _icon in pairs(icon) do
                _icon.color = color
            end
        else
            icon.color = color
        end
    end

    theme.app_to_font_icon_lookup = {
        ["kitty"] = theme.icons.laptop_code,
        ["alacritty"] = theme.icons.laptop_code,
        ["termite"] = theme.icons.laptop_code,
        ["urxvt"] = theme.icons.laptop_code,
        ["st"] = theme.icons.laptop_code,
        ["st256color"] = theme.icons.laptop_code,
        ["htop"] = theme.icons.system_monitor,
        ["nmconnectioneditor"] = theme.icons.router,
        ["network_manager_dmenu"] = theme.icons.router,
        ["pavucontrol"] = theme.icons.speaker,
        ["bluemanmanager"] = theme.icons.bluetooth.on,
        ["fileroller"] = theme.icons.archeive,
        ["lxappearance"] = theme.icons.spraycan,
        ["nvidiasettings"] = theme.icons.nvidia,
        ["wpg"] = theme.icons.spraycan,
        ["feh"] = theme.icons.image,
        ["eog"] = theme.icons.image,
        ["gwenview"] = theme.icons.image,
        ["flameshot"] = theme.icons.camera_retro,
        ["gnomecalculator"] = theme.icons.calculator,
        ["gnomesystemmonitor"] = theme.icons.system_monitor,
        ["notepadqq"] = theme.icons.note,
        ["ranger"] = theme.icons.file_manager,
        ["nemo"] = theme.icons.file_manager,
        ["thunar"] = theme.icons.file_manager,
        ["files"] = theme.icons.file_manager,
        ["firefox"] = theme.icons.firefox,
        ["vivaldistable"] = theme.icons.chrome,
        ["chromium"] = theme.icons.chrome,
        ["emacs"] = theme.icons.code,
        ["vim"] = theme.icons.code,
        ["code"] = theme.icons.vscode,
        ["jetbrainsstudio"] = theme.icons.code,
        ["qtcreator"] = theme.icons.code,
        ["lazygit"] = theme.icons.git,
        ["gitqlient"] = theme.icons.git,
        ["gitkraken"] = theme.icons.gitkraken,
        ["discord"] = theme.icons.discord,
        ["kotatogramdesktop"] = theme.icons.telegram,
        ["telegramdesktop"] = theme.icons.telegram,
        ["spotify"] = theme.icons.spotify,
        ["mopidy"] = theme.icons.spotify,
        ["ncmpcpp"] = theme.icons.spotify,
        ["steam"] = theme.icons.steam,
        ["lutris"] = theme.icons.gamepad_alt,
        ["heroic"] = theme.icons.gamepad_alt,
        ["rockstarGamesLauncher"] = theme.icons.gamepad_alt,
        ["steamapp252950"] = theme.icons.gamepad_alt,
        ["grand Theft Auto V"] = theme.icons.gamepad_alt,
        ["openrgb"] = theme.icons.lights_holiday,
        ["artemisuiexe"] = theme.icons.lights_holiday,
        ["qbittorrent"] = theme.icons.download,
        ["webtorrent"] = theme.icons.video_download_icon,
        ["virtualBoxmanager"] = theme.icons.computer,
        ["qemusystemx8664"] = theme.icons.computer,
        ["thunderbird"] = theme.icons.envelope,
        ["bitwarden"] = theme.icons.unlock,
        ["keePassXC"] = theme.icons.unlock,
        ["libreofficewriter"] = theme.icons.word,
        ["libreofficeimpress"] = theme.icons.powerpoint,
        ["libreofficecalc"] = theme.icons.excel,
        ["awesomeappscreenshot"] = theme.icons.camera_retro,
        ["awesomeapprecord"] = theme.icons.video,
        ["awesomeappthememanager"] = theme.icons.spraycan,
        ["xfce4settingsmanager"] = theme.icons.gear,
        ["dconfeditor"] = theme.icons.gear
    }

    function theme.get_font_icon_for_app_name(name)
        if name then
            name = name:lower()
            name = name:gsub("_", "")
            name = name:gsub("%s+", "")
            name = name:gsub("-", "")
            name = name:gsub("%.", "")
        else
            return theme.icons.window
        end

        return theme.app_to_font_icon_lookup[name] or theme.icons.window
    end
end

local function assets()
    local assets_folder = helpers.filesystem.get_awesome_config_dir("ui/assets")

    theme.profile_icon = assets_folder .. "profile.png"
    theme.overview_pictures = {assets_folder .. "overview/1.png", assets_folder .. "overview/2.png",
                               assets_folder .. "overview/3.png", assets_folder .. "overview/4.png",
                               assets_folder .. "overview/5.png", assets_folder .. "overview/6.png",
                               assets_folder .. "overview/7.png", assets_folder .. "overview/8.png",
                               assets_folder .. "overview/9.png"}
end

local function defaults()
    theme.hover_cursor = "hand2"
    theme.useless_gap = helpers.settings:get_value("useless-gap")
    theme.font_name = "Iosevka "
    theme.font = theme.font_name .. 12
    theme.secondary_font_name = "Oswald Medium "
    theme.secondary_font = theme.secondary_font_name .. 12
    theme.bg_normal = theme.colors.background
    theme.bg_focus = theme.colors.random_accent_color()
    theme.bg_urgent = theme.colors.background
    theme.bg_minimize = theme.colors.background
    theme.fg_normal = theme.colors.on_background
    theme.fg_focus = theme.colors.background
    theme.fg_urgent = nil
    theme.fg_minimize = nil
    theme.border_width = nil
    theme.border_color = theme.colors.surface
    theme.border_radius = 5
    theme.border_color_active = theme.colors.random_accent_color()
    theme.border_color_normal = theme.colors.surface
    theme.border_color_urgent = nil
    theme.border_color_new = theme.border_color_normal
    theme.border_color_floating_active = theme.colors.random_accent_color()
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
    theme.opacity_normal = nil
    theme.opacity_active = nil
    theme.opacity_urgent = nil
    theme.opacity_new = nil
    theme.opacity_floating_normal = nil
    theme.opacity_floating_active = nil
    theme.opacity_floating_urgent = nil
    theme.opacity_floating_new = nil
    theme.opacity_maximized_normal = nil
    theme.opacity_maximized_active = nil
    theme.opacity_maximized_urgent = nil
    theme.opacity_maximized_new = nil
    theme.opacity_fullscreen_normal = nil
    theme.opacity_fullscreen_active = nil
    theme.opacity_fullscreen_urgent = nil
    theme.opacity_fullscreen_new = nil
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
end

local function machi()
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

    theme.layout_machi = gcolor.recolor_image(require("external.layout-machi").get_icon(), theme.colors.on_background)
end

colors()
icons()
assets()
defaults()
opacity()
notification()
systray()
tabbed()
machi()

return theme
