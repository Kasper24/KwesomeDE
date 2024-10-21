-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gdebug = require("gears.debug")
local ipairs = ipairs
local pairs = pairs

local _gusb_status, GUsb = pcall(function()
    return require("lgi").GUsb
end)
if not _gusb_status or not GUsb then
    gdebug.print_warning(
        "Can't load GUsb introspection. "..
        "Seems like GUsb is not installed or `lua-lgi` was built with an incompatible GUsb version. " ..
        "USB notifications will not be available!"
    )
    return gobject {}
end

local usb = {}
local instance = nil

local function check_usb_device_gudev(self)
    local devices = self._private.gudev_client:query_by_subsystem("usb")

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
                if gtable.count_keys(self._private.usb_devices) > 0 and self._private.usb_devices[device.name] == nil then
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

local function check_usb_device_shell(self)
    awful.spawn.easy_async_with_shell("lsusb -v | grep -e 'iManufacturer' -e 'iProduct'", function(stdout)
        local new_devices = {}
        local device = {}
        for line in stdout:gmatch("[^\r\n]+") do
            if line:match("iManufacturer") then
                device = {}
                device.vendor = line:match("iManufacturer%s+%d+%s+([^\n]*)")
            elseif line:match("iProduct") then
                device.name = line:match("iProduct%s+%d+%s+([^\n]*)")
                new_devices[device.name] = device

                if gtable.count_keys(self._private.usb_devices) > 0 and self._private.usb_devices[device.name] == nil then
                    self:emit_signal("usb::added", device)
                end
            end
        end

        for key, device in pairs(self._private.usb_devices) do
            if new_devices[key] == nil then
                self:emit_signal("usb::removed", device)
            end
        end

        self._private.usb_devices = new_devices
    end)
end

local function check_usb_device(self)
    if self._private.gudev_client then
        check_usb_device_gudev(self)
    else
        check_usb_device_shell(self)
    end
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, usb, true)

    ret._private = {}
    ret._private.usb_devices = {}

    local _gudev_status, GUdev = pcall(function()
        return require("lgi").GUdev
    end)
    if not _gudev_status or not GUdev then
        gdebug.print_warning(
            "Can't load GUdev introspection. "..
            "Seems like GUdev is not installed or `lua-lgi` was built with an incompatible GUdev version. " ..
            "Using shell commands instead!"
        )
    else
        ret._private.gudev_client = GUdev.Client.new()
    end

    local deivce_context = GUsb.Context.new()
    deivce_context:enumerate()
    deivce_context.on_device_added = function(context, device)
        -- Get pid/vid_as_str() is not working, so gotta get it via shell
        check_usb_device(ret)
    end
    deivce_context.on_device_removed = function(context, device)
        -- Get pid/vid_as_str() is not working, so gotta get it via shell
        check_usb_device(ret)
    end

    check_usb_device(ret)

    return ret
end

if not instance then
    instance = new()
end
return instance
