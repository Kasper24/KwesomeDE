-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gtimer = require("gears.timer")
local ruled = require("ruled")
local beautiful = require("beautiful")
local picom_daemon = require("daemons.system.picom")
local settings = require("services.settings")
local animation = require("services.animation")
local capi = { awesome = awesome, client = client }

require("awful.autofocus")

local mutex = false
capi.client.connect_signal("mouse::move", function(c)
    if capi.client.focus ~= c then
        if not mutex then
            mutex = true
            gtimer.delayed_call(function ()
                c:activate { context = "mouse_enter", raise = false }
                mutex = false
            end)
        end
    end
end)

capi.client.connect_signal("mouse::enter", function(c)
    if not c.fullscreen then
        c:activate { context = "mouse_enter", raise = false }
    end
end)

capi.client.connect_signal("manage", function (c)
    if not capi.awesome.startup then
        c:to_secondary_section()
    end
end)

capi.client.connect_signal("property::floating", function(c)
    if c.floating and not c.fullscreen then
        c.ontop = true
    else
        c.ontop = false
    end
end)

ruled.client.connect_signal("request::rules", function()
    -- Global
    ruled.client.append_rule
    {
        rule = {},
        properties =
        {
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
    ruled.client.append_rule
    {
        rule_any =
        {
            instance =
            {
                "copyq",  -- Includes session name in class.
                "floating_terminal",
                "riotclientux.exe",
                "leagueclientux.exe",
                "Devtools", -- Firefox devtools
            },
            class =
            {
                beautiful.apps.lxappearance.class,
                beautiful.apps.nm_connection_editor.class,
                beautiful.apps.file_roller.class,
                beautiful.apps.nvidia_settings.class,
                beautiful.apps.blueman_manager.class,
                "Yad"
            },
            name =
            {
                "Event Tester",  -- xev
                "MetaMask Notification",
            },
            role =
            {
                "pop-up",  -- e.g. Google Chrome's (detached) Developer Tools.
                "AlarmWindow",
                "pop-up",
                "GtkFileChooserDialog",
                "conversation",
            },
            type =
            {
                "dialog",
            }
        },
        properties = { floating = true }
    }

    -- "Needy": Clients that steal focus when they are urgent
    ruled.client.append_rule
    {
        rule_any =
        {
            type =
            {
                "dialog",
            },
        },
        callback = function (c)
            c:connect_signal("property::urgent", function()
                if c.urgent then
                    c:jump_to()
                end
            end)
        end
    }

    -- Fixed terminal geometry for floating terminals
    ruled.client.append_rule
    {
        rule_any =
        {
            class =
            {
                "Alacritty",
                "Termite",
                "mpvtube",
                "kitty",
                "st-256color",
                "URxvt",
            },
        },
        properties = { width = awful.screen.focused().geometry.width * 0.45, height = awful.screen.focused().geometry.height * 0.5 }
    }

    -- File chooser dialog
    ruled.client.append_rule
    {
        rule = { role = "GtkFileChooserDialog" },
        properties = { floating = true, width = awful.screen.focused().geometry.width * 0.55, height = awful.screen.focused().geometry.height * 0.65 }
    }

    -- Pavucontrol
    ruled.client.append_rule
    {
        rule = { class = beautiful.apps.pavucontrol.class },
        properties = { floating = true, width = awful.screen.focused().geometry.width * 0.45, height = awful.screen.focused().geometry.height * 0.8 }
    }

    -- System monitors
    ruled.client.append_rule
    {
        rule_any = { class = { beautiful.apps.htop.class, beautiful.apps.gnome_system_monitor.class } },
        properties = { floating = true, width = awful.screen.focused().geometry.width * 0.4, height = awful.screen.focused().geometry.height * 0.9 }
    }

    -- Gnome calculator
    ruled.client.append_rule
    {
        rule = { class = beautiful.apps.gnome_calculator.class },
        properties = { floating = true, width = awful.screen.focused().geometry.width * 0.2, height = awful.screen.focused().geometry.height * 0.4 }
    }

    -- Image viewers
    ruled.client.append_rule
    {
        rule_any = { class = { beautiful.apps.feh.class, beautiful.apps.eye_of_gnome.class, beautiful.apps.gwenview.class } },
        properties = { floating = true, width = awful.screen.focused().geometry.width * 0.7, height = awful.screen.focused().geometry.height * 0.75 }
    }

    -- WPGTK
    ruled.client.append_rule
    {
        rule = { class = beautiful.apps.wpgtk.class },
        properties = { floating = true, width = awful.screen.focused().geometry.width * 0.6, height = awful.screen.focused().geometry.height * 0.6 }
    }

    -- Notepadqq
    ruled.client.append_rule
    {
        rule = { class = beautiful.apps.notepadqq.class },
        properties = { floating = true, width = awful.screen.focused().geometry.width * 0.8, height = awful.screen.focused().geometry.height * 0.8 }
    }

    -- Steam dialogs
    ruled.client.append_rule
    {
        rule = { class = "Steam" },
        except = { name = "Steam" },
        properties = { floating = true, width = awful.screen.focused().geometry.width * 0.3, height = awful.screen.focused().geometry.height * 0.8 }
    }

    -- "Fix" games that minimize on focus loss.
    -- Usually this can be fixed by launching them with
    -- SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS=0 but not all games use SDL
    ruled.client.append_rule
    {
        rule = { name = beautiful.apps.gta_v.name },
        callback = function (c)
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
    ruled.client.append_rule
    {
        rule = { class = beautiful.apps.rocket_league.class },
        callback = function (c)
            c:connect_signal("property::urgent", function()
                if c.urgent then
                    local tag = awful.screen.focused().tags[7]
                    if tag and tag ~= awful.screen.focused().selected_tag then
                        c:jump_to()
                    end
                end
            end)
            gtimer {timeout = 15, autostart = true, single_shot = true, callback = function()
                c.fullscreen = true
                awful.spawn("bakkesmod", false)
                c:connect_signal("unmanage", function() awful.spawn("pkill -f BakkesMod.exe", false) end)
            end}
        end
    }

    -- Start the start page server when opening firefox and close it when closing firefox
    ruled.client.append_rule
    {
        rule = { class = beautiful.apps.firefox.class },
        callback = function (c)
            awful.spawn.with_shell("bash -c \"exec -a start-page-server python -m http.server --directory /usr/share/start-page\"", false)
            c:connect_signal("unmanage", function()
                awful.spawn("pkill -f start-page-server", false)
            end)
        end
    }

    -- Hack to not close artemis to tray
    ruled.client.append_rule
    {
        rule = { class = beautiful.apps.artemis.class },
        callback = function (c)
            -- Artemis first open a splash loading window before opening the main window
            if c.name ~= " " then
                c:connect_signal("unmanage", function()
                        awful.spawn.with_shell("pkill -f Artemis.UI.exe && pkill -f Artemis.ui.exe")
                end)
            end
        end
    }

    ruled.client.append_rule
    {
        rule = { name = "Wine System Tray" },
        properties = { minimized = true, hidden = true }
    }

    ---------------------------------------------
    -- Start application on specific workspace --
    ---------------------------------------------
    -- Browsing
    ruled.client.append_rule
    {
        rule_any = { class = { beautiful.apps.vivaldi.class, beautiful.apps.firefox.class } },
        except = { role = "GtkFileChooserDialog" },
        properties = { tag = awful.screen.focused().tags[1], switch_to_tags = true },
    }

    -- Code
    ruled.client.append_rule
    {
        rule_any ={ class = { beautiful.apps.vscode.class, beautiful.apps.qt_creator.class, beautiful.apps.android_studio.class } },
        except = { role = "GtkFileChooserDialog" },
        properties = { tag = awful.screen.focused().tags[2], switch_to_tags = true },
    }

    -- Git client
    ruled.client.append_rule
    {
        rule_any = { class = { beautiful.apps.gitkraken.class, beautiful.apps.lazygit.class } },
        except = { role = "GtkFileChooserDialog" },
        properties = { tag = awful.screen.focused().tags[3], switch_to_tags = true  },
    }

    -- Chat
    ruled.client.append_rule
    {
        rule_any = { class = { beautiful.apps.discord.class, beautiful.apps.kotatogram.class } },
        except = { role = "GtkFileChooserDialog" },
        properties = { tag = awful.screen.focused().tags[4], switch_to_tags = true  },
    }

    -- Music
    ruled.client.append_rule
    {
        rule_any = { class = { beautiful.apps.spotify.class, beautiful.apps.ncmpcpp.class } },
        except = { role = "GtkFileChooserDialog" },
        properties = { tag = awful.screen.focused().tags[5], switch_to_tags = true  },
    }

    -- Game launchers
    ruled.client.append_rule
    {
        rule_any = { class = { beautiful.apps.steam.class, beautiful.apps.lutris.class, beautiful.apps.heroic.class }, name = { beautiful.apps.rockstar_games_launcer.name } },
        except = { role = "GtkFileChooserDialog" },
        properties = { tag = awful.screen.focused().tags[6] },
    }

    -- Games
    ruled.client.append_rule
    {
        rule_any = { class = { beautiful.apps.rocket_league.class  }, name = { beautiful.apps.gta_v.name } },
        except = { role = "GtkFileChooserDialog" },
        properties = { fullscreen = true, tag = awful.screen.focused().tags[7] },
        callback = function (c)
            -- Kill picom when a game starts
            -- Respawn picom when the game is closed
            animation:set_instant(true)
            picom_daemon:turn_off(false)
            c:connect_signal("unmanage", function()
                animation:set_instant(false)

                if settings:get_value("picom") ~= false then
                    picom_daemon:turn_on(false)
                end
            end)
        end
    }

    -- RGB Lighting
    ruled.client.append_rule
    {
        rule_any = { class = { beautiful.apps.openrgb.class, beautiful.apps.artemis.class } },
        except = { role = "GtkFileChooserDialog" },
        properties = { tag = awful.screen.focused().tags[8] },
    }

    -- Miscellaneous
    ruled.client.append_rule
    {
        rule_any = { class = { beautiful.apps.qbittorrent.class, beautiful.apps.webtorrent.class, beautiful.apps.virtualbox.class } },
        except = { role = "GtkFileChooserDialog" },
        properties = { tag = awful.screen.focused().tags[9] },
    }
end)