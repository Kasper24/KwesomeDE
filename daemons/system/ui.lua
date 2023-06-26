-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local beautiful = require("beautiful")
local helpers = require("helpers")
local filesystem = require("external.filesystem")
local ipairs = ipairs
local os = os
local capi = {
    root = root,
    screen = screen
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

-- Profile image
function ui:set_profile_image(profile_image)
    self._private.profile_image = profile_image
    helpers.settings["ui.profile_image"] = profile_image
    self:emit_signal("profile_image", profile_image)
end

function ui:get_profile_image()
    if self._private.profile_image == nil then
        self._private.profile_image = helpers.settings["ui.profile_image"]
    end

    return self._private.profile_image
end

-- DPI
function ui:set_dpi(dpi)
    self._private.dpi = dpi
    helpers.settings["ui.dpi"] = dpi
end

function ui:get_dpi()
    if self._private.dpi == nil then
        self._private.dpi = helpers.settings["ui.dpi"]
    end

    return self._private.dpi
end

-- Opacity
function ui:set_opacity(opacity)
    self._private.ui_opacity = opacity
    helpers.settings["ui.opacity"] = opacity
    beautiful.reload()
end

function ui:get_opacity()
    if self._private.ui_opacity == nil then
        self._private.ui_opacity = helpers.settings["ui.opacity"]
    end

    return self._private.ui_opacity
end

-- Border radius
function ui:set_border_radius(border_radius)
    self._private.ui_border_radius = border_radius
    helpers.settings["ui.border_radius"] = border_radius
    beautiful.reload()
end

function ui:get_border_radius()
    if self._private.ui_border_radius == nil then
        self._private.ui_border_radius = helpers.settings["ui.border_radius"]
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
        helpers.settings["layout.useless_gap"] = useless_gap
    end
end

function ui:get_useless_gap()
    if self._private.useless_gap == nil then
        self._private.useless_gap = helpers.settings["layout.useless_gap"]
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
            bottom = client_gap
        }
        awful.layout.arrange(screen)
    end

    self._private.client_gap = client_gap
    self:emit_signal("client_gap", client_gap)
    if save ~= false then
        helpers.settings["layout.client_gap"] = client_gap
    end
end

function ui:get_client_gap()
    if self._private.client_gap == nil then
        self._private.client_gap = helpers.settings["layout.client_gap"]
    end

    return self._private.client_gap
end

-- Animations
function ui:set_animations(animations, save)
    helpers.animation:set_instant(not animations)

    if save ~= false then
        self._private.ui_animations = animations
        helpers.settings["ui.animations.enabled"] = animations
    end
end

function ui:get_animations()
    if self._private.ui_animations == nil then
        self._private.ui_animations = helpers.settings["ui.animations.enabled"]
    end

    return self._private.ui_animations
end

-- Animations Framerate
function ui:set_animations_framerate(framerate, save)
    helpers.animation:set_framerate(framerate)
    self._private.ui_animations_framerate = framerate

    if save ~= false then
        helpers.settings["ui.animations.framerate"] = framerate
    end
end

function ui:get_animations_framerate()
    if self._private.ui_animations_framerate == nil then
        self._private.ui_animations_framerate = helpers.settings["ui.animations.framerate"]
    end

    return self._private.ui_animations_framerate
end

-- Show lockscreen on login
function ui:set_show_lockscreen_on_login(show_lockscreen_on_login)
    self._private.show_lockscreen_on_login = show_lockscreen_on_login
    helpers.settings["ui.show_lockscreen_on_login"] = show_lockscreen_on_login
end

function ui:get_show_lockscreen_on_login()
    if self._private.show_lockscreen_on_login == nil then
        self._private.show_lockscreen_on_login = helpers.settings["ui.show_lockscreen_on_login"]
    end

    return self._private.show_lockscreen_on_login
end

-- Double bars
function ui:set_double_bars(double_bars)
    self._private.double_bars = double_bars
    helpers.settings["ui.bar.double_bars"] = double_bars
end

function ui:get_double_bars()
    if self._private.double_bars == nil then
        self._private.double_bars = helpers.settings["ui.bar.double_bars"]
    end

    return self._private.double_bars
end

-- Icon taglist
function ui:set_icon_taglist(icon_taglist)
    self._private.icon_taglist = icon_taglist
    helpers.settings["ui.bar.icon_taglist"] = icon_taglist
end

function ui:get_icon_taglist()
    if self._private.icon_taglist == nil then
        self._private.icon_taglist = helpers.settings["ui.bar.icon_taglist"]
    end

    return self._private.icon_taglist
end

local function new()
    local ret = gobject {}
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
