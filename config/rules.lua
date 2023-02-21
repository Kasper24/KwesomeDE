-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local DesktopAppInfo = require("lgi").Gio.DesktopAppInfo
local awful = require("awful")
local gtimer = require("gears.timer")
local ruled = require("ruled")
local beautiful = require("beautiful")
local picom_daemon = require("daemons.system.picom")
local theme_daemon = require("daemons.system.theme")
local ncmpcpp_titlebar = require("ui.titlebar.ncmpcpp")
local helpers = require("helpers")
local ipairs = ipairs
local capi = {
    awesome = awesome,
    client = client
}

local apps = {
    kitty = {
        command = "kitty",
        class = "kitty"
    },
    alacritty = {
        command = "alacritty",
        class = "Alacritty"
    },
    termite = {
        command = "termite",
        class = "Termite"
    },
    urxvt = {
        command = "urxvt",
        class = "URxvt"
    },
    st = {
        command = "st",
        class = "st"
    },
    st_256color = {
        command = "st-256color",
        class = "st-256color"
    },
    htop = {
        command = "kitty --class htop htop",
        class = "htop"
    },
    nm_connection_editor = {
        command = "nm-connection-editor",
        class = "Nm-connection-editor"
    },
    network_manager_dmenu = {
        name = "network",
        command = "networkmanager_dmenu",
        class = "Rofi"
    },
    pavucontrol = {
        command = "pavucontrol",
        class = "Pavucontrol"
    },
    blueman_manager = {
        name = "bluetooth",
        command = "blueman-manager",
        class = "Blueman-manager"
    },
    file_roller = {
        command = "file-roller",
        class = "File-roller"
    },
    lxappearance = {
        command = "Lxappearance",
        class = "lxappearance"
    },
    nvidia_settings = {
        command = "nvidia-settings",
        class = "Nvidia-settings"
    },
    wpgtk = {
        command = "wpg",
        class = "Wpg"
    },
    feh = {
        command = "feh",
        class = "feh"
    },
    eye_of_gnome = {
        command = "eog",
        class = "Eog"
    },
    gwenview = {
        command = "gwenview",
        class = "gwenview"
    },
    flameshot_gui = {
        command = "flameshot gui -p ~/Pictures",
        class = "flameshot"
    },
    flameshot = {
        command = "flameshot full -c -p ~/Pictures",
        class = "flameshot"
    },
    gnome_calculator = {
        command = "gnome-calculator",
        class = "Gnome-calculator"
    },
    gnome_system_monitor = {
        name = "system-monitor",
        command = "gnome-system-monitor",
        class = "Gnome-system-monitor"
    },
    notepadqq = {
        command = "notepadqq",
        class = "Notepadqq"
    },
    ranger = {
        command = "kitty --class ranger ranger",
        class = "ranger"
    },
    nemo = {
        command = "nemo",
        class = "Nemo"
    },
    thunar = {
        class = "Thunar"
    },
    files = {
        class = "files"
    },
    firefox = {
        command = "firefox",
        class = "firefox"
    },
    vivaldi = {
        command = "vivaldi-stable",
        class = "Vivaldi-stable"
    },
    chromium = {
        class = "Chromium"
    },
    emacs = {
        class = "Emacs"
    },
    vim = {
        class = "vim"
    },
    vscode = {
        command = "code",
        class = "Code"
    },
    android_studio = {
        command = "android-studio",
        class = "jetbrains-studio"
    },
    qt_creator = {
        command = "qtcreator",
        class = "QtCreator"
    },
    lazygit = {
        command = "kitty --class gitqlient lazygit",
        class = "gitqlient"
    },
    gitkraken = {
        command = "gitkraken",
        class = "GitKraken"
    },
    discord = {
        command = "discocss",
        class = "discord"
    },
    telegram = {
        command = "kotatogram-desktop",
        class = "KotatogramDesktop"
    },
    kotatogram = {
        command = "telegram-desktop",
        class = "TelegramDesktop"
    },
    spotify = {
        command = "spotify",
        class = "Spotify"
    },
    ncmpcpp = {
        command = "kitty --class mopidy ncmpcpp",
        class = "mopidy"
    },
    steam = {
        command = "steam",
        class = "Steam"
    },
    lutris = {
        command = "lutris",
        class = "Lutris"
    },
    heroic = {
        command = "heroic",
        class = "heroic"
    },
    rockstar_games_launcer = {
        name = "Rockstar Games Launcher"
    },
    rocket_league = {
        class = "steam_app_252950"
    },
    gta_v = {
        name = "Grand Theft Auto V"
    },
    openrgb = {
        command = "openrgb",
        class = "openrgb"
    },
    artemis = {
        command = "artemis",
        class = "artemis.ui.exe"
    },
    qbittorrent = {
        command = "qbittorrent",
        class = "qBittorrent"
    },
    webtorrent = {
        class = "WebTorrent"
    },
    virtualbox = {
        command = "virtualbox",
        class = "VirtualBox Manager"
    },
    qemui = {
        class = "Qemu-system-x86_64"
    },
    thunderbird = {
        command = "thunderbird",
        class = "Thunderbird"
    },
    bitwarden = {
        command = "bitwarden",
        class = "Bitwarden"
    },
    keepassxc = {
        command = "keepassxc",
        class = "KeePassXC"
    },
    libreoffice_writer = {
        command = "libreoffice",
        class = "libreoffice-writer"
    },
    libreoffice_impress = {
        command = "libreoffice",
        class = "libreoffice-impress"
    },
    libreoffice_calc = {
        command = "libreoffice",
        class = "libreoffice-calc"
    },
    screenshot = {
        command = "",
        class = "Screenshot"
    },
    record = {
        command = "",
        class = "Record"
    },
    theme = {
        command = "",
        class = "Theme"
    },
    xfce4_settings_manager = {
        command = "xfce4-settings-manager",
        class = "Xfce4-settings-manager"
    }
}

require("awful.autofocus")

capi.client.connect_signal("request::manage", function(client)
    if not capi.awesome.startup then
        client:to_secondary_section()
    end
end)

capi.client.connect_signal("manage", function(client)
    client.desktop_app_info = helpers.client.get_desktop_app_info(client)
    client.actions = helpers.client.get_actions(client)
    -- client.icon = helpers.client.get_icon(client) -- not used
    client.font_icon = helpers.client.get_font_icon(client.class, client.name)
    client.index = helpers.client.get_client_index(client)

    capi.client.emit_signal("ui::ready", client)

    capi.client.connect_signal("tagged", function(client)
        -- Tagged gets emitted before 'manage' when launching a client
        -- so with this check this code will only run once the 'manage'
        -- signal was emitted
        if client.index then
            client.index = helpers.client.get_client_index(client)
            capi.client.emit_signal("ui::ready", client)
        end
    end)
end)

capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
    for _, client in ipairs(capi.client.get()) do
        client.font_icon = helpers.client.get_font_icon(client.class, client.name)
    end
end)

capi.client.connect_signal("property::floating", function(client)
    if client.floating and not client.fullscreen then
        client.ontop = true
    else
        client.ontop = false
    end
end)

capi.client.connect_signal("mouse::enter", function(client)
    if not client.fullscreen then
        client:activate{
            context = "mouse_enter",
            raise = false
        }
    end
end)

ruled.client.connect_signal("request::rules", function()
    -- Global
    ruled.client.append_rule {
        rule = {},
        properties = {
            focus = awful.client.focus.filter,
            raise = true,
            screen = awful.screen.focused,
            size_hints_honor = false,
            honor_workarea = true,
            honor_padding = true,
            maximized = false,
            titlebars_enabled = false,
            maximized_horizontal = false,
            maximized_vertical = false,
            placement = awful.placement.centered
        },
        callback = function(c)
            if c.floating then
                if c.transient_for == nil then
                    awful.placement.centered(c)
                else
                    awful.placement.centered(c, {
                        parent = c.transient_for
                    })
                end
                awful.placement.no_offscreen(c)
            end
        end
    }

    -- Floating clients
    ruled.client.append_rule {
        rule_any = {
            instance = {"copyq", -- Includes session name in class.
            "floating_terminal", "riotclientux.exe", "leagueclientux.exe", "Devtools" -- Firefox devtools
            },
            class = {apps.lxappearance.class, apps.nm_connection_editor.class, apps.file_roller.class,
                     apps.nvidia_settings.class, apps.blueman_manager.class},
            name = {"Event Tester", -- xev
            "MetaMask Notification"},
            role = {"pop-up", -- e.g. Google Chrome's (detached) Developer Tools.
            "AlarmWindow", "pop-up", "GtkFileChooserDialog", "conversation"},
            type = {"dialog"}
        },
        properties = {
            floating = true
        }
    }

    -- "Needy": Clients that steal focus when they are urgent
    ruled.client.append_rule {
        rule_any = {
            type = {"dialog"}
        },
        callback = function(c)
            c:connect_signal("property::urgent", function()
                if c.urgent then
                    c:jump_to()
                end
            end)
        end
    }

    -- Fixed terminal geometry for floating terminals
    ruled.client.append_rule {
        rule_any = {
            class = {"Alacritty", "Termite", "mpvtube", "kitty", "st-256color", "URxvt"}
        },
        properties = {
            width = awful.screen.focused().geometry.width * 0.45,
            height = awful.screen.focused().geometry.height * 0.5
        }
    }

    -- File chooser dialog
    ruled.client.append_rule {
        rule = {
            role = "GtkFileChooserDialog"
        }
        -- properties = { floating = true, width = awful.screen.focused().geometry.width * 0.55, height = awful.screen.focused().geometry.height * 0.65 }
    }

    -- Pavucontrol
    ruled.client.append_rule {
        rule = {
            class = apps.pavucontrol.class
        },
        properties = {
            floating = true,
            width = awful.screen.focused().geometry.width * 0.45,
            height = awful.screen.focused().geometry.height * 0.8
        }
    }

    -- System monitors
    ruled.client.append_rule {
        rule_any = {
            class = {apps.htop.class, apps.gnome_system_monitor.class}
        },
        properties = {
            floating = true,
            width = awful.screen.focused().geometry.width * 0.4,
            height = awful.screen.focused().geometry.height * 0.9
        }
    }

    -- Gnome calculator
    ruled.client.append_rule {
        rule = {
            class = apps.gnome_calculator.class
        },
        properties = {
            floating = true,
            width = awful.screen.focused().geometry.width * 0.2,
            height = awful.screen.focused().geometry.height * 0.4
        }
    }

    -- Image viewers
    ruled.client.append_rule {
        rule_any = {
            class = {apps.feh.class, apps.eye_of_gnome.class, apps.gwenview.class}
        },
        properties = {
            floating = true,
            width = awful.screen.focused().geometry.width * 0.7,
            height = awful.screen.focused().geometry.height * 0.75
        }
    }

    -- WPGTK
    ruled.client.append_rule {
        rule = {
            class = apps.wpgtk.class
        },
        properties = {
            floating = true,
            width = awful.screen.focused().geometry.width * 0.6,
            height = awful.screen.focused().geometry.height * 0.6
        }
    }

    -- Notepadqq
    ruled.client.append_rule {
        rule = {
            class = apps.notepadqq.class
        },
        properties = {
            floating = true,
            width = awful.screen.focused().geometry.width * 0.8,
            height = awful.screen.focused().geometry.height * 0.8
        }
    }

    -- Steam dialogs
    ruled.client.append_rule {
        rule = {
            class = "Steam"
        },
        except = {
            name = "Steam"
        },
        properties = {
            floating = true,
            width = awful.screen.focused().geometry.width * 0.3,
            height = awful.screen.focused().geometry.height * 0.8
        }
    }

    -- "Fix" games that minimize on focus loss.
    -- Usually this can be fixed by launching them with
    -- SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS=0 but not all games use SDL
    ruled.client.append_rule {
        rule = {
            name = apps.gta_v.name
        },
        callback = function(c)
            c:connect_signal("property::minimized", function()
                if c.minimized then
                    c.minimized = false
                end
            end)
        end
    }

    -- Rocket League opens and closes multiple windows, so setting it to full screen at the start doesn't work
    -- instead I use a delay to wait until the last window opens and only then set it to fullscreen
    -- Only raise Rocket League when urgent if I'm not in it's tag already
    -- Sometimes I'll have some app open as a scratchpad in the same tag as Rocket League
    -- so I don't want it to raise Rocket League as I can see it and there is no need
    ruled.client.append_rule {
        rule = {
            class = apps.rocket_league.class
        },
        callback = function(c)
            c:connect_signal("property::urgent", function()
                if c.urgent then
                    local tag = awful.screen.focused().tags[7]
                    if tag and tag ~= awful.screen.focused().selected_tag then
                        c:jump_to()
                    end
                end
            end)
            gtimer.start_new(15, function()
                c.fullscreen = true
                awful.spawn("bakkesmod", false)
                c:connect_signal("unmanage", function()
                    awful.spawn("pkill -f BakkesMod.exe", false)
                end)

                return false
            end)
        end
    }

    -- Start the start page server when opening firefox and close it when closing firefox
    ruled.client.append_rule {
        rule = {
            class = apps.firefox.class
        },
        callback = function(c)
            awful.spawn.with_shell(
                "bash -c \"exec -a start-page-server python -m http.server --directory /usr/share/start-page\"", false)
            c:connect_signal("unmanage", function()
                awful.spawn("pkill -f start-page-server", false)
            end)
        end
    }

    -- Hack to not close artemis to tray
    ruled.client.append_rule {
        rule = {
            class = apps.artemis.class
        },
        callback = function(c)
            -- Artemis first open a splash loading window before opening the main window
            if c.name ~= " " then
                c:connect_signal("unmanage", function()
                    awful.spawn.with_shell("pkill -f Artemis.UI.exe && pkill -f Artemis.ui.exe")
                end)
            end
        end
    }

    ruled.client.append_rule {
        rule = {
            name = "Wine System Tray"
        },
        properties = {
            minimized = true,
            hidden = true
        }
    }

    -- Focus browser when urent if current client is not full screen
    ruled.client.append_rule {
        rule_any = {
            class = {apps.vivaldi.class, apps.firefox.class}
        },
        except = {
            role = "GtkFileChooserDialog"
        },
        callback = function(c)
            if not capi.client.focus.fullscreen or not capi.client.focus then
                c:connect_signal("property::urgent", function()
                    c:jump_to()
                end)
            end
        end
    }

    ---------------------------------------------
    -- Start application on specific workspace --
    ---------------------------------------------
    -- Browsing
    ruled.client.append_rule {
        rule_any = {
            class = {apps.vivaldi.class, apps.firefox.class}
        },
        except = {
            role = "GtkFileChooserDialog"
        },
        properties = {
            tag = awful.screen.focused().tags[1],
            switch_to_tags = true
        }
    }

    -- Code
    ruled.client.append_rule {
        rule_any = {
            class = {apps.vscode.class, apps.qt_creator.class, apps.android_studio.class}
        },
        except = {
            role = "GtkFileChooserDialog"
        },
        properties = {
            tag = awful.screen.focused().tags[2],
            switch_to_tags = true
        }
    }

    -- Git client
    ruled.client.append_rule {
        rule_any = {
            class = {apps.gitkraken.class, apps.lazygit.class}
        },
        except = {
            role = "GtkFileChooserDialog"
        },
        properties = {
            tag = awful.screen.focused().tags[3],
            switch_to_tags = true
        }
    }

    -- Chat
    ruled.client.append_rule {
        rule_any = {
            class = {apps.discord.class, apps.kotatogram.class}
        },
        except = {
            role = "GtkFileChooserDialog"
        },
        properties = {
            tag = awful.screen.focused().tags[4],
            switch_to_tags = true
        }
    }

    -- Music
    ruled.client.append_rule {
        rule_any = {
            class = {apps.spotify.class, apps.ncmpcpp.class}
        },
        except = {
            role = "GtkFileChooserDialog"
        },
        properties = {
            tag = awful.screen.focused().tags[5],
            switch_to_tags = true
        }
    }

    -- Game launchers
    ruled.client.append_rule {
        rule_any = {
            class = {apps.steam.class, apps.lutris.class, apps.heroic.class},
            name = {apps.rockstar_games_launcer.name}
        },
        except = {
            role = "GtkFileChooserDialog"
        },
        properties = {
            tag = awful.screen.focused().tags[6]
        }
    }

    -- Games
    ruled.client.append_rule {
        rule_any = {
            class = {apps.rocket_league.class},
            name = {apps.gta_v.name}
        },
        except = {
            role = "GtkFileChooserDialog"
        },
        properties = {
            fullscreen = true,
            tag = awful.screen.focused().tags[7]
        },
        callback = function(c)
            -- Kill picom when a game starts
            -- Respawn picom when the game is closed
            theme_daemon:set_ui_animations(false, false)
            picom_daemon:turn_off(false)
            c:connect_signal("unmanage", function()
                if helpers.settings:get_value("theme-ui-animations") ~= false then
                    theme_daemon:set_ui_animations(true, false)
                end

                if helpers.settings:get_value("picom") ~= false then
                    picom_daemon:turn_on(false)
                end
            end)
        end
    }

    -- RGB Lighting
    ruled.client.append_rule {
        rule_any = {
            class = {apps.openrgb.class, apps.artemis.class}
        },
        except = {
            role = "GtkFileChooserDialog"
        },
        properties = {
            tag = awful.screen.focused().tags[8]
        }
    }

    ruled.client.append_rule {
        rule = {
            class = apps.ncmpcpp.class
        },
        callback = function(c)
            c.custom_titlebar = true

            ncmpcpp_titlebar.tabs_titlebar(c)
            ncmpcpp_titlebar.media_controls_titlebar(c)
        end
    }
end)
