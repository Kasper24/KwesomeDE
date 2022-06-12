-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local inotify = require("services.inotify")
local settings = require("services.settings")
local helpers = require("helpers")
local tonumber = tonumber
local string = string
local capi = { awesome = awesome }

local picom = { }
local instance = nil

local CONFIG_PATH = helpers.filesystem.get_awesome_config_dir("config") .. "picom.conf"
local UPDATE_INTERVAL = 1

function picom:turn_on(save)
    helpers.run.check_if_running("picom --experimental-backends", nil,
    function()
        awful.spawn("picom --experimental-backends --config " .. CONFIG_PATH, false)
        if save == true then
            settings:set_value("picom", true)
        end
    end)
end

function picom:turn_off(save)
    helpers.run.check_if_running("picom --experimental-backends", function()
        awful.spawn("pkill -f 'picom --experimental-backends'", false)
        if save == true then
            settings:set_value("picom", false)
        end
    end, nil)
end

function picom:toggle(save)
    helpers.run.check_if_running("picom --experimental-backends", function()
        self:turn_off(save)
    end,
    function()
        self:turn_on(save)
    end)
end

function picom:set_active_opacity(active_opacity)
    awful.spawn.with_shell(string.format("sed -i 's/.*active-opacity = .*/    active-opacity = %d;/g' \\%s", active_opacity, CONFIG_PATH))
end

function picom:set_inactive_opacity(inactive_opacity)
    awful.spawn.with_shell(string.format("sed -i 's/.*inactive-opacity = .*/    inactive-opacity = %d;/g' \\%s", inactive_opacity, CONFIG_PATH))
end

function picom:set_frame_opacity(frame_opacity)
    awful.spawn.with_shell(string.format("sed -i 's/.*frame-opacity = .*/    frame-opacity = %d;/g' \\%s", frame_opacity, CONFIG_PATH))
end

function picom:set_corner_radius(corner_radius)
    awful.spawn.with_shell(string.format("sed -i 's/.*corner-radius = .*/    corner-radius = %d;/g' \\%s", corner_radius, CONFIG_PATH))
end

function picom:set_blur(blur)
    awful.spawn.with_shell(string.format("sed -i 's/.*strength = .*/    strength = %d;/g' \\%s", blur, CONFIG_PATH))
end

local function get_settings(self)
    helpers.filesystem.read_file(CONFIG_PATH, function(stdout)
        stdout = stdout:gsub("%s+", "")
        local active_opacity = stdout:match("active%-opacity=(%d+.%d+)") or stdout:match("active%-opacity=(%d+)")
        local inactive_opacity = stdout:match("inactive%-opacity=(%d+.%d+)") or stdout:match("inactive%-opacity=(%d+)")
        local frame_opacity = stdout:match("frame%-opacity=(%d+.%d+)") or stdout:match("frame%-opacity=(%d+)")
        local corner_radius = stdout:match("corner%-radius=(%d+.%d+)") or stdout:match("corner%-radius=(%d+)")
        local blur = stdout:match("strength=(%d+.%d+)") or stdout:match("strength=(%d+)")

        self:emit_signal("settings", tonumber(active_opacity), tonumber(inactive_opacity),
            tonumber(frame_opacity), tonumber(corner_radius), tonumber(blur))
    end)
end

local function get_is_running(self)
    if self._private.state ~= capi.awesome.composite_manager_running then
        self:emit_signal("state", capi.awesome.composite_manager_running)
        self._private.state = capi.awesome.composite_manager_running
    end
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, picom, true)

    ret._private = {}
    ret._private.state = -1

    gtimer.delayed_call(function()
        get_settings(ret)

        local watcher = inotify:watch(CONFIG_PATH,
        {
            inotify.Events.modify
        })

        watcher:connect_signal("event", function(_, __, __)
            get_settings(ret)

            -- Try to turn picom back on if it crashed from incorrect setting
            if settings:get_value("picom") == true then
                ret:turn_on()
            end
        end)

        if settings:get_value("picom") == true then
            ret:turn_on()
        elseif settings:get_value("picom") == false then
            ret:turn_off()
        end

        gtimer { timeout = UPDATE_INTERVAL, autostart = true, call_now = true, callback = function()
            get_is_running(ret)
        end}
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance