-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local widgets = require("presentation.ui.widgets")
local action_panel = require("presentation.ui.panels.action")
local message_panel = require("presentation.ui.panels.message")
local info_panel = require("presentation.ui.panels.info")
local app_launcher = require("presentation.ui.popups.app_launcher")
local screenshot_popup = require("presentation.ui.apps.screenshot")
local record_popup = require("presentation.ui.apps.record")
local hotkeys_popup = require("presentation.ui.popups.hotkeys")
local power_popup = require("presentation.ui.popups.power")
local theme_popup = require("presentation.ui.apps.theme")
local beautiful = require("beautiful")
local ipairs = ipairs
local capi = { screen = screen, tag = tag }

local recent_places_daemon = require("daemons.system.recent_places")

local instance = nil

local function recent_places_sub_menu()
    local menu = widgets.menu{}

    recent_places_daemon:connect_signal("update", function(self, recent_places)
        for _, place in ipairs(recent_places) do
            menu:add(widgets.menu.button
            {
                text = place.title,
                on_press = function() awful.spawn("xdg-open " .. place.path, false) end
            })
        end
    end)

    return menu
end

local function commands_sub_menu()
    local function package_management_sub_menu()
        local function run(cmd)
            awful.spawn.with_shell("xdotool exec " .. beautiful.apps.kitty.command .. " && sleep 0.5 && xdotool type \"sudo pacman -" .. cmd .. "\"")
        end

        return widgets.menu
        {
            widgets.menu.button
            {
                text = "Check Local DB Validity",
                on_press = function() run("Dk") end
            },
            widgets.menu.button
            {
                text = "Refresh Package Database",
                on_press = function() run("Syy") end
            },
            widgets.menu.separator(),
            widgets.menu.button
            {
                text = "Upgrade Packages",
                on_press = function() run("Syu") end
            },
            widgets.menu.button
            {
                text = "Upgrade Packages (Refresh DB)",
                on_press = function() run("Syyu") end
            },
            widgets.menu.button
            {
                text = "Install Package(s)",
                on_press = function() run("S PKG_NAME") end
            },
            widgets.menu.button
            {
                text = "Download Package(s)",
                on_press = function() run("Sw PKG_NAME") end
            },
            widgets.menu.button
            {
                text = "Search Package",
                on_press = function() run("Ss STRING") end
            },
            widgets.menu.button
            {
                text = "Package Information",
                on_press = function() run("Sii PKG_NAME") end
            },
            widgets.menu.button
            {
                text = "Print Package URL/Path",
                on_press = function() run("Sp PKG_NAME") end
            },
            widgets.menu.button
            {
                text = "List Packages In Repo",
                on_press = function() run("Sl REPO_NAME") end
            },
            widgets.menu.separator(),
            widgets.menu.button
            {
                text = "Remove Package(s)",
                on_press = function() run("R PKG_NAME") end
            },
            widgets.menu.button
            {
                text = "Remove Package(s) & Depends",
                on_press = function() run("Rcv PKG_NAME") end
            },
            widgets.menu.button
            {
                text = "Remove Package(s) & Configs",
                on_press = function() run("Rnv PKG_NAME") end
            },
            widgets.menu.button
            {
                text = "Purge Package(s)",
                on_press = function() run("Rcnsuv PKG_NAME") end
            },
            widgets.menu.button
            {
                text = "Print Target Package(s)",
                on_press = function() run("Rcsup PKG_NAME") end
            },
            widgets.menu.button
            {
                text = "Remove Old Packages From Cache",
                on_press = function() run("Sc") end
            },
            widgets.menu.button
            {
                text = "Clear All Package Cache",
                on_press = function() run("Scc") end
            },
            widgets.menu.separator(),
            widgets.menu.button
            {
                text = "List All Installed Packages",
                on_press = function() run("Q") end
            },
            widgets.menu.button
            {
                text = "List Explicitly Installed Packages",
                on_press = function() run("Qe") end
            },
            widgets.menu.button
            {
                text = "List Outdated Packages",
                on_press = function() run("Qu") end
            },
            widgets.menu.button
            {
                text = "List Packages That Are Not In DB",
                on_press = function() run("Qm") end
            },
            widgets.menu.button
            {
                text = "Search Installed Package(s)",
                on_press = function() run("Qs STRING") end
            },
            widgets.menu.button
            {
                text = "View Package Information",
                on_press = function() run("Qii PKG_NAME") end
            },
            widgets.menu.button
            {
                text = "Check Package Files",
                on_press = function() run("Qkk PKG_NAME") end
            },
            widgets.menu.button
            {  widgets.menu.button
            {
                text = "Refresh Package Database",
                on_press = function() run("Syy") end
            },
            widgets.menu.button
            {
                text = "Upgrade Packages",
                on_press = function() run("Syu") end
            },
            widgets.menu.button
            {
                text = "Upgrade Packages (Refresh DB)",
                on_press = function() run("Syyu") end
            },
            widgets.menu.button
            {
                text = "Install Package(s)",
                on_press = function() run("S PKG_NAME") end
            },
            widgets.menu.button
            {
                text = "Download Package(s)",
                on_press = function() run("Sw PKG_NAME") end
            },
            widgets.menu.button
            {
                text = "Search Package",
                on_press = function() run("Ss STRING") end
            },
            widgets.menu.button
            {
                text = "Package Information",
                on_press = function() run("Sii PKG_NAME") end
            },
            widgets.menu.button
            {
                text = "Print Package URL/Path",
                on_press = function() run("Sp PKG_NAME") end
            },
            widgets.menu.button
            {
                text = "List Packages In Repo",
                on_press = function() run("Sl REPO_NAME") end
            },
            widgets.menu.button
            {
                text = "Remove Package(s)",
                on_press = function() run("R PKG_NAME") end
            },
            widgets.menu.button
            {
                text = "Remove Package(s) & Depends",
                on_press = function() run("Rcv PKG_NAME") end
            },
                text = "List Files Owned Package",
                on_press = function() run("Ql PKG_NAME") end
            },
            widgets.menu.button
            {
                text = "Check File Owned By Package",
                on_press = function() run("Qo FILE_NAME") end
            },
        }
    end

    local function systemd_services_sub_menu()
        local function run(cmd)
            awful.spawn.with_shell("xdotool exec " .. beautiful.apps.kitty.command .. " && sleep 0.5 && xdotool type \"sudo systemctl " .. cmd .. "\"")
        end

        return widgets.menu
        {
            widgets.menu.button
            {
                text = "List units currently in memory",
                on_press = function() run("list-units") end
            },
            widgets.menu.button
            {
                text = "List sockets currently in memory",
                on_press = function() run("list-sockets") end
            },
            widgets.menu.button
            {
                text = "List timers currently in memory",
                on_press = function() run("list-timers") end
            },
            widgets.menu.separator(),
            widgets.menu.button
            {
                text = "Check whether units are active",
                on_press = function() run("is-active PATTERN") end
            },
            widgets.menu.button
            {
                text = "Show runtime status of unit(s)",
                on_press = function() run("status UNIT(s)") end
            },
            widgets.menu.button
            {
                text = "Show properties of unit(s)",
                on_press = function() run("show UNIT(s)") end
            },
            widgets.menu.separator(),
            widgets.menu.button
            {
                text = "Start / Activate the unit(s)",
                on_press = function() run("start UNIT(s)") end
            },
            widgets.menu.button
            {
                text = "Stop / Deactivate the unit(s)",
                on_press = function() run("stop UNIT(s)") end
            },
            widgets.menu.button
            {
                text = "Reload the unit(s)",
                on_press = function() run("reload UNIT(s)") end
            },
            widgets.menu.button
            {
                text = "Restart the unit(s)",
                on_press = function() run("restart UNIT(s)") end
            },
        }
    end

    return widgets.menu
    {
        widgets.menu.sub_menu_button
        {
            text = "Package Management",
            sub_menu = package_management_sub_menu()
        },
        widgets.menu.sub_menu_button
        {
            text = "Systemd Services",
            sub_menu = systemd_services_sub_menu()
        }
    }
end

local function tag_sub_menu()
    local menu = widgets.menu{}

    for _, tag in ipairs(capi.screen.primary.tags) do
        local button = widgets.menu.checkbox_button
        {
            text = tag.name,
            on_press = function()
                tag:view_only()
            end
        }

        menu:add(button)

        tag:connect_signal("property::selected", function(t)
            if t.selected == true then
                button:turn_on()
            else
                button:turn_off()
            end
        end)
    end

    return menu
end

local function layout_sub_menu()
    local menu = widgets.menu{}

    capi.tag.connect_signal("property::selected", function(t)
        menu:reset()

        for _, layout in ipairs(t.layouts) do
            local button = widgets.menu.checkbox_button
            {
                text = layout.name,
                image = beautiful["layout_" .. (layout.name or "")],
                on_press = function()
                    t.layout = layout
                end
            }

            menu:add(button)

            if t.layout == layout then
                button:turn_on()
            else
                button:turn_off()
            end

            t:connect_signal("property::layout", function()
                if t.layout == layout then
                    button:turn_on()
                else
                    button:turn_off()
                end
            end)
        end
    end)

    return menu
end

local function widget()
    return widgets.menu
    {
        widgets.menu.button
        {
            icon = beautiful.launcher_icon,
            text = "Applicaitons",
            on_press = function() app_launcher:show() end
        },
        widgets.menu.button
        {
            icon = beautiful.terminal_icon,
            icon_size = 20,
            text = "Terminal",
            on_press = function() awful.spawn(beautiful.apps.kitty.command, false) end
        },
        widgets.menu.button
        {
            icon = beautiful.chrome_icon,
            text = "Web Browser",
            on_press = function() awful.spawn(beautiful.apps.firefox.command, false) end
        },
        widgets.menu.button
        {
            icon = beautiful.file_manager_icon,
            text = "File Manager",
            on_press = function() awful.spawn(beautiful.apps.ranger.command, false) end
        },
        widgets.menu.button
        {
            icon = beautiful.clipboard_icon,
            text = "Text Editor",
            on_press = function() awful.spawn(beautiful.apps.firefox.command, false) end
        },
        widgets.menu.separator(),
        widgets.menu.button
        {
            icon = beautiful.industry_icon,
            text = "Action Panel",
            on_press = function() action_panel:toggle() end
        },
        widgets.menu.button
        {
            icon = beautiful.message_icon,
            text = "Message Panel",
            on_press = function() message_panel:toggle() end
        },
        widgets.menu.button
        {
            icon = beautiful.calendar_icon,
            text = "Info Panel",
            on_press = function() info_panel:toggle() end
        },
        widgets.menu.button
        {
            icon = beautiful.keyboard_icon,
            text = "Keybinds",
            on_press = function() hotkeys_popup.show_help() end
        },
        widgets.menu.separator(),
        widgets.menu.button
        {
            icon = beautiful.camera_retro_icon,
            text = "Screenshot",
            on_press = function() screenshot_popup:toggle() end
        },
        widgets.menu.button
        {
            icon = beautiful.video_icon,
            text = "Record",
            on_press = function() record_popup:toggle() end
        },
        widgets.menu.separator(),
        widgets.menu.button
        {
            icon = beautiful.gear_icon,
            text = "Settings Manager",
            on_press = function() awful.spawn(beautiful.apps.xfce4_settings_manager.command, false) end
        },
        widgets.menu.button
        {
            icon = beautiful.spraycan_icon,
            text = "Theme Manager",
            on_press = function() theme_popup:toggle() end
        },
        widgets.menu.separator(),
        widgets.menu.sub_menu_button
        {
            icon = beautiful.tag_icon,
            text = "Tag",
            sub_menu = tag_sub_menu()
        },
        widgets.menu.sub_menu_button
        {
            icon = beautiful.table_layout_icon,
            text = "Layout",
            sub_menu = layout_sub_menu()
        },
        widgets.menu.separator(),
        widgets.menu.sub_menu_button
        {
            icon = beautiful.folder_open_icon,
            text = "Recent Places",
            sub_menu = recent_places_sub_menu()
        },
        widgets.menu.sub_menu_button
        {
            icon = beautiful.command_icon,
            text = "Commands",
            sub_menu = commands_sub_menu()
        },
        widgets.menu.separator(),
        widgets.menu.button
        {
            icon = beautiful.exit_icon,
            text = "Exit",
            on_press = function() power_popup:show() end
        }
    }
end

if not instance then
    instance = widget()
end
return instance