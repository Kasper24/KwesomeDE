-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local gmath = require("gears.math")
local tonumber = tonumber
local string = string
local pairs = pairs

local audio = {}

local sink = {}
local source = {}

local sink_input = {}
local source_output = {}

local instance = nil

function audio:set_default_sink(id)
    awful.spawn(string.format("pactl set-default-sink %d", id), false)
end

function audio:set_default_source(id)
    awful.spawn(string.format("pactl set-default-source %d", id), false)
end

function audio:get_sinks()
    return self._private.sinks
end

function audio:get_sources()
    return self._private.sources
end

function audio:get_default_sink()
    for _, sink in pairs(self:get_sinks()) do
        if sink.default then
            return sink
        end
    end
end

function audio:get_default_source()
    for _, source in pairs(self:get_sources()) do
        if source.default then
            return source
        end
    end
end

function sink:toggle_mute()
    awful.spawn(string.format("pactl set-sink-mute %d toggle", self.id), false)
end

function sink:volume_up(step)
    if self.description == "GSX 1000 Main Audio analog-output-surround71" then
        return
    end

    awful.spawn(string.format("pactl set-sink-volume %d +%d%%", self.id, step), false)
end

function sink:volume_down(step)
    if self.description == "GSX 1000 Main Audio analog-output-surround71" then
        return
    end

    awful.spawn(string.format("pactl set-sink-volume %d -%d%%", self.id, step), false)
end

function sink:set_volume(volume)
    volume = gmath.round(volume)
    awful.spawn(string.format("pactl set-sink-volume %d %d%%", self.id, volume), false)
end

function source:toggle_mute()
    awful.spawn(string.format("pactl set-source-mute %d toggle", self.id), false)
end

function source:volume_up(step)
    awful.spawn(string.format("pactl set-source-volume %d +%d%%", self.id, step), false)
end

function source:volume_down(step)
    awful.spawn(string.format("pactl set-source-volume %d -%d%%", self.id, step), false)
end

function source:set_volume(volume)
    volume = gmath.round(volume)
    awful.spawn(string.format("pactl set-source-volume %d %d%%", self.id, volume), false)
end

function sink_input:toggle_mute()
    awful.spawn(string.format("pactl set-sink-input-mute %d toggle", self.id), false)
end

function sink_input:set_volume(volume)
    volume = gmath.round(volume)
    awful.spawn(string.format("pactl set-sink-input-volume %d %d%%", self.id, volume), false)
end

function source_output:toggle_mute()
    awful.spawn(string.format("pactl set-source-output-mute %d toggle", self.id), false)
end

function source_output:set_volume(volume)
    volume = gmath.round(volume)
    awful.spawn(string.format("pactl set-source-output-volume %d %d%%", self.id, volume), false)
end

local function on_default_device_changed(self)
    awful.spawn.easy_async_with_shell([[pactl info | grep "Default Sink:\|Default Source:"]], function(stdout)
        for line in stdout:gmatch("[^\r\n]+") do
            local default_device_name = line:match(": (.*)")
            local type = line:match("Default Sink") and "sinks" or "sources"
            for _, device in pairs(self._private[type]) do
                if device.name == default_device_name then
                    if device.default == false then
                        device.default = true
                        self:emit_signal(type .. "::default", device)
                    end
                else
                    device.default = false
                end
                device:emit_signal("updated")
            end
        end
    end)
end

local function get_devices(self)
    awful.spawn.easy_async_with_shell([[pactl list sinks | grep "Sink #\|Name:\|Description:\|Mute:\|Volume: ";
        pactl list sources | grep "Source #\|Name:\|Description:\|Mute:\|Volume:"]], function(stdout)
        local device = gobject {}
        for line in stdout:gmatch("[^\r\n]+") do
            if line:match("Sink") or line:match("Source") then
                device = gobject {}
                device.id = line:match("#(%d+)")
                device.type = line:match("Sink") and "sinks" or "sources"
                device.default = false
                gtable.crush(device, device.type == "sinks" and sink or source, true)
            elseif line:match("Name") then
                device.name = line:match(": (.*)")
            elseif line:match("Description") then
                device.description = line:match(": (.*)")
            elseif line:match("Mute") then
                device.mute = line:match(": (.*)") == "yes" and true or false
            elseif line:match("Volume") then
                device.volume = tonumber(line:match("(%d+)%%"))

                if self._private[device.type][device.id] == nil then
                    self:emit_signal(device.type .. "::added", device)
                    self._private[device.type][device.id] = device
                end
            end
        end

        on_default_device_changed(self)
    end)
end

local function get_applications(self)
    awful.spawn.easy_async_with_shell(
        [[pactl list sink-inputs | grep "Sink Input #\|application.name = \|application.icon_name = \|Mute:\|Volume: ";
        pactl list source-outputs | grep "Source Output #\|application.name = \|application.icon_name = \|Mute:\|Volume: "]],
        function(stdout)
            local application = gobject {}
            local new_application = nil

            for line in stdout:gmatch("[^\r\n]+") do
                if line:match("Sink Input") or line:match("Source Output") then
                    local id = line:match("#(%d+)")
                    local type = line:match("Sink Input") and "sink_inputs" or "source_outputs"
                    application = self._private[type][id]
                    new_application = application == nil
                    if new_application then
                        application = gobject {}
                        application.id = id
                        application.type = type
                        gtable.crush(application, application.type == "sink_inputs" and sink_input or source_output, true)
                    elseif application.makred_to_remove then
                        return
                    end
                elseif line:match("Mute") then
                    application.mute = line:match(": (.*)") == "yes" and true or false
                elseif line:match("Volume") then
                    application.volume = tonumber(line:match("(%d+)%%"))
                elseif line:match("application.name") then
                    application.name = line:match(" = (.*)"):gsub('"', "")
                    if new_application then
                        self:emit_signal(application.type .. "::added", application)
                        self._private[application.type][application.id] = application
                    else
                        application:emit_signal("updated")
                    end
                elseif line:match("application.icon_name") then
                    application.icon_name = line:match(" = (.*)"):gsub('"', "")
                    application:emit_signal("icon_name")
                end
            end
        end)
end

local function on_object_removed(self, type, id)
    -- get_applications is an async function, some object might get added and removed very quickly
    -- sink_inputs are  primiarlay prone to this, so we might get a remove event before the object was initialized
    if self._private[type][id] == nil then
        self._private[type][id] = {}
        self._private[type][id].makred_to_remove = true
    else
        self:emit_signal(type .. "::removed", self._private[type][id])
        self._private[type][id] = nil
    end
end

local function on_device_updated(self, type, id)
    if self._private[type][id] == nil then
        get_devices(self)
        return
    end

    local type_no_s = type:sub(1, -2)

    awful.spawn.easy_async_with_shell(string.format("pactl get-%s-volume %s; pactl get-%s-mute %s", type_no_s, id,
        type_no_s, id), function(stdout)
        local was_there_any_change = false

        for line in stdout:gmatch("[^\r\n]+") do
            if line:match("Volume") then
                local volume = tonumber(line:match("(%d+)%%"))
                if volume ~= self._private[type][id].volume then
                    was_there_any_change = true
                end
                self._private[type][id].volume = volume
            elseif line:match("Mute") then
                local mute = line:match(": (.*)") == "yes" and true or false
                if mute ~= self._private[type][id].mute then
                    was_there_any_change = true
                end
                self._private[type][id].mute = mute
            end
        end

        if was_there_any_change == true then
            self._private[type][id]:emit_signal("updated")
            if self._private[type][id].default == true then
                self:emit_signal(type .. "::default", self._private[type][id])
            end
        end
    end)
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, audio, true)

    ret._private = {}
    ret._private.sinks = {}
    ret._private.sources = {}
    ret._private.sink_inputs = {}
    ret._private.source_outputs = {}

    gtimer.start_new(5, function()
        get_devices(ret)
        get_applications(ret)

        awful.spawn.easy_async("pkill -f 'pactl subscribe'", function()
            awful.spawn.with_line_callback("pactl subscribe", {
                stdout = function(line)
                    ---------------------------------------------------------------------------------------------------------
                    -- Devices
                    ---------------------------------------------------------------------------------------------------------
                    if line:match("Event 'new' on sink #") or line:match("Event 'new' on source #") then
                        get_devices(ret)
                    elseif line:match("Event 'remove' on sink #") then
                        local id = line:match("Event 'remove' on sink #(.*)")
                        on_object_removed(ret, "sinks", id)
                    elseif line:match("Event 'remove' on source #") then
                        local id = line:match("Event 'remove' on source #(.*)")
                        on_object_removed(ret, "sources", id)
                    elseif line:match("Event 'change' on server") then
                        on_default_device_changed(ret)
                    elseif line:match("Event 'change' on sink #") then
                        local id = line:match("Event 'change' on sink #(.*)")
                        on_device_updated(ret, "sinks", id)
                    elseif line:match("Event 'change' on source #") then
                        local id = line:match("Event 'change' on source #(.*)")
                        on_device_updated(ret, "sources", id)

                    ---------------------------------------------------------------------------------------------------------
                    -- Applications
                    ---------------------------------------------------------------------------------------------------------
                    elseif line:match("Event 'new' on sink%-input #") or
                        line:match("Event 'new' on source%-input #") then
                        get_applications(ret)
                    elseif line:match("Event 'change' on sink%-input #") then
                        get_applications(ret)
                    elseif line:match("Event 'change' on source%-output #") then
                        get_applications(ret)
                    elseif line:match("Event 'remove' on sink%-input #") then
                        local id = line:match("Event 'remove' on sink%-input #(.*)")
                        on_object_removed(ret, "sink_inputs", id)
                    elseif line:match("Event 'remove' on source%-output #") then
                        local id = line:match("Event 'remove' on source%-output #(.*)")
                        on_object_removed(ret, "source_outputs", id)
                    end
                end
            })
        end)

        return false
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance

-- -- print(filesystem.filesystem.get_awesome_config_dir("external"))
-- package.cpath = package.cpath .. ";" .. filesystem.filesystem.get_awesome_config_dir("external") .. "?.so;"
-- -- print(package.cpath)

-- pulseaudio = require("pulseaudio")
