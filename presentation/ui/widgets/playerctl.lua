-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local gshape = require("gears.shape")
local wibox = require("wibox")
local twidget = require("presentation.ui.widgets.text")
local tbutton = require("presentation.ui.widgets.button.text")
local ebutton = require("presentation.ui.widgets.button.elevated")
local wslider = require("presentation.ui.widgets.slider")
local beautiful = require("beautiful")
local general_playerctl_daemon = require("daemons.system.playerctl")
local animation = require("services.animation")
local helpers = require("helpers")
local icon_theme = require("services.icon_theme")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable
local math = math

local playerctl = { }

local accent_color = beautiful.random_accent_color()

function playerctl.art(halign, valign, size, default_icon_size, daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    local icon = wibox.widget
    {
        widget = wibox.widget.imagebox,
        halign = halign or "left",
        valign = valign or "top",
        clip_shape = helpers.ui.rrect(beautiful.border_radius),
        image = icon_theme:get_icon_path("spotify")
    }

    local default_icon = twidget
    {
        halign = halign or "left",
        valign = valign or "center",
        color = beautiful.random_accent_color(),
        size = default_icon_size or 150,
        font = beautiful.spotify_icon.font,
        text = beautiful.spotify_icon.icon,
    }

    local stack = wibox.widget
    {
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
            local app_font_icon = beautiful.get_font_icon_for_app_name(player_name)
            if app_font_icon ~= nil then
                default_icon:set_text(app_font_icon.icon)
            else
                default_icon:set_text(beautiful.spotify_icon.icon)
            end
            stack:raise_widget(default_icon)
        end
    end)

    playerctl_daemon:connect_signal("no_players", function(self)
        default_icon:set_text(beautiful.spotify_icon.icon)
        stack:raise_widget(default_icon)
    end)

    return stack
end

function playerctl.title_artist(daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    local widget = twidget
    {
        halign = "center",
        width = dpi(70),
        height = dpi(20),
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

function playerctl.player_name(halign, daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    local widget = twidget
    {
        halign = halign or "center",
        size = 12,
        text = "Not Playing"
    }

    playerctl_daemon:connect_signal("metadata", function(self, title, artist, album_path, album, new, player_name)
        if title ~= "" then
            player_name = player_name:sub(1, 1):upper() .. player_name:sub(2)
            widget:set_text(player_name)
        end
    end)

    return widget
end

function playerctl.title(width, halign, daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    local widget = twidget
    {
        width = width or dpi(70),
        height = dpi(20),
        halign = halign or "center",
        size = 12,
        text = "Not Playing"
    }

    playerctl_daemon:connect_signal("metadata", function(self, title, artist, album_path, album, new, player_name)
        if title ~= "" then
            widget:set_text(title)
        else
            widget:set_text("Not Playing")
        end
    end)

    playerctl_daemon:connect_signal("no_players", function(self)
        widget:set_text("Not Playing")
    end)

    return widget
end

function playerctl.artist(width, halign, daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    local widget = twidget
    {
        width = width or dpi(70),
        height = dpi(20),
        halign = halign or "center",
        size = 12,
        markup = "Artist"
    }

    playerctl_daemon:connect_signal("metadata", function(self, title, artist, album_path, album, new, player_name)
        if artist ~= "" then
            widget:set_text(artist)
        else
            widget:set_text("Artist")
        end
    end)

    playerctl_daemon:connect_signal("no_players", function(self)
        widget:set_text("Artist")
    end)

    return widget
end

local function create_point_maker()
	local self = {}
	self.height = 0

	local margin_x = 0.23
	local margin_y = 0.21
	local margin_yf = 0.15
	local width = 0.18

	--top slope, bottom slope, bottom y-int, top y-int
	local tm, bm, bb, tb

	--bottom left final, top left final, middle right, top middle final, bottom middle final
	local blf, tlf, mf, tmf, bmf

	function self:set_height(height)
		if height == self.height then return end --short circuit
		self.height = height

		blf = {x=margin_x*height, y=(1-margin_yf)*height}
		tlf = {x=margin_x*height, y=margin_yf*height}

		--middle, not slope
		mf = {x=(1-margin_x)*height, y=height/2}

		tm = (tlf.y-mf.y)/(tlf.x-mf.x)
		bm = (blf.y-mf.y)/(blf.x-mf.x)
		tb = tlf.y-tlf.x*tm
		bb = blf.y-blf.x*bm

		--middle, not slope
		tmf = {x=(margin_x+width)*height, y=tm*(margin_x+width)*height+tb}
		bmf = {x=(margin_x+width)*height, y=bm*(margin_x+width)*height+bb}

		--points look like this
		--p1-p2  p5-p6
		--|   |  |   |
		--p4_p3  p8_p7
		self.p1 = {x=margin_x*height, y=margin_y*height}
		self.p2 = {x=(margin_x+width)*height, y=margin_y*height}
		self.p3 = {x=(margin_x+width)*height, y=(1-margin_y)*height}
		self.p4 = {x=margin_x*height, y=(1-margin_y)*height}

		self.p5 = {x=(1-margin_x-width)*height, y=margin_y*height}
		self.p6 = {x=(1-margin_x)*height, y=margin_y*height}
		self.p7 = {x=(1-margin_x)*height, y=(1-margin_y)*height}
		self.p8 = {x=(1-margin_x-width)*height, y=(1-margin_y)*height}

		self.p1d = {y=self.p1.y-tlf.y}
		self.p2d = {y=self.p2.y-tmf.y}
		self.p3d = {y=self.p4.y-bmf.y}
		self.p4d = {y=self.p3.y-blf.y}

		self.p5d = {x=self.p5.x-tmf.x, y=self.p5.y-tmf.y} --x moves
		self.p6d = {y=self.p6.y-mf.y}
		self.p7d = {y=self.p7.y-mf.y}
		self.p8d = {x=self.p8.x-bmf.x, y=self.p7.y-bmf.y} --x moves

	end

	return self
end

local function get_draw(pos, pm)
	return function(_, _, cr, _, height)
		pm:set_height(height)

		-- cr:set_source_rgb(1.0, 1.0, 1.0)
        cr:set_source(require("gears.color")(beautiful.colors.background))

		if pos == 1 then
			cr:move_to(pm.p1.x, pm.p1.y-pm.p1d.y)
			cr:line_to(pm.p6.x, pm.p6.y-pm.p6d.y)
			cr:line_to(pm.p4.x, pm.p4.y-pm.p4d.y)
			cr:fill()
			return
		end

		cr:move_to(pm.p1.x, pm.p1.y-pm.p1d.y*pos)
		cr:line_to(pm.p2.x, pm.p2.y-pm.p2d.y*pos)
		cr:line_to(pm.p3.x, pm.p3.y-pm.p3d.y*pos)
		cr:line_to(pm.p4.x, pm.p4.y-pm.p4d.y*pos)
		cr:fill()

		cr:move_to(pm.p5.x-pm.p5d.x*pos, pm.p5.y-pm.p5d.y*pos)
		cr:line_to(pm.p6.x, pm.p6.y-pm.p6d.y*pos)
		cr:line_to(pm.p7.x, pm.p7.y-pm.p7d.y*pos)
		cr:line_to(pm.p8.x-pm.p8d.x*pos, pm.p8.y-pm.p8d.y*pos)
		cr:fill()
	end
end

function playerctl.play(daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    local point_maker = create_point_maker()

	local widget = wibox.widget
    {
        widget = wibox.widget.make_base_widget,
		forced_width = dpi(25),
		forced_height = dpi(25),
        fit = function(_, _, _, height) return height, height end,
		draw = get_draw(0, point_maker),
	}

    local button = ebutton.normal
    {
        normal_shape = gshape.circle,
        normal_bg = accent_color,
        on_release = function()
            playerctl_daemon:play_pause()
        end,
        child = widget
    }

    local play_pause_animation = animation:new
    {
		duration = 0.125,
        easing = animation.easing.linear,
		update = function(self, pos)
			widget.draw = get_draw(pos, point_maker)
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

    playerctl_daemon:connect_signal("no_players", function(self)
        play_pause_animation:set(1)
    end)

    return button
end

function playerctl.previous(width, height, daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    return tbutton.normal
    {
        forced_width = width or dpi(50),
        forced_height = height or dpi(50),
        normal_shape = gshape.circle,
        font = beautiful.backward_icon.font,
        size = 12,
        text_normal_bg = beautiful.colors.on_background,
        text = beautiful.backward_icon.icon,
        on_release = function()
            playerctl_daemon:previous()
        end
    }
end

function playerctl.next(width, height, daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    return tbutton.normal
    {
        forced_width = width or dpi(50),
        forced_height = height or dpi(50),
        normal_shape = gshape.circle,
        font = beautiful.forward_icon.font,
        size = 12,
        text_normal_bg = beautiful.colors.on_background,
        text = beautiful.forward_icon.icon,
        on_release = function()
            playerctl_daemon:next()
        end
    }
end

function playerctl.loop(width, height, daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    local widget = tbutton.state
    {
        forced_width = width or dpi(50),
        forced_height = height or dpi(50),
        normal_shape = gshape.circle,
        font = beautiful.repeat_icon.font,
        size = 12,
        text_normal_bg = beautiful.colors.on_background,
        text = beautiful.repeat_icon.icon,
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

    local widget = tbutton.state
    {
        forced_width = width or dpi(50),
        forced_height = height or dpi(50),
        normal_shape = gshape.circle,
        font = beautiful.shuffle_icon.font,
        size = 12,
        text_normal_bg = beautiful.colors.on_background,
        text = beautiful.shuffle_icon.icon,
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

    return wibox.widget
    {
        widget = wibox.container.place,
        halign = "center",
        {
            layout = wibox.layout.fixed.horizontal,
            spacing = dpi(15),
            playerctl.previous(nil, nil, playerctl_daemon),
            playerctl.play(nil, nil, playerctl_daemon),
            playerctl.next(nil, nil, playerctl_daemon),
        }
    }
end

function playerctl.loop_previous_play_next_shuffle(daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    return wibox.widget
    {
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

    local widget = wslider
    {
        forced_width = width or dpi(200),
        value = 0,
        maximum = 1,
        bar_height = 5,
        bar_shape = helpers.ui.rrect(beautiful.border_radius),
        bar_color = beautiful.colors.surface,
        bar_active_color = beautiful.colors.on_background,
        handle_width = dpi(2),
        handle_color = beautiful.colors.surface,
        handle_shape = gshape.circle,
    }

    widget:connect_signal("mouse::enter", function()
        if widget.maximum > 1 then
            widget.bar_active_color = accent_color
            widget.handle_color = beautiful.colors.on_background
            widget.handle_width = dpi(15)
        end
    end)

    widget:connect_signal("mouse::leave", function()
        widget.bar_active_color = beautiful.colors.on_background
        widget.handle_color = beautiful.colors.surface
        widget.handle_width = dpi(2)
    end)

    local function set_slider_value(self, position, length)
        widget.maximum = math.max(length, 1)
        widget.value = math.max(position, 0)
    end

    local function set_position(self, value)
        playerctl_daemon:set_position(value)
    end

    playerctl_daemon:connect_signal("seeked", function(self, position, player_name)
        widget.value = position
    end)

    playerctl_daemon:connect_signal("metadata", function(self, title, artist, album_path, album, new, player_name)
        widget.value = 0
    end)

    playerctl_daemon:connect_signal("no_players", function(self)
        widget.value = 0
    end)

    playerctl_daemon:connect_signal("position", set_slider_value)

    widget:connect_signal("button::press", function()
        -- widget:connect_signal("property::value", set_position)
        -- Set position won't be called on the first button press
        -- playerctl_daemon:set_position(widget.value)
        playerctl_daemon:disconnect_signal("position", set_slider_value)
    end)

    widget:connect_signal("button::release", function()
        if widget.maximum > 1 then
            playerctl_daemon:connect_signal("position", set_slider_value)
            playerctl_daemon:set_position(widget.value)
        end
        -- widget:disconnect_signal("property::value", set_position)
    end)

    return widget
end

function playerctl.position(daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    local widget = twidget
    {
        size = 12,
        color = beautiful.colors.on_background,
        text = "00:00"
    }

    playerctl_daemon:connect_signal("position", function(self, position, length)
        local hours = string.format("%02.f", math.floor(position/3600));
        local mins = string.format("%02.f", math.floor(position/60 - (hours*60)));
        local secs = string.format("%02.f", math.floor(position - hours*3600 - mins *60));
        widget.text = mins .. ":" .. secs
    end)

    playerctl_daemon:connect_signal("seeked", function(self, position, player_name)
        local hours = string.format("%02.f", math.floor(position/3600));
        local mins = string.format("%02.f", math.floor(position/60 - (hours*60)));
        local secs = string.format("%02.f", math.floor(position - hours*3600 - mins *60));
        widget.text = mins .. ":" .. secs
    end)

    playerctl_daemon:connect_signal("metadata", function(self, title, artist, album_path, album, new, player_name)
        widget.text = "00:00"
    end)

    playerctl_daemon:connect_signal("no_players", function(self)
        widget.text = "00:00"
    end)

    return widget
end

function playerctl.length(daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    local widget = twidget
    {
        size = 12,
        color = beautiful.colors.on_background,
        text = "00:00"
    }

    playerctl_daemon:connect_signal("position", function(self, position, length)
        if length > 0 then
            local hours = string.format("%02.f", math.floor(length/3600));
            local mins = string.format("%02.f", math.floor(length/60 - (hours*60)));
            local secs = string.format("%02.f", math.floor(length - hours*3600 - mins *60));
            widget.text = mins .. ":" .. secs
        else
            widget.text = "00:00"
        end
    end)

    playerctl_daemon:connect_signal("metadata", function(self, title, artist, album_path, album, new, player_name)
        widget.text = "00:00"
    end)

    playerctl_daemon:connect_signal("no_players", function(self)
        widget.text = "00:00"
    end)

    return widget
end

function playerctl.position_slider_length(slider_width, daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    return wibox.widget
    {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15),
        playerctl.position(playerctl_daemon),
        {
            widget = wibox.container.place,
            valign = "center",
            playerctl.slider(slider_width, playerctl_daemon),
        },
        playerctl.length(playerctl_daemon)
    }
end

function playerctl.volume(width, daemon)
    local playerctl_daemon = daemon or general_playerctl_daemon

    local icon = twidget
    {
        font = beautiful.volume_normal_icon.font,
        size = 12,
        text = beautiful.volume_normal_icon.icon,
        color = accent_color
    }

    local widget = wslider
    {
        forced_width = width or dpi(50),
        value = 100,
        maximum = 100,
        bar_height = 5,
        bar_shape = helpers.ui.rrect(beautiful.border_radius),
        bar_color = beautiful.colors.surface,
        bar_active_color = beautiful.colors.on_background,
        handle_width = dpi(2),
        handle_color = beautiful.colors.surface,
        handle_shape = gshape.circle,
    }

    widget:connect_signal("mouse::enter", function()
        widget.bar_active_color = accent_color
        widget.handle_color = beautiful.colors.on_background
        widget.handle_width = dpi(15)
    end)

    widget:connect_signal("mouse::leave", function()
        widget.bar_active_color = beautiful.colors.on_background
        widget.handle_color = beautiful.colors.surface
        widget.handle_width = dpi(2)
    end)

    local function set_slider_value(self, volume)
        widget.value = volume * 100

        if volume == 0 then
            icon:set_text(beautiful.volume_off_icon.icon)
        elseif volume <= 0.33 then
            icon:set_text(beautiful.volume_low_icon.icon)
        elseif volume <= 0.66 then
            icon:set_text(beautiful.volume_normal_icon.icon)
        elseif volume > 0.66 then
            icon:set_text(beautiful.volume_high_icon.icon)
        end
    end

    local function set_position(self, value)
        playerctl_daemon:set_volume(value / 100)
    end

    playerctl_daemon:connect_signal("volume", set_slider_value)

    widget:connect_signal("button::press", function()
        -- widget:connect_signal("property::value", set_position)
        -- Set position won't be called on the first button press
        -- playerctl_daemon:set_position(widget.value)
        playerctl_daemon:disconnect_signal("volume", set_slider_value)
    end)

    widget:connect_signal("button::release", function()
        playerctl_daemon:connect_signal("volume", set_slider_value)
        playerctl_daemon:set_volume(widget.value / 100)
        -- widget:disconnect_signal("property::value", set_position)
    end)

    return wibox.widget
    {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15),
        icon,
        widget
    }
end

return setmetatable(playerctl, playerctl.mt)