-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local cairo = require("lgi").cairo
local gsurface = require("gears.surface")
local gshape = require("gears.shape")
local gcolor = require("gears.color")
local wibox = require("wibox")
local twidget = require("ui.widgets.text")
local tbwidget = require("ui.widgets.button.text")
local ebwidget = require("ui.widgets.button.elevated")
local swidget = require("ui.widgets.slider")
local beautiful = require("beautiful")
local tasklist_daemon = require("daemons.system.tasklist")
local general_playerctl_daemon = require("daemons.system.playerctl")
local theme_daemon = require("daemons.system.theme")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable
local math = math
local capi = {
    awesome = awesome,
    screen = screen
}

local playerctl = {}

function playerctl.art_opacity(daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    local function colors()
        return {
            {
                stop = 0,
                color = beautiful.colors.background_no_opacity
            },
            {
                stop = 0.3,
                color = beautiful.colors.background_no_opacity  .. "CC"
            },
            {
                stop = 0.7,
                color = beautiful.colors.background_no_opacity  .. "BB"
            },
            {
                stop = 1,
                color = beautiful.colors.background_no_opacity  .. "99"
            }
        }
    end

    local function image_surface(path)
        local adjusted_image = helpers.ui.adjust_image_res(path, 500, 225)
        return helpers.ui.add_gradient_to_surface(adjusted_image, colors())
    end

    local art = wibox.widget{
        widget = wibox.widget.imagebox,
        opacity = 0.6,
        horizontal_fit_policy = "fit",
        vertical_fit_policy = "fit",
        image = image_surface(theme_daemon:get_wallpaper_path()),
    }

    local image = false
    playerctl_daemon:connect_signal("metadata", function(_, title, artist, album_path, _, new, player_name)
        if album_path ~= "" then
            image = album_path
            art.image = image_surface(album_path)
        else
            image = nil
            art.image = image_surface(theme_daemon:get_wallpaper_path())
        end
    end)

    playerctl_daemon:connect_signal("no_players", function()
        art.image = image_surface(theme_daemon:get_wallpaper_path())
        image = nil
    end)

    capi.awesome.connect_signal("wallpaper::changed", function()
        if not image then
            art.image = image_surface(theme_daemon:get_wallpaper_path())
        end
    end)

    capi.awesome.connect_signal("colorscheme::changed", function()
        if not image then
            art.image = image_surface(theme_daemon:get_wallpaper_path())
        else
            art.image = image_surface(image)
        end
    end)


    return art
end

function playerctl.art(halign, valign, size, default_icon_size, daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    local icon = wibox.widget {
        widget = wibox.widget.imagebox,
        halign = halign or "left",
        valign = valign or "top",
        clip_shape = helpers.ui.rrect(),
        image = helpers.icon_theme.get_icon_path("spotify")
    }

    local default_icon = wibox.widget {
        widget = twidget,
        halign = halign or "left",
        valign = valign or "center",
        icon = beautiful.icons.spotify,
        size = default_icon_size or 150
    }

    local stack = wibox.widget {
        layout = wibox.layout.stack,
        forced_width = size or dpi(200),
        forced_height = size or dpi(200),
        top_only = true,
        default_icon,
        icon
    }

    playerctl_daemon:connect_signal("metadata", function(self, title, artist, album_path, album, new, player_name)
        if album_path ~= "" then
            icon.image = album_path
            stack:raise_widget(icon)
        else
            local app_font_icon = tasklist_daemon:get_font_icon(player_name, "spotfy")
            default_icon:set_icon(app_font_icon)
            stack:raise_widget(default_icon)
        end
    end)

    playerctl_daemon:connect_signal("no_players", function(self)
        default_icon:set_icon(beautiful.icons.spotify)
        stack:raise_widget(default_icon)
    end)

    return stack
end

function playerctl.title_artist(daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    local widget = wibox.widget {
        widget = twidget,
        halign = "center",
        forced_width = dpi(70),
        forced_height = dpi(20),
        size = 12,
        text = "Not Playing"
    }

    playerctl_daemon:connect_signal("metadata", function(self, title, artist, album_path, album, new, player_name)
        if title == "" and artist == "" then
            widget:set_text("Not Playing")
        else
            widget:set_text(title .. " - " .. artist)
        end
    end)

    playerctl_daemon:connect_signal("no_players", function(self)
        widget:set_text("Not Playing")
    end)

    return widget
end

function playerctl.player_art(halign, valign, daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    local icon = wibox.widget {
        widget = twidget,
        halign = halign or "left",
        valign = valign or "center",
        icon = beautiful.icons.spotify,
    }

    playerctl_daemon:connect_signal("metadata", function(self, title, artist, album_path, album, new, player_name)
        if player_name ~= "" then
            local app_font_icon = tasklist_daemon:get_font_icon(player_name, "spotify")
            icon:set_icon(app_font_icon)
        end
    end)

    playerctl_daemon:connect_signal("no_players", function(self)
        icon:set_icon(beautiful.icons.spotify)
    end)

    return icon
end

function playerctl.player_name(halign, daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    local widget = wibox.widget {
        widget = twidget,
        halign = halign or "center",
        size = 12,
        text = "Not Playing"
    }

    playerctl_daemon:connect_signal("metadata", function(self, title, artist, album_path, album, new, player_name)
        if title ~= "" then
            player_name = player_name:sub(1, 1):upper() .. player_name:sub(2)
            widget:set_text(player_name)
        else
            widget:set_text("Not Playing")
        end
    end)

    playerctl_daemon:connect_signal("no_players", function(self)
        widget:set_text("Not Playing")
    end)

    return widget
end

function playerctl.title(width, halign, daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    local widget = wibox.widget {
        widget = twidget,
        forced_width = width or dpi(70),
        forced_height = dpi(20),
        halign = halign or "center",
        size = 12,
        text = ""
    }

    playerctl_daemon:connect_signal("metadata", function(self, title, artist, album_path, album, new, player_name)
        if title ~= "" then
            widget:set_text(title)
        else
            widget:set_text("")
        end
    end)

    playerctl_daemon:connect_signal("no_players", function(self)
        widget:set_text("")
    end)

    return widget
end

function playerctl.artist(width, halign, daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    local widget = wibox.widget {
        widget = twidget,
        forced_width = width or dpi(70),
        forced_height = dpi(20),
        halign = halign or "center",
        size = 12,
        text = ""
    }

    playerctl_daemon:connect_signal("metadata", function(self, title, artist, album_path, album, new, player_name)
        if artist ~= "" then
            widget:set_text(artist)
        else
            widget:set_text("")
        end
    end)

    playerctl_daemon:connect_signal("no_players", function(self)
        widget:set_text("")
    end)

    return widget
end

local function create_point_maker()
    local self = {}
    self.height = 0

    local margin_x = 0.23
    local margin_y = 0.21
    local margin_yf = 0.2
    local width = 0.18

    -- top slope, bottom slope, bottom y-int, top y-int
    local tm, bm, bb, tb

    -- bottom left final, top left final, middle right, top middle final, bottom middle final
    local blf, tlf, mf, tmf, bmf

    function self:set_height(height)
        if height == self.height then
            return
        end -- short circuit
        self.height = height

        blf = {
            x = margin_x * height,
            y = (1 - margin_yf) * height
        }
        tlf = {
            x = margin_x * height,
            y = margin_yf * height
        }

        -- middle, not slope
        mf = {
            x = (1 - margin_x) * height,
            y = height / 2
        }

        tm = (tlf.y - mf.y) / (tlf.x - mf.x)
        bm = (blf.y - mf.y) / (blf.x - mf.x)
        tb = tlf.y - tlf.x * tm
        bb = blf.y - blf.x * bm

        -- middle, not slope
        tmf = {
            x = (margin_x + width) * height,
            y = tm * (margin_x + width) * height + tb
        }
        bmf = {
            x = (margin_x + width) * height,
            y = bm * (margin_x + width) * height + bb
        }

        -- points look like this
        -- p1-p2  p5-p6
        -- |   |  |   |
        -- p4_p3  p8_p7
        self.p1 = {
            x = margin_x * height,
            y = margin_y * height
        }
        self.p2 = {
            x = (margin_x + width) * height,
            y = margin_y * height
        }
        self.p3 = {
            x = (margin_x + width) * height,
            y = (1 - margin_y) * height
        }
        self.p4 = {
            x = margin_x * height,
            y = (1 - margin_y) * height
        }

        self.p5 = {
            x = (1 - margin_x - width) * height,
            y = margin_y * height
        }
        self.p6 = {
            x = (1 - margin_x) * height,
            y = margin_y * height
        }
        self.p7 = {
            x = (1 - margin_x) * height,
            y = (1 - margin_y) * height
        }
        self.p8 = {
            x = (1 - margin_x - width) * height,
            y = (1 - margin_y) * height
        }

        self.p1d = {
            y = self.p1.y - tlf.y
        }
        self.p2d = {
            y = self.p2.y - tmf.y
        }
        self.p3d = {
            y = self.p4.y - bmf.y
        }
        self.p4d = {
            y = self.p3.y - blf.y
        }

        self.p5d = {
            x = self.p5.x - tmf.x,
            y = self.p5.y - tmf.y
        } -- x moves
        self.p6d = {
            y = self.p6.y - mf.y
        }
        self.p7d = {
            y = self.p7.y - mf.y
        }
        self.p8d = {
            x = self.p8.x - bmf.x,
            y = self.p7.y - bmf.y
        } -- x moves

    end

    return self
end

local function get_draw(pm)
    return function(self, _, cr, __, height)
        pm:set_height(height)

        cr:set_source(gcolor(beautiful.colors.background_no_opacity))

        if self.pos == 1 then
            cr:move_to(pm.p1.x, pm.p1.y - pm.p1d.y)
            cr:line_to(pm.p6.x, pm.p6.y - pm.p6d.y)
            cr:line_to(pm.p4.x, pm.p4.y - pm.p4d.y)
            cr:fill()
            return
        end

        cr:move_to(pm.p1.x, pm.p1.y - pm.p1d.y * self.pos)
        cr:line_to(pm.p2.x, pm.p2.y - pm.p2d.y * self.pos)
        cr:line_to(pm.p3.x, pm.p3.y - pm.p3d.y * self.pos)
        cr:line_to(pm.p4.x, pm.p4.y - pm.p4d.y * self.pos)
        cr:fill()

        cr:move_to(pm.p5.x - pm.p5d.x * self.pos, pm.p5.y - pm.p5d.y * self.pos)
        cr:line_to(pm.p6.x, pm.p6.y - pm.p6d.y * self.pos)
        cr:line_to(pm.p7.x, pm.p7.y - pm.p7d.y * self.pos)
        cr:line_to(pm.p8.x - pm.p8d.x * self.pos, pm.p8.y - pm.p8d.y * self.pos)
        cr:fill()
    end
end

function playerctl.play(daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    local point_maker = create_point_maker()

    local widget = wibox.widget {
        widget = wibox.widget.make_base_widget,
        forced_width = dpi(35),
        forced_height = dpi(35),
        pos = 0,
        fit = function(_, _, _, height)
            return height, height
        end,
        draw = get_draw(point_maker)
    }

    local button = wibox.widget {
        widget = ebwidget.normal,
        normal_shape = gshape.circle,
        normal_bg = beautiful.icons.spotify.color,
        on_release = function()
            playerctl_daemon:play_pause()
        end,
        widget
    }

    local play_pause_animation = helpers.animation:new{
        duration = 0.2,
        easing = helpers.animation.easing.linear,
        update = function(self, pos)
            widget.pos = pos
            widget:emit_signal("widget::redraw_needed")
        end
    }

    playerctl_daemon:connect_signal("playback_status", function(self, playing)
        if playing then
            play_pause_animation:set(0)
        else
            play_pause_animation:set(1)
        end
    end)

    playerctl_daemon:connect_signal("metadata", function(self, title, artist, album_path, album, new, player_name)
        if player_name ~= "" then
            local app_font_icon = tasklist_daemon:get_font_icon(player_name, "spotify")
            button:set_normal_bg(app_font_icon.color)
        end
    end)

    playerctl_daemon:connect_signal("no_players", function(self)
        play_pause_animation:set(1)
        button:set_normal_bg(beautiful.icons.spotify.color)
    end)

    return button
end

function playerctl.previous(width, height, daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    return wibox.widget {
        widget = tbwidget.normal,
        forced_width = width or dpi(50),
        forced_height = height or dpi(50),
        normal_shape = gshape.circle,
        normal_bg = beautiful.colors.transparent,
        text_normal_bg = beautiful.colors.on_background,
        icon = beautiful.icons.backward,
        size = 12,
        on_release = function()
            playerctl_daemon:previous()
        end
    }
end

function playerctl.next(width, height, daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    return wibox.widget {
        widget = tbwidget.normal,
        forced_width = width or dpi(50),
        forced_height = height or dpi(50),
        normal_shape = gshape.circle,
        normal_bg = beautiful.colors.transparent,
        text_normal_bg = beautiful.colors.on_background,
        icon = beautiful.icons.forward,
        size = 12,
        on_release = function()
            playerctl_daemon:next()
        end
    }
end

function playerctl.loop(width, height, daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    local widget = wibox.widget {
        widget = tbwidget.state,
        forced_width = width or dpi(50),
        forced_height = height or dpi(50),
        normal_shape = gshape.circle,
        normal_bg = beautiful.colors.transparent,
        text_normal_bg = beautiful.colors.on_background,
        icon = beautiful.icons._repeat,
        size = 12,
        on_release = function(self)
            playerctl_daemon:cycle_loop_status()
        end
    }

    playerctl_daemon:connect_signal("loop_status", function(self, loop_status, player)
        if loop_status == "none" then
            widget:turn_off()
        else
            widget:turn_on()
        end
    end)

    return widget
end

function playerctl.shuffle(width, height, daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    local widget = wibox.widget {
        widget = tbwidget.state,
        forced_width = width or dpi(50),
        forced_height = height or dpi(50),
        normal_shape = gshape.circle,
        normal_bg = beautiful.colors.transparent,
        text_normal_bg = beautiful.colors.on_background,
        icon = beautiful.icons.shuffle,
        size = 12,
        on_release = function(self)
            playerctl_daemon:cycle_shuffle()
        end
    }

    playerctl_daemon:connect_signal("shuffle", function(self, shuffle, player)
        if shuffle == true then
            widget:turn_on()
        else
            widget:turn_off()
        end
    end)

    return widget
end

function playerctl.previous_play_next(daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    return wibox.widget {
        widget = wibox.container.place,
        halign = "center",
        {
            layout = wibox.layout.fixed.horizontal,
            spacing = dpi(15),
            playerctl.previous(nil, nil, playerctl_daemon),
            playerctl.play(nil, nil, playerctl_daemon),
            playerctl.next(nil, nil, playerctl_daemon)
        }
    }
end

function playerctl.loop_previous_play_next_shuffle(daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    return wibox.widget {
        widget = wibox.container.place,
        halign = "center",
        {
            layout = wibox.layout.fixed.horizontal,
            spacing = dpi(15),
            playerctl.shuffle(nil, nil, playerctl_daemon),
            playerctl.previous(nil, nil, playerctl_daemon),
            playerctl.play(playerctl_daemon),
            playerctl.next(nil, nil, playerctl_daemon),
            playerctl.loop(nil, nil, playerctl_daemon)
        }
    }
end

function playerctl.slider(width, daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    local slider = swidget {
        forced_width = width or dpi(200),
        forced_height = dpi(20),
        maximum = 0,
        bar_active_color = beautiful.colors.on_background,
        handle_width = dpi(20),
        handle_height = dpi(20),
        handle_color = beautiful.colors.on_background,
    }

    playerctl_daemon:connect_signal("seeked", function(self, position, player_name)
        slider:set_value(position)
    end)

    playerctl_daemon:connect_signal("metadata", function(self, title, artist, album_path, album, new, player_name)
        slider:set_value(0)
    end)

    playerctl_daemon:connect_signal("no_players", function(self)
        slider:set_maximum(0)
        slider:set_value(0)
    end)

    playerctl_daemon:connect_signal("position", function(self, position, length)
        slider:set_maximum(math.max(length, 1))
        slider:set_value(math.max(position, 0))
    end)

    slider:connect_signal("property::value", function(self, value)
        playerctl_daemon:set_position(value)
    end)

    return slider
end

function playerctl.position(daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    local widget = wibox.widget {
        widget = twidget,
        size = 12,
        color = beautiful.colors.on_background,
        text = "00:00"
    }

    playerctl_daemon:connect_signal("position", function(self, position, length)
        local hours = string.format("%02.f", math.floor(position / 3600));
        local mins = string.format("%02.f", math.floor(position / 60 - (hours * 60)));
        local secs = string.format("%02.f", math.floor(position - hours * 3600 - mins * 60));
        widget:set_text(mins .. ":" .. secs)
    end)

    playerctl_daemon:connect_signal("seeked", function(self, position, player_name)
        local hours = string.format("%02.f", math.floor(position / 3600));
        local mins = string.format("%02.f", math.floor(position / 60 - (hours * 60)));
        local secs = string.format("%02.f", math.floor(position - hours * 3600 - mins * 60));
        widget:set_text(mins .. ":" .. secs)
    end)

    playerctl_daemon:connect_signal("metadata", function(self, title, artist, album_path, album, new, player_name)
        widget:set_text("00:00")
    end)

    playerctl_daemon:connect_signal("no_players", function(self)
        widget:set_text("00:00")
    end)

    return widget
end

function playerctl.length(daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    local widget = wibox.widget {
        widget = twidget,
        size = 12,
        color = beautiful.colors.on_background,
        text = "00:00"
    }

    playerctl_daemon:connect_signal("position", function(self, position, length)
        if length > 0 then
            local hours = string.format("%02.f", math.floor(length / 3600));
            local mins = string.format("%02.f", math.floor(length / 60 - (hours * 60)));
            local secs = string.format("%02.f", math.floor(length - hours * 3600 - mins * 60));
            widget:set_text(mins .. ":" .. secs)
        else
            widget:set_text("00:00")
        end
    end)

    playerctl_daemon:connect_signal("metadata", function(self, title, artist, album_path, album, new, player_name)
        widget:set_text("00:00")
    end)

    playerctl_daemon:connect_signal("no_players", function(self)
        widget:set_text("00:00")
    end)

    return widget
end

function playerctl.position_slider_length(slider_width, daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15),
        playerctl.position(playerctl_daemon),
        {
            widget = wibox.container.place,
            valign = "center",
            playerctl.slider(slider_width, playerctl_daemon)
        },
        playerctl.length(playerctl_daemon)
    }
end

function playerctl.volume(width, daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    local icon = wibox.widget {
        widget = twidget,
        icon = beautiful.icons.volume.normal,
        size = 12,
    }

    local slider = swidget {
        forced_width = width or dpi(50),
        active_bar_color = beautiful.icons.volume.normal.color,
        value = 100
    }

    playerctl_daemon:connect_signal("volume", function(self, volume)
        slider:set_value_instant(volume)

        if volume == 0 then
            icon:set_icon(beautiful.icons.volume.off)
        elseif volume <= 0.33 then
            icon:set_icon(beautiful.icons.volume.low)
        elseif volume <= 0.66 then
            icon:set_icon(beautiful.icons.volume.normal)
        elseif volume > 0.66 then
            icon:set_icon(beautiful.icons.volume.high)
        end
    end)

    slider:connect_signal("property::value", function(self, value)
        playerctl_daemon:set_volume(value / 100)
    end)

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15),
        icon,
        slider
    }
end

return setmetatable(playerctl, playerctl.mt)
