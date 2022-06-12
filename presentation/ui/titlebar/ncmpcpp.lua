-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local ruled = require("ruled")
local beautiful = require("beautiful")
local bling = require("modules.bling")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi

local function tabs_titlebar(c)
    local current_playlist = nil
    local local_files = nil
    local search = nil
    local libary = nil
    local playlist_editor  = nil
    local lyrics  = nil

    local accent_color = beautiful.random_accent_color()

    current_playlist = widgets.button.text.state
    {
        on_by_default = true,
        halign = "left",
        on_normal_bg = accent_color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        size = 12,
        text = "Current Playlist",
        on_turn_on = function()
            helpers.input.send_key_sequence(c, "1o")
            local_files:turn_off()
            search:turn_off()
            libary:turn_off()
            playlist_editor:turn_off()
            lyrics:turn_off()
        end
    }

    local_files = widgets.button.text.state
    {
        halign = "left",
        on_normal_bg = accent_color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        size = 12,
        text = "Local Files",
        on_turn_on = function()
            helpers.input.send_key(c, "2")
            current_playlist:turn_off()
            search:turn_off()
            libary:turn_off()
            playlist_editor:turn_off()
            lyrics:turn_off()
        end
    }

    search = widgets.button.text.state
    {
        halign = "left",
        on_normal_bg = accent_color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        size = 12,
        text = "Search",
        on_turn_on = function()
            helpers.input.send_key(c, "3")
            current_playlist:turn_off()
            local_files:turn_off()
            libary:turn_off()
            playlist_editor:turn_off()
            lyrics:turn_off()
        end
    }

    libary = widgets.button.text.state
    {
        halign = "left",
        on_normal_bg = accent_color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        size = 12,
        text = "Library",
        on_turn_on = function()
            helpers.input.send_key(c, "4")
            current_playlist:turn_off()
            local_files:turn_off()
            search:turn_off()
            playlist_editor:turn_off()
            lyrics:turn_off()
        end
    }

    playlist_editor = widgets.button.text.state
    {
        halign = "left",
        on_normal_bg = accent_color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        size = 12,
        text = "Playlist editor",
        on_turn_on = function()
            helpers.input.send_key(c, "5")
            current_playlist:turn_off()
            local_files:turn_off()
            search:turn_off()
            libary:turn_off()
            lyrics:turn_off()
        end
    }

    lyrics = widgets.button.text.state
    {
        halign = "left",
        on_normal_bg = accent_color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        size = 12,
        text = "Lyrics",
        on_turn_on = function()
            helpers.input.send_key_sequence(c, "1l")
            current_playlist:turn_off()
            local_files:turn_off()
            search:turn_off()
            libary:turn_off()
            playlist_editor:turn_off()
        end
    }

    awful.titlebar(c,
    {
        position = "left",
        size = dpi(230),
        bg = beautiful.colors.background
    }) : setup
    {
        widget = wibox.container.margin,
        margins = { left = dpi(15), top = dpi(25) },
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(15),
                widgets.text
                {
                    size = 50,
                    color = accent_color,
                    font = beautiful.list_music_icon.font,
                    text = beautiful.list_music_icon.icon
                },
                widgets.text
                {
                    size = 25,
                    text = "Mopidy"
                }
            },
            {
                widget = wibox.widget.separator,
                forced_width = dpi(1),
                forced_height = dpi(1),
                shape = helpers.ui.rrect(beautiful.border_radius),
                orientation = "horizontal",
                color = beautiful.colors.surface
            },
            current_playlist,
            local_files,
            search,
            libary,
            playlist_editor,
            lyrics
        }
    }
end

local function media_controls_titlebar(c)
    local playerctl_daemon = bling.signal.playerctl.lib
    {
        update_on_activity = true,
        player = { "mopidy", "%any" },
        debounce_delay = 1
    }

    awful.titlebar(c,
    {
        position = "bottom",
        size = dpi(100),
        bg = beautiful.colors.background
    }) : setup
    {
        layout = wibox.layout.align.horizontal,
        expand = "inside",
        {
            widget = wibox.container.place,
            valign = "center",
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(15),
                widgets.spacer.horizontal(1),
                widgets.playerctl.art("center", "top", dpi(50), 25, playerctl_daemon),
                {
                    widget = wibox.container.place,
                    valign = "center",
                    {
                        layout = wibox.layout.fixed.vertical,
                        spacing = dpi(5),
                        widgets.playerctl.title(150, "left", playerctl_daemon),
                        widgets.playerctl.artist(150, "left", playerctl_daemon),
                    }
                },
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
            widgets.playerctl.volume(dpi(100), playerctl_daemon),
            widgets.spacer.horizontal(30)
        }
    }
end

ruled.client.connect_signal("request::rules", function()
    ruled.client.append_rule
    {
        rule = { class = beautiful.apps.ncmpcpp.class },
        callback = function(c)
            c.custom_titlebar = true

            tabs_titlebar(c)
            media_controls_titlebar(c)
        end
    }
end)