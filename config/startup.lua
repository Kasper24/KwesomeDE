-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gtimer = require("gears.timer")
local beautiful = require("beautiful")
local persistent_daemon = require("daemons.system.persistent")
local helpers = require("helpers")

local function setup_system_tools()
   helpers.run.run_once_ps("polkit-gnome-authentication-agent-1", "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
   helpers.run.run_once_grep("blueman-applet")
   helpers.run.run_once_grep("parcellite")
   helpers.run.run_once_grep("kdeconnect-indicator")
   helpers.run.run_once_grep("mopidy")
   helpers.run.run_once_grep(beautiful.apps.openrgb.command)
end

local function configure_xserver()
   awful.spawn("xrandr --output DP-2 --gamma 0.8", false)
   awful.spawn("xset s off", false)
   awful.spawn("xset -dpms", false)
   awful.spawn("xset s noblank", false)
   awful.spawn("xset r rate 200 30", false)
   gtimer.delayed_call(function()
      awful.spawn("setxkbmap -layout us,il -variant , -option grp:alt_shift_toggle", false)
   end)

   -- Why does xkbcomp only disable caps lock on release instead of on press like any other key?
   awful.spawn.with_shell
   ([[
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

setup_system_tools()
configure_xserver()
persistent_daemon:enable()
