-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local bling = require("external.bling")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local capi = {
    awesome = awesome
}

local ncmppcpp = {}

function ncmppcpp.tabs_titlebar(c)
    local current_playlist = nil
    local local_files = nil
    local search = nil
    local libary = nil
    local playlist_editor = nil
    local lyrics = nil

    current_playlist = wibox.widget {
        widget = widgets.button.text.state,
        on_by_default = true,
        halign = "left",
        on_normal_bg = beautiful.icons.list_music.color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        size = 12,
        text = "Current Playlist",
        on_turn_on = function()
            helpers.input.send_string_to_client(c, "1o")
            local_files:turn_off()
            search:turn_off()
            libary:turn_off()
            playlist_editor:turn_off()
            lyrics:turn_off()
        end
    }

    local_files = wibox.widget {
        widget = widgets.button.text.state,
        halign = "left",
        on_normal_bg = beautiful.icons.list_music.color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        size = 12,
        text = "Local Files",
        on_turn_on = function()
            helpers.input.send_string_to_client(c, "2")
            current_playlist:turn_off()
            search:turn_off()
            libary:turn_off()
            playlist_editor:turn_off()
            lyrics:turn_off()
        end
    }

    search = wibox.widget {
        widget = widgets.button.text.state,
        halign = "left",
        on_normal_bg = beautiful.icons.list_music.color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        size = 12,
        text = "Search",
        on_turn_on = function()
            helpers.input.send_string_to_client(c, "3")
            current_playlist:turn_off()
            local_files:turn_off()
            libary:turn_off()
            playlist_editor:turn_off()
            lyrics:turn_off()
        end
    }

    libary = wibox.widget {
        widget = widgets.button.text.state,
        halign = "left",
        on_normal_bg = beautiful.icons.list_music.color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        size = 12,
        text = "Library",
        on_turn_on = function()
            helpers.input.send_string_to_client(c, "4")
            current_playlist:turn_off()
            local_files:turn_off()
            search:turn_off()
            playlist_editor:turn_off()
            lyrics:turn_off()
        end
    }

    playlist_editor = wibox.widget {
        widget = widgets.button.text.state,
        halign = "left",
        on_normal_bg = beautiful.icons.list_music.color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        size = 12,
        text = "Playlist editor",
        on_turn_on = function()
            helpers.input.send_string_to_client(c, "5")
            current_playlist:turn_off()
            local_files:turn_off()
            search:turn_off()
            libary:turn_off()
            lyrics:turn_off()
        end
    }

    lyrics = wibox.widget {
        widget = widgets.button.text.state,
        halign = "left",
        on_normal_bg = beautiful.icons.list_music.color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        size = 12,
        text = "Lyrics",
        on_turn_on = function()
            helpers.input.send_string_to_client(c, "1l")
            current_playlist:turn_off()
            local_files:turn_off()
            search:turn_off()
            libary:turn_off()
            playlist_editor:turn_off()
        end
    }

    local titlebar =awful.titlebar(c, {
        position = "left",
        size = dpi(230),
        bg = beautiful.colors.background_no_opacity
    })
    titlebar:setup{
        widget = wibox.container.margin,
        margins = {
            left = dpi(15),
            right = dpi(15),
            top = dpi(25)
        },
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(15),
                wibox.widget {
                    widget = widgets.text,
                    size = 50,
                    icon = beautiful.icons.list_music,
                },
                wibox.widget {
                    widget = widgets.text,
                    size = 25,
                    text = "Mopidy"
                }
            },
            {
                widget = widgets.background,
                forced_height = dpi(1),
                shape = helpers.ui.rrect(),
                bg = beautiful.colors.surface
            },
            current_playlist,
            local_files,
            search,
            libary,
            playlist_editor,
            lyrics
        }
    }

    capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
        titlebar:set_bg(beautiful.colors.background_no_opacity)
    end)
end

function ncmppcpp.media_controls_titlebar(c)
    local playerctl_daemon = bling.signal.playerctl.lib {
        update_on_activity = true,
        player = {"mopidy", "%any"},
        debounce_delay = 1
    }

    local titlebar = awful.titlebar(c, {
        position = "bottom",
        size = dpi(100),
        bg = beautiful.colors.background_no_opacity
    })
    titlebar:setup{
        layout = wibox.layout.align.horizontal,
        expand = "inside",
        {
            widget = wibox.container.place,
            valign = "center",
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(15),
                {
                    widget = wibox.container.margin,
                    margins = { left = dpi(15) },
                    widgets.playerctl.art("center", "top", dpi(50), 25, playerctl_daemon),
                },
                {
                    widget = wibox.container.place,
                    valign = "center",
                    {
                        layout = wibox.layout.fixed.vertical,
                        spacing = dpi(5),
                        widgets.playerctl.title(150, "left", playerctl_daemon),
                        widgets.playerctl.artist(150, "left", playerctl_daemon)
                    }
                }
            }
        },
        {
            widget = wibox.container.place,
            halign = "center",
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(15),
                widgets.playerctl.loop_previous_play_next_shuffle(playerctl_daemon),
                widgets.playerctl.position_slider_length(dpi(400), playerctl_daemon)
            }
        },
        {
            layout = wibox.layout.fixed.horizontal,
            {
                widget = wibox.container.margin,
                margins = { right = dpi(30) },
                widgets.playerctl.volume(dpi(100), playerctl_daemon),
            }
        }
    }

    capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
        titlebar:set_bg(beautiful.colors.background_no_opacity)
    end)
end

return ncmppcpp
