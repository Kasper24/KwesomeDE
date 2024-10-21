-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local library = require("library")
local dbus_proxy = require("external.dbus_proxy")
local string = string
local pairs = pairs

local udisks = {}
local instance = nil

local function check_mounts(self)
    awful.spawn.easy_async("findmnt --pairs", function(stdout)
        local new_devices = {}
        for line in stdout:gmatch("[^\r\n]+") do
            local partition = line:match('SOURCE="(.*)" FSTYPE')
            if partition ~= "tmpfs" and partition ~= "gvfsd-fuse" then
                local device = {}
                device.mount_point = line:match('TARGET="(.*)" SOURCE')
                device.name = string.sub(device.mount_point, library.string.find_last(device.mount_point, "/") + 1,
                    #device.mount_point)
                device.partition = line:match('SOURCE="(.*)" FSTYPE')
                device.fs_type = line:match('FSTYPE="(.*)" OPTIONS')
                device.options = line:match('OPTIONS=(.*)')
                new_devices[device.mount_point] = device

                if gtable.count_keys(self._private.mounts) > 0 and
                    self._private.mounts[device.mount_point] == nil then
                    self:emit_signal("mount::added", device)
                end
            end
        end

        for key, device in pairs(self._private.mounts) do
            if new_devices[key] == nil then
                self:emit_signal("mount::removed", device)
            end
        end

        self._private.mounts = new_devices
    end)
end

local function example()
    -- Disonncect:
    -- VolumeChanged
    -- DriveDisconnected
    -- VolumeRemoved

    -- Connect:
    -- DriveChanged
    -- DriveConnected
    -- VolumeAdded

    -- Mount:
    -- VolumeChanged
    -- MountAdded
    -- VolumeChanged

    -- Disconnect after mount:
    -- VolumeChanged
    -- MountChanged
    -- DriveDisconnected
    -- VolumeRemoved
    -- MountRemoved

    -- Safely remove:
    -- MountPreUnmount

    -- Eject:
    -- VolumeChanged
    -- MountChanged
    -- MountRemoved
    -- VolumeChanged
    -- DriveChanged
    -- VolumeRemoved

    -- volume_monitor_proxy:connect_signal("DriveChanged", function(self, _, __, mount)
    --     print("DriveChanged")
    -- end)
    -- volume_monitor_proxy:connect_signal("DriveConnected", function(self, _, __, mount)
    --     print("DriveConnected")
    -- end)
    -- volume_monitor_proxy:connect_signal("DriveDisconnected", function(self, _, __, mount)
    --     print("DriveDisconnected")
    -- end)
    -- volume_monitor_proxy:connect_signal("DriveEjectButton", function(self, _, __, mount)
    --     print("DriveEjectButton")
    -- end)
    -- volume_monitor_proxy:connect_signal("DriveStopButton", function(self, _, __, mount)
    --     print("DriveStopButton")
    -- end)
    -- volume_monitor_proxy:connect_signal("MountAdded", function(self, _, __, mount)
    --     print("MountAdded")
    -- end)
    -- volume_monitor_proxy:connect_signal("MountChanged", function(self, _, __, mount)
    --     print("MountChanged")
    -- end)
    -- volume_monitor_proxy:connect_signal("MountPreUnmount", function(self, _, __, mount)
    --     print("MountPreUnmount")
    -- end)
    -- volume_monitor_proxy:connect_signal("MountRemoved", function(self, _, __, mount)
    --     print("MountRemoved")
    -- end)
    -- volume_monitor_proxy:connect_signal("VolumeAdded", function(self, _, __, mount)
    --     print("VolumeAdded")
    -- end)
    -- volume_monitor_proxy:connect_signal("VolumeChanged", function(self, _, __, mount)
    --     print("VolumeChanged")
    -- end)
    -- volume_monitor_proxy:connect_signal("VolumeRemoved", function(self, _, __, mount)
    --     print("VolumeRemoved")
    -- end)
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, udisks, true)

    ret._private = {}
    ret._private.mounts = {}

    local volume_monitor_proxy = dbus_proxy.Proxy:new{
        bus = dbus_proxy.Bus.SESSION,
        name = "org.gtk.vfs.UDisks2VolumeMonitor",
        interface = "org.gtk.Private.RemoteVolumeMonitor",
        path = "/org/gtk/Private/RemoteVolumeMonitor"
    }

    volume_monitor_proxy:connect_signal("MountAdded", function(self, _, __, mount)
        ret:emit_signal("mount::added", mount[2], mount[6]:gsub("file://", ""))
    end)

    volume_monitor_proxy:connect_signal("MountRemoved", function(self, _, __, mount)
        ret:emit_signal("mount::removed", mount[2], mount[6]:gsub("file://", ""))
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance
