-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local lgi = require("lgi")
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local dbus_proxy = require("external.dbus_proxy")
local pairs = pairs

local bluetooth = {}
local device = {}

local instance = nil

function bluetooth:toggle()
    local is_powered = self._private.adapter_proxy.Powered

    self._private.adapter_proxy:Set("org.bluez.Adapter1", "Powered", lgi.GLib.Variant("b", not is_powered))
    self._private.adapter_proxy.Powered = {
        signature = "b",
        value = not is_powered
    }
end

function bluetooth:open_settings()
    awful.spawn("blueman-manager", false)
end

function bluetooth:scan()
    self._private.adapter_proxy:StartDiscovery()
end

function device:toggle_connect()
    if self.Connected == true then
        self:DisconnectAsync()
    else
        self:ConnectAsync()
    end
end

function device:toggle_trust()
    local is_trusted = self.Trusted
    self:Set("org.bluez.Device1", "Trusted", lgi.GLib.Variant("b", not is_trusted))
    self.Trusted = {
        signature = "b",
        value = not is_trusted
    }
end

function device:toggle_pair()
    if self.Paired == true then
        self:PairAsync()
    else
        self:CancelPairingAsync()
    end
end

function device:is_connected()
    return self.Connected
end

function device:is_paired()
    return self.Paired
end

function device:is_trusted()
    return self.Trusted
end

function device:get_name()
    return self.Name
end

function device:get_icon()
    return self.Icon
end

local function get_device_info(self, object_path)
    if object_path ~= nil and object_path:match("/org/bluez/hci0/dev") then
        local device_proxy = dbus_proxy.Proxy:new{
            bus = dbus_proxy.Bus.SYSTEM,
            name = "org.bluez",
            interface = "org.bluez.Device1",
            path = object_path
        }

        local device_properties_proxy = dbus_proxy.Proxy:new{
            bus = dbus_proxy.Bus.SYSTEM,
            name = "org.bluez",
            interface = "org.freedesktop.DBus.Properties",
            path = object_path
        }

        if device_proxy.Name ~= "" and device_proxy.Name ~= nil then
            device_properties_proxy:connect_signal("PropertiesChanged", function(_, __, changed_properties)
                for key, _ in pairs(changed_properties) do
                    if key == "Connected" or key == "Paired" or key == "Trusted" then
                        self:emit_signal("device_event", key, device_proxy)
                    end
                end

                self:emit_signal(object_path .. "_updated", device_proxy)
            end)

            gtable.crush(device_proxy, device, true)

            self:emit_signal("new_device", device_proxy, object_path)
        end
    end
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, bluetooth, true)

    ret._private = {}

    ret._private.object_manager_proxy = dbus_proxy.Proxy:new{
        bus = dbus_proxy.Bus.SYSTEM,
        name = "org.bluez",
        interface = "org.freedesktop.DBus.ObjectManager",
        path = "/"
    }

    ret._private.adapter_proxy = dbus_proxy.Proxy:new{
        bus = dbus_proxy.Bus.SYSTEM,
        name = "org.bluez",
        interface = "org.bluez.Adapter1",
        path = "/org/bluez/hci0"
    }

    ret._private.adapter_proxy_properties = dbus_proxy.Proxy:new{
        bus = dbus_proxy.Bus.SYSTEM,
        name = "org.bluez",
        interface = "org.freedesktop.DBus.Properties",
        path = "/org/bluez/hci0"
    }

    ret._private.object_manager_proxy:connect_signal("InterfacesAdded", function(self, interface, data)
        get_device_info(ret, interface)
    end)

    ret._private.object_manager_proxy:connect_signal("InterfacesRemoved", function(self, interface, data)
        if interface ~= nil then
            ret:emit_signal(interface .. "_removed")
        end
    end)

    ret._private.adapter_proxy_properties:connect_signal("PropertiesChanged", function(self, interface, data)
        if data.Powered ~= nil then
            ret:emit_signal("state", data.Powered)

            if data.Powered == true then
                ret:scan()
            end
        end
    end)

    gtimer.delayed_call(function()
        local objects = ret._private.object_manager_proxy:GetManagedObjects()
        for object_path, _ in pairs(objects) do
            get_device_info(ret, object_path)
        end
        ret:emit_signal("state", ret._private.adapter_proxy.Powered)
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance
