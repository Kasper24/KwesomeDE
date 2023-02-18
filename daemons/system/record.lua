-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local helpers = require("helpers")
local string = string
local os = os

local record = {}
local instance = nil

function record:set_resolution(resolution)
    self._private.resolution = resolution
    helpers.settings:set_value("record-resolution", self._private.resolution)
end

function record:get_resolution()
    return self._private.resolution
end

function record:set_fps(fps)
    self._private.fps = fps
    helpers.settings:set_value("record-fps", self._private.fps)
end

function record:get_fps()
    return self._private.fps
end

function record:set_delay(delay)
    self._private.delay = delay
    helpers.settings:set_value("record-delay", self._private.delay)
end

function record:get_delay()
    return self._private.delay
end

function record:get_folder()
    return self._private.folder
end

function record:set_folder(folder)
    if folder then
        self._private.folder = folder
        helpers.settings:set_value("record-folder", folder)
    else
        awful.spawn.easy_async("yad --file --directory", function(stdout)
            for line in stdout:gmatch("[^\r\n]+") do
                if line ~= "" then
                    self._private.folder = line
                    helpers.settings:set_value("record-folder", line)
                    self:emit_signal("folder::updated", line)
                end
            end
        end)
    end
end

function record:get_format()
    return self._private.format
end

function record:set_format(format)
    self._private.format = format
    helpers.settings:set_value("record-format", self._private.format)
end

function record:set_audio_source(audio_source)
    self._private.audio_source = audio_source
end

function record:stop_video()
    awful.spawn.easy_async("killall ffmpeg", function()
        local file = helpers.file.new_for_path(self._private.folder .. self._private.file_name)
        file:exists(function(error, exists)
            if error == nil then
                if exists == false then
                    self:emit_signal("error::create_file", stderr)
                end
            end

            self._private.is_recording = false
            self:emit_signal("ended", self._private.folder, self._private.file_name)
        end)
    end)
end

function record:start_video()
    local function record()
        self._private.file_name = os.date("%d-%m-%Y-%H:%M:%S") .. "." .. self._private.format
        local command = string.format(
            "ffmpeg -video_size %s -framerate %d -f x11grab -i :0.0+0,0 -f pulse -i %s %s%s -c:v libx264 -profile:v main",
            self._private.resolution, self._private.fps, self._private.audio_source, self._private.folder,
            self._private.file_name)
        awful.spawn(command, false)
        self._private.is_recording = true
        self:emit_signal("started")
    end

    gtimer.start_new(self._private.delay, function()
        local folder = helpers.file.new_for_path(self._private.folder)
        folder:exists(function(error, exists)
            if exists == false then
                helpers.filesystem.make_directory(self._private.folder, function(error)
                    if error == nil then
                        record()
                    else
                        self:emit_signal("error::create_directory")
                    end
                end)
            else
                record()
            end
        end)

        return false
    end)
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
    local ret = gobject {}
    gtable.crush(ret, record, true)

    ret._private = {}

    ret._private.resolution = helpers.settings:get_value("record-resolution")
    ret._private.fps = helpers.settings:get_value("record-fps")
    ret._private.delay = helpers.settings:get_value("record-delay")
    ret._private.folder = helpers.settings:get_value("record-folder"):gsub("~", os.getenv("HOME"))
    ret._private.format = helpers.settings:get_value("record-format")

    ret._private.is_recording = false

    return ret
end

if not instance then
    instance = new()
end
return instance
