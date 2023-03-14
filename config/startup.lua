-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gtimer = require("gears.timer")
local helpers = require("helpers")
local string = string

local function run_programs()
    awful.spawn(string.format("sudo %s/Dotfiles/packages/wal-vivaldi/patcher.py", os.getenv("HOME")))

    helpers.run.run_once_ps("polkit-gnome-authentication-agent-1",
        "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    helpers.run.run_once_grep("blueman-applet")
    helpers.run.run_once_grep("parcellite")
    helpers.run.run_once_grep("kdeconnect-indicator")
    helpers.run.run_once_grep("mopidy")
    helpers.run.run_once_grep("bitwarden-desktop", "bitwarden")
    gtimer.start_new(10, function()
        helpers.run.run_once_grep("openrgb --server --gui")
        return false
    end)
end

local function configure_keyboard()
    gtimer {
        autostart = true,
        call_now = true,
        single_shot = false,
        timeout = 600,
        callback = function()
            awful.spawn("xset r rate 200 30", false)

            gtimer.delayed_call(function()
                awful.spawn("setxkbmap -layout us,il -variant , -option grp:alt_shift_toggle", false)
            end)

            awful.spawn.with_shell([[
        xkbcomp -xkb "$DISPLAY" - | sed 's#key <CAPS>.*#key <CAPS> {\
           repeat=no,\
           type[group1]="ALPHABETIC",\
           symbols[group1]=[ Caps_Lock, Caps_Lock],\
           actions[group1]=[ LockMods(modifiers=Lock),\
           Private(type=3,data[0]=1,data[1]=3,data[2]=3)]\
        };\
        #' | xkbcomp -w 0 - "$DISPLAY"
           ]])
        end
    }
end

local function configure_display()
    awful.spawn("xset s off", false)
    awful.spawn("xset -dpms", false)
    awful.spawn("xset s noblank", false)

    gtimer.poller {
        timeout = 600,
        callback = function()
            configure_keyboard()
        end
    }
end

run_programs()
configure_keyboard()
configure_display()
