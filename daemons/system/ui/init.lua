-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local beautiful = require("beautiful")
local library = require("library")
local filesystem = require("external.filesystem")
local ipairs = ipairs
local os = os
local capi = {
	root = root,
	screen = screen,
}

local ui = {}
local instance = nil

local function setup_profile_image(self)
	if self:get_profile_image() == nil then
		local profile_image = filesystem.file.new_for_path(os.getenv("HOME") .. "/.face")
		profile_image:exists(function(error, exists)
			if error == nil and exists == true then
				self:set_profile_image(os.getenv("HOME") .. "/.face")
			else
				profile_image = filesystem.file.new_for_path("/var/lib/AccountService/icons/" .. os.getenv("USER"))
				profile_image:exists(function(error, exists)
					if error == nil and exists == true then
						self:set_profile_image("/var/lib/AccountService/icons/" .. os.getenv("USER"))
					end
				end)
			end
		end)
	end
end

-- Recolor icons
function ui:set_recolor_icons(recolor_icons)
	self._private.recolor_icons = recolor_icons
	library.settings["ui.recolor_icons"] = recolor_icons
end

function ui:get_recolor_icons()
	if self._private.recolor_icons == nil then
		self._private.recolor_icons = library.settings["ui.recolor_icons"]
	end

	return self._private.recolor_icons
end

-- Profile image
function ui:set_profile_image(profile_image)
	self._private.profile_image = profile_image
	library.settings["ui.profile_image"] = profile_image
	self:emit_signal("profile_image", profile_image)
end

function ui:get_profile_image()
	if self._private.profile_image == nil then
		self._private.profile_image = library.settings["ui.profile_image"]
	end

	return self._private.profile_image
end

-- DPI
function ui:set_dpi(dpi)
	self._private.dpi = dpi
	library.settings["ui.dpi"] = dpi
end

function ui:get_dpi()
	if self._private.dpi == nil then
		self._private.dpi = library.settings["ui.dpi"]
	end

	return self._private.dpi
end

-- Opacity
function ui:set_opacity(opacity)
	self._private.ui_opacity = opacity
	library.settings["ui.opacity"] = opacity
	beautiful.reload()
end

function ui:get_opacity()
	if self._private.ui_opacity == nil then
		self._private.ui_opacity = library.settings["ui.opacity"]
	end

	return self._private.ui_opacity
end

-- Border radius
function ui:set_border_radius(border_radius)
	self._private.ui_border_radius = border_radius
	library.settings["ui.border_radius"] = border_radius
	beautiful.reload()
end

function ui:get_border_radius()
	if self._private.ui_border_radius == nil then
		self._private.ui_border_radius = library.settings["ui.border_radius"]
	end

	return self._private.ui_border_radius
end

-- Useless gaps
function ui:set_useless_gap(useless_gap, save)
	if useless_gap < 0 then
		useless_gap = 0
	end

	for _, tag in ipairs(capi.root.tags()) do
		tag.gap = useless_gap
	end

	for screen in capi.screen do
		awful.layout.arrange(screen)
	end

	self._private.useless_gap = useless_gap
	self:emit_signal("useless_gap", useless_gap)
	if save ~= false then
		library.settings["layout.useless_gap"] = useless_gap
	end
end

function ui:get_useless_gap()
	if self._private.useless_gap == nil then
		self._private.useless_gap = library.settings["layout.useless_gap"]
	end

	return self._private.useless_gap
end

-- Client gaps
function ui:set_client_gap(client_gap, save)
	if client_gap < 0 then
		client_gap = 0
	end

	for screen in capi.screen do
		screen.padding = {
			left = client_gap,
			right = client_gap,
			top = client_gap,
			bottom = client_gap,
		}
		awful.layout.arrange(screen)
	end

	self._private.client_gap = client_gap
	self:emit_signal("client_gap", client_gap)
	if save ~= false then
		library.settings["layout.client_gap"] = client_gap
	end
end

function ui:get_client_gap()
	if self._private.client_gap == nil then
		self._private.client_gap = library.settings["layout.client_gap"]
	end

	return self._private.client_gap
end

-- Animations
function ui:set_animations(animations, save)
	library.animation:set_instant(not animations)

	if save ~= false then
		self._private.ui_animations = animations
		library.settings["ui.animations.enabled"] = animations
	end
end

function ui:get_animations()
	if self._private.ui_animations == nil then
		self._private.ui_animations = library.settings["ui.animations.enabled"]
	end

	return self._private.ui_animations
end

-- Animations Framerate
function ui:set_animations_framerate(framerate, save)
	library.animation:set_framerate(framerate)
	self._private.ui_animations_framerate = framerate

	if save ~= false then
		library.settings["ui.animations.framerate"] = framerate
	end
end

function ui:get_animations_framerate()
	if self._private.ui_animations_framerate == nil then
		self._private.ui_animations_framerate = library.settings["ui.animations.framerate"]
	end

	return self._private.ui_animations_framerate
end

-- Show lockscreen on login
function ui:set_show_lockscreen_on_login(show_lockscreen_on_login)
	self._private.show_lockscreen_on_login = show_lockscreen_on_login
	library.settings["ui.show_lockscreen_on_login"] = show_lockscreen_on_login
end

function ui:get_show_lockscreen_on_login()
	if self._private.show_lockscreen_on_login == nil then
		self._private.show_lockscreen_on_login = library.settings["ui.show_lockscreen_on_login"]
	end

	return self._private.show_lockscreen_on_login
end

-- Bars layout
function ui:set_bars_layout(bar_layout)
	self._private.bars_layout = bar_layout
	library.settings["ui.bar.layout"] = bar_layout
end

function ui:get_bars_layout()
	if self._private.bars_layout == nil then
		self._private.bars_layout = library.settings["ui.bar.layout"]
	end

	return self._private.bars_layout
end

-- Taglist type
function ui:set_taglist_type(taglist_type)
	self._private.taglist_type = taglist_type
	library.settings["ui.bar.taglist_type"] = taglist_type
end

function ui:get_taglist_type()
	if self._private.taglist_type == nil then
		self._private.taglist_type = library.settings["ui.bar.taglist_type"]
	end

	return self._private.taglist_type
end

-- Widget at center
function ui:set_widget_at_center(widget_at_center)
	self._private.widget_at_center = widget_at_center
	library.settings["ui.bar.widget_at_center"] = widget_at_center
end

function ui:get_widget_at_center()
	if self._private.widget_at_center == nil then
		self._private.widget_at_center = library.settings["ui.bar.widget_at_center"]
	end

	return self._private.widget_at_center
end

-- Horizontal bar position
function ui:set_horizontal_bar_position(horizontal_bar_position)
	self._private.horizontal_bar_position = horizontal_bar_position
	library.settings["ui.bar.horizontal_bar_position"] = horizontal_bar_position
end

function ui:get_horizontal_bar_position()
	if self._private.horizontal_bar_position == nil then
		self._private.horizontal_bar_position = library.settings["ui.bar.horizontal_bar_position"]
	end

	return self._private.horizontal_bar_position
end

local function new()
	local ret = gobject({})
	gtable.crush(ret, ui, true)

	ret._private = {}

	ret:set_useless_gap(ret:get_useless_gap(), false)
	ret:set_client_gap(ret:get_client_gap(), false)
	ret:set_animations(ret:get_animations(), false)
	ret:set_animations_framerate(ret:get_animations_framerate(), false)

	setup_profile_image(ret)

	return ret
end

if not instance then
	instance = new()
end
return instance
