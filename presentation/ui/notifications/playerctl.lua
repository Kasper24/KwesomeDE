local naughty = require("naughty")
local playerctl_daemon = require("daemons.system.playerctl")
local string = string

playerctl_daemon:connect_signal("metadata", function(self, title, artist, album_path, album, new, player_name)
    if new == false then
        return
    end

    local text = (artist ~= "") and artist or (album ~= "") and album or player_name:gsub("^%l", string.upper)
    local image = (album_path ~= "") and album_path or {"youtube"}
    local app_name = (album_path ~= "") and nil or player_name

    if app_name == "chromium" then
        app_name = "vivaldi"
    end

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
        app_name = app_name,
        icon = image,
        title = title,
        text = text,
        actions = { previous, play_pause, next }
    }
end)
