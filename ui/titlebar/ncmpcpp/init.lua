-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local awful = require("awful")
local ruled = require("ruled")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local bling = require("external.bling")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local capi = {
    awesome = awesome
}

local function tab_button(title)
    return wibox.widget {
        widget = widgets.button.state,
        on_by_default = true,
        halign = "left",
        on_color = beautiful.icons.list_music.color,
        {
            widget = widgets.text,
            color = beautiful.colors.on_background,
            on_color = beautiful.colors.on_accent,
            size = 12,
            text = title,
        }
    }
end

local function tabs_titlebar(c)
    local tabs = wibox.widget {
        widget = widgets.button_group.vertical,
        on_select = function(id)
            helpers.input.send_string_to_client(c, id)
        end,
        values = {
            {
                id = "1o",
                button = tab_button("Current Playlist")
            },
            {
                id = "2",
                button = tab_button("Local Files")

            },
            {
                id = "3",
                button = tab_button("Search")

            },
            {
                id = "4",
                button = tab_button("Library")

            },
            {
                id = "5",
                button = tab_button("Playlist editor")
            },
            {
                id = "1l",
                button = tab_button("Lyrics")
            }
        }
    }

    local titlebar = awful.titlebar(c, {
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
            tabs
        }
    }

    capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
        titlebar:set_bg(beautiful.colors.background_no_opacity)
    end)
end

local function media_controls_titlebar(c)
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

ruled.client.connect_signal("request::rules", function()
    ruled.client.append_rule
    {
        rule = { class = "mopidy" },
        callback = function(c)
            c.custom_titlebar = true

            tabs_titlebar(c)
            media_controls_titlebar(c)
        end
    }
end)
