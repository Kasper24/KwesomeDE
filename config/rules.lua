-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gtimer = require("gears.timer")
local ruled = require("ruled")
local power_popup = require("ui.popups.power")
local lock_popup = require("ui.popups.lock")
local ncmpcpp_titlebar = require("ui.titlebar.ncmpcpp")
local picom_daemon = require("daemons.system.picom")
local theme_daemon = require("daemons.system.theme")
local helpers = require("helpers")
local capi = {
    awesome = awesome,
    screen = screen,
    client = client
}

require("awful.autofocus")

capi.client.connect_signal("request::manage", function(client)
    if not capi.awesome.startup then
        client:to_secondary_section()
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
    if not client.fullscreen and client.can_focus ~= false then
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
        }
    }

    -- Floating clients
    ruled.client.append_rule {
        rule_any = {
            instance = {
                "copyq", -- Includes session name in class.
                "floating_terminal",
                "riotclientux.exe",
                "leagueclientux.exe",
                "Devtools" -- Firefox devtools
            },
            class = {
                "lxappearance",
                "Nm-connection-editor",
                "File-roller",
                "Nvidia-settings",
                "Blueman-manager"
            },
            name = {
                "Event Tester", -- xev
                "MetaMask Notification"
            },
            role = {
                "pop-up", -- e.g. Google Chrome's (detached) Developer Tools.
                "AlarmWindow",
                "pop-up",
                "GtkFileChooserDialog",
                "conversation"
            },
            type = {"dialog"}
        },
        properties = {
            floating = true
        }
    }

    -- "Needy": Clients that steal focus when they are urgent
    ruled.client.append_rule {
        rule_any = {
            class = {"Vivaldi-stable", "firefox"},
            type = {"dialog"}
        },
        callback = function(c)
            c:connect_signal("property::urgent", function()
                -- If current focused app is fullscren (possiblly a game, don't jump)
                if capi.client.focus and capi.client.focus.fullscreen then
                    return
                end

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

    -- Pavucontrol
    ruled.client.append_rule {
        rule = {
            class = "Pavucontrol"
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
            class = {"htop", "Gnome-system-monitor"}
        },
        except = {
            type = {"dialog"}
        },
        properties = {
            floating = true,
            width = awful.screen.focused().geometry.width * 0.4,
            height = awful.screen.focused().geometry.height * 0.9
        }
    }

    -- Gnome system monitor confrim kill dialog
    ruled.client.append_rule {
        rule = {
            class = "Gnome-system-monitor",
            type = "dialog"
        },
        properties = {
            floating = true,
            width = awful.screen.focused().geometry.width * 0.2,
            height = awful.screen.focused().geometry.height * 0.2
        }
    }

    -- Calculators
    ruled.client.append_rule {
        rule_any = {
            class =  {
                "Gnome-calculator",
                "kcalc"
            }
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
            class = {"feh", "Eog", "gwenview"}
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
            class = "Wpg"
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
            class = "Notepadqq"
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
            name = "Grand Theft Auto V"
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
            class = "steam_app_252950"
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
            class = "firefox"
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
            class = "artemis.ui.exe"
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

    -- Wallpaper engine
    ruled.client.append_rule {
        rule_any = {
            class = {"linux-wallpaperengine"}
        },
        properties = {
            x = 0,
            y = 0,
            floating = true,
            below = true,
            sticky = true,
            skip_taskbar = true,
            can_tile = false,
            can_move = false,
            can_resize = false,
            is_fixed = true,
            can_focus = false,
            focusable = false,
            can_kill = false,
            fake_root = true
        }
    }

    -- Wallpaper engine preview
    ruled.client.append_rule {
        rule_any = {
            class = {"linux-wallpaperengine-preview"}
        },
        properties = {
            floating = true,
        }
    }

    ---------------------------------------------
    -- Start application on specific workspace --
    ---------------------------------------------
    -- Browsing
    ruled.client.append_rule {
        rule_any = {
            class = {
                "Vivaldi-stable",
                "firefox",
                "Chromium",
            }
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
            class = {
                "Emacs",
                "nvim",
                "lvim",
                "vim",
                "Code",
                "QtCreator",
                "jetbrains-studio"
            }
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
            class = {
                "GitKraken",
                "gitqlient"
            }
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
            class = {
                "discord",
                "TelegramDesktop",
                "KotatogramDesktop"
            }
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
            class = {
                "Spotify",
                "mopidy"
            }
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
            class = {
                "Steam",
                "Lutris",
                "heroic"
            },
            name = {
                "Rockstar Games Launcher"
            }
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
            class = {
                "steam_app_252950"
            },
            name = {
                "Grand Theft Auto V"
            }
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
                if helpers.settings["theme-ui-animations"] ~= false then
                    theme_daemon:set_ui_animations(true, false)
                end

                if helpers.settings["picom"] ~= false then
                    picom_daemon:turn_on(false)
                end
            end)
        end
    }

    -- RGB Lighting
    ruled.client.append_rule {
        rule_any = {
            class = {"openrgb", "artemis.ui.exe"}
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
            class = "mopidy"
        },
        callback = function(c)
            c.custom_titlebar = true

            ncmpcpp_titlebar.tabs_titlebar(c)
            ncmpcpp_titlebar.media_controls_titlebar(c)
        end
    }
end)

ruled.client.add_rule_source("fix_dialog", function(c, properties, callbacks)
    if c.type ~= "dialog" then
        return
    end

    if not properties.placement then
        local parent = c.transient_for
        if not parent and c.pid then
            local screen = properties.screen
                and (type(properties.screen) == "function"
                    and capi.screen[properties.screen(c, properties)]
                    or capi.screen[properties.screen])
                or nil
            if screen then
                local possible_parents = {}
                for _, cc in ipairs(screen.clients) do
                    if c ~= cc and c.pid == cc.pid then
                        table.insert(possible_parents, cc)
                    end
                end
                -- right now I take first parent, I already forgot why I create table ¯\_(ツ)_/¯
                parent = possible_parents[1]
            end
        end

        c.width = c.screen.geometry.width * 0.6
        c.height = c.screen.geometry.height * 0.8

        (awful.placement.centered + awful.placement.no_offscreen)(c, {
            parent = parent,
        })
    end

end, { "awful.spawn", "awful.rules" }, {})