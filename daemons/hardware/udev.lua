-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local gdebug = require("gears.debug")
local helpers = require("helpers")
local string = string
local ipairs = ipairs
local pairs = pairs

-- This seems to be common issue causing a crash, so make sure GUdev is available
local _gudev_status, GUdev = pcall(function()
    return require("lgi").GUdev
end)
if not _gudev_status or not GUdev then
    gdebug.print_warning(
        "Can't load GUdev introspection. "..
        "Seems like GUdev is not installed or `lua-lgi` was built with an incompatible GUdev version. " ..
        "USB notifications will not be available!"
    )
    return gobject {}
end

local udev = {}
local instance = nil

local function check_usb_device(self)
    local devices = self._private.client:query_by_subsystem("usb")

    local new_devices = {}
    for _, device in ipairs(devices) do
        if device:get_property("DEVTYPE") == "usb_device" then
            local vendor = device:get_property("ID_VENDOR"):gsub("_", " ")
            local name = device:get_property("ID_MODEL"):gsub("_", " ")
            if name ~= nil and vendor ~= nil then
                local device = {
                    name = name,
                    vendor = vendor
                }
                new_devices[device.name] = device
                if helpers.table.length(self._private.usb_devices) > 0 and self._private.usb_devices[device.name] == nil then
                    self:emit_signal("usb::added", device)
                end
            end
        end
    end

    for key, device in pairs(self._private.usb_devices) do
        if new_devices[key] == nil then
            self:emit_signal("usb::removed", device)
        end
    end

    self._private.usb_devices = new_devices
end

local function check_block_devices(self)
    awful.spawn.easy_async("findmnt --pairs", function(stdout)
        local new_devices = {}
        for line in stdout:gmatch("[^\r\n]+") do
            local partition = line:match('SOURCE="(.*)" FSTYPE')
            if partition ~= "tmpfs" and partition ~= "gvfsd-fuse" then
                local device = {}
                device.mount_point = line:match('TARGET="(.*)" SOURCE')
                device.name = string.sub(device.mount_point, helpers.string.find_last(device.mount_point, "/") + 1,
                    #device.mount_point)
                device.partition = line:match('SOURCE="(.*)" FSTYPE')
                device.fs_type = line:match('FSTYPE="(.*)" OPTIONS')
                device.options = line:match('OPTIONS=(.*)')
                new_devices[device.mount_point] = device

                if helpers.table.length(self._private.block_devices) > 0 and
                    self._private.block_devices[device.mount_point] == nil then
                    self:emit_signal("block::added", device)
                end
            end
        end

        for key, device in pairs(self._private.block_devices) do
            if new_devices[key] == nil then
                self:emit_signal("block::removed", device)
            end
        end

        self._private.block_devices = new_devices
    end)
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, udev, true)

    ret._private = {}
    ret._private.client = GUdev.Client()
    ret._private.usb_devices = {}
    ret._private.block_devices = {}

    awful.spawn.easy_async("pkill -f 'udevadm monitor'", function()
        awful.spawn.with_line_callback("udevadm monitor", {
            stdout = function(_)
                gtimer.start_new(0.5, function()
                    check_usb_device(ret)
                    check_block_devices(ret)
                    return false
                end)
            end
        })
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance
