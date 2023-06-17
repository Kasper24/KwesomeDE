-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local helpers = require("helpers")

helpers.run.run_once_grep("blueman-applet")
helpers.run.run_once_grep("parcellite")
helpers.run.run_once_grep("kdeconnect-indicator")
helpers.run.run_once_grep("mopidy")
helpers.run.run_once_grep("bitwarden")
helpers.run.run_once_grep("maestral_qt")

awful.spawn("xset s off", false)
awful.spawn("xset -dpms", false)
awful.spawn("xset s noblank", false)
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
