-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local beautiful = require("beautiful")
local naughty = require("naughty")
local playerctl_daemon = require("daemons.system.playerctl")
local string = string

playerctl_daemon:connect_signal("metadata", function(self, title, artist, album_path, album, new, player_name)
    if new == false then
        return
    end

    local app_font_icon = beautiful.get_font_icon_for_app_name(player_name)
    local text = (artist ~= "") and artist or (album ~= "") and album or player_name:gsub("^%l", string.upper)
    local icon = album_path ~= "" and album_path or {"youtube"}
    local font_icon = album_path == "" and beautiful.youtube_icon or nil
    local app_name = album_path ~= "" and nil or player_name

    local previous = naughty.action { name = "Previous" }
    local play_pause = naughty.action {  name = "Play/Pause" }
    local next = naughty.action { name = "Next" }

    previous:connect_signal("invoked", function()
        playerctl_daemon:previous()
    end)

    play_pause:connect_signal("invoked", function()
        playerctl_daemon:play_pause()
    end)

    next:connect_signal("invoked", function()
        playerctl_daemon:next()
    end)

    naughty.notification
    {
        app_font_icon = app_font_icon,
        app_name = app_name,
        font_icon = font_icon,
        icon = icon,
        title = title,
        text = text,
        actions = { previous, play_pause, next }
    }
end)
