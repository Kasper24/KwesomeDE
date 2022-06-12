-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local settings = require("services.settings")
local helpers = require("helpers")
local string = string
local os = os

local record = { }
local instance = nil

function record:set_resolution(resolution)
    self._private.resolution = resolution
    settings:set_value("record.resolution", self._private.resolution)
end

function record:get_resolution()
    return self._private.resolution
end

function record:increase_fps()
    self._private.fps = self._private.fps + 1
    settings:set_value("record.fps", self._private.fps)
    return self:get_fps()
end

function record:decrease_fps()
    if self._private.fps > 0 then
        self._private.fps = self._private.fps - 1
        settings:set_value("record.fps", self._private.fps)
    end
    return self:get_fps()
end

function record:get_fps()
    return self._private.fps
end

function record:get_delay()
    return self._private.delay
end

function record:increase_delay()
    self._private.delay = self._private.delay + 1
    settings:set_value("record.delay", self._private.delay)
    return self:get_delay()
end

function record:decrease_delay()
    if self._private.delay > 0 then
        self._private.delay = self._private.delay - 1
        settings:set_value("record.delay", self._private.delay)
    end
    return self:get_delay()
end

function record:get_folder()
    return self._private.folder
end

function record:set_folder()
    awful.spawn.easy_async("yad --file --directory", function(stdout)
        for line in stdout:gmatch("[^\r\n]+") do
            if line ~= "" then
                self._private.folder = line
                settings:set_value("record.folder", line)
                self:emit_signal("folder::updated", line)
            end
        end
    end)
end

function record:get_format()
    return self._private.format
end

function record:set_format(format)
    self._private.format = format
    settings:set_value("record.format", self._private.format)
end

function record:set_audio_source(audio_source)
    self._private.audio_source = audio_source
end

function record:stop_video()
    awful.spawn("killall ffmpeg", false)
    self._private.is_recording = false
    self:emit_signal("ended", self._private.folder, self._private.file_name)
end

function record:start_video()
    gtimer {
        timeout = self._private.delay,
        single_shot = true,
        autostart = true,
        call_now = false,
        callback = function()
            helpers.filesystem.make_directory(self._private.folder, function(result)
                if result == true then
                    self._private.file_name = os.date("%d-%m-%Y-%H:%M:%S") .. "." .. self._private.format
                    local command = string.format("ffmpeg -video_size %s -framerate %d -f x11grab -i :0.0+0,0 -f pulse -i %s %s%s -c:v libx264 -profile:v main",
                            self._private.resolution, self._private.fps, self._private.audio_source, self._private.folder, self._private.file_name)
                    awful.spawn(command, false)
                    self._private.is_recording = true
                    self:emit_signal("started")
                else
                    self:emit_signal("error::create_directory")
                end
            end)
        end
    }
end

function record:toggle_video()
    if self:get_is_recording() == true then
        self:stop_video()
    else
        self:start_video()
    end
end

function record:get_is_recording()
    return self._private.is_recording
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, record, true)

    ret._private = {}

    ret._private.resolution = settings:get_value("record.resolution") or "1920x1080"
    ret._private.fps = settings:get_value("record.fps") or 60
    ret._private.delay = settings:get_value("record.delay") or 0
    ret._private.show_cursor = settings:get_value("record.show_cursor") or false
    ret._private.folder = settings:get_value("record.folder") or
                                "/home/" .. os.getenv("USER") .. "/Recordings/"
    ret._private.format = settings:get_value("record.format") or "mp4"

    ret._private.is_recording = false

    return ret
end

if not instance then
    instance = new()
end
return instance