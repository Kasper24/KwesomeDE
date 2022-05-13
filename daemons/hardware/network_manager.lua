local lgi = require("lgi")
local NM = lgi.NM
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local helpers = require("helpers")
local dbus_proxy = require("services.dbus_proxy")
local ipairs = ipairs
local string = string
local table = table
local math = math

local network_manager = { }
local instance = nil

local DeviceType =
{
    ETHERNET = 1,
    WIFI = 2
}

local DeviceState =
{
    UNKNOWN = 0, -- the device's state is unknown
    UNMANAGED = 10, -- the device is recognized, but not managed by NetworkManager
    UNAVAILABLE = 20, --the device is managed by NetworkManager,
    --but is not available for use. Reasons may include the wireless switched off,
    --missing firmware, no ethernet carrier, missing supplicant or modem manager, etc.
    DISCONNECTED = 30, -- the device can be activated,
    --but is currently idle and not connected to a network.
    PREPARE = 40, -- the device is preparing the connection to the network.
    -- This may include operations like changing the MAC address,
    -- setting physical link properties, and anything else required
    -- to connect to the requested network.
    CONFIG = 50, -- the device is connecting to the requested network.
    -- This may include operations like associating with the Wi-Fi AP,
    -- dialing the modem, connecting to the remote Bluetooth device, etc.
    NEED_AUTH = 60, -- the device requires more information to continue
    -- connecting to the requested network. This includes secrets like WiFi passphrases,
    -- login passwords, PIN codes, etc.
    IP_CONFIG = 70, -- the device is requesting IPv4 and/or IPv6 addresses
    -- and routing information from the network.
    IP_CHECK = 80, -- the device is checking whether further action
    -- is required for the requested network connection.
    -- This may include checking whether only local network access is available,
    -- whether a captive portal is blocking access to the Internet, etc.
    SECONDARIES = 90, -- the device is waiting for a secondary connection
    -- (like a VPN) which must activated before the device can be activated
    ACTIVATED = 100, -- the device has a network connection, either local or global.
    DEACTIVATING = 110, -- a disconnection from the current network connection
    -- was requested, and the device is cleaning up resources used for that connection.
    -- The network connection may still be valid.
    FAILED = 120 -- the device failed to connect to
    -- the requested network and is cleaning up the connection request
}

local DeviceStateReason =
{
    NEW_ACTIVATION = 60 -- New connection activation was enqueued
}

local function flags_to_security(flags, wpa_flags, rsn_flags)
    local str = ""
    if flags == 1 and wpa_flags == 0 and rsn_flags == 0 then
      str = str .. " WEP"
    end
    if wpa_flags ~= 0 then
      str = str .. " WPA1"
    end
    if not rsn_flags ~= 0 then
      str = str .. " WPA2"
    end
    if wpa_flags == 512 or rsn_flags == 512 then
      str = str .. " 802.1X"
    end

    return (str:gsub( "^%s", ""))
end

local function generate_uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    local uuid = string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
    return uuid
end

local function create_profile(access_point, password, auto_connect)
    local profile = NM.SimpleConnection.new()

    local s_con = NM.SettingConnection.new()
    s_con[NM.SETTING_CONNECTION_ID] = access_point.ssid
    s_con[NM.SETTING_CONNECTION_UUID] = generate_uuid()
    s_con[NM.SETTING_CONNECTION_TYPE] = "802-11-wireless"
    s_con[NM.SETTING_CONNECTION_AUTOCONNECT] = auto_connect
    profile:add_setting(s_con)

    local s_wifi = NM.SettingWireless.new()
    s_wifi[NM.SETTING_WIRELESS_SSID] = access_point.raw_ssid()
    s_wifi[NM.SETTING_WIRELESS_MODE] = "infrastructure"
    s_wifi[NM.SETTING_WIRELESS_MAC_ADDRESS] = access_point.device:get_permanent_hw_address()
    profile:add_setting(s_wifi)

    local s_ip4 = NM.SettingIP4Config.new()
    s_ip4[NM.SETTING_IP_CONFIG_METHOD] = "auto"
    profile:add_setting(s_ip4)

    local s_ip6 = NM.SettingIP6Config.new()
    s_ip6[NM.SETTING_IP_CONFIG_METHOD] = "auto"
    profile:add_setting(s_ip6)

    if access_point.security ~= "" then
        local s_wifi_sec = NM.SettingWirelessSecurity.new()

        if access_point.security == "WEP" then
            s_wifi_sec[NM.SETTING_WIRELESS_SECURITY_KEY_MGMT] = "wpa-psk"
            s_wifi_sec[NM.SETTING_WIRELESS_SECURITY_WEP_KEY_TYPE] = "open"
            s_wifi_sec[NM.SETTING_WIRELESS_SECURITY_WEP_KEY_TYPE] = NM.WepKeyType.PASSPHRASE
            s_wifi_sec:set_wep_key(0, helpers.string.trim(password))
        else
            s_wifi_sec[NM.SETTING_WIRELESS_SECURITY_KEY_MGMT] = "wpa-psk"
            s_wifi_sec[NM.SETTING_WIRELESS_SECURITY_AUTH_ALG] = "open"
            s_wifi_sec[NM.SETTING_WIRELESS_SECURITY_PSK] = helpers.string.trim(password)
        end

        profile:add_setting(s_wifi_sec)
    end

    return profile
end

local function on_wifi_device_state_changed(self, new_state, old_state, reason)
    print(new_state)
    print(old_state)
    print(reason)
    print("-----------------------------------------------------")

    print(helpers.inspect.inspect(self))

    -- if (new_state == DeviceState.UNAVAILABLE or new_state == DeviceState.FAILED
    --     or new_state == DeviceState.DEACTIVATING) and reason ~= DeviceStateReason.NEW_ACTIVATION
    -- then
    --     -- self:emit_signal("wireless_state", false)
    -- elseif new_state == DeviceState.DISCONNECTED and reason ~= DeviceState.NEW_ACTIVATION then
    --     -- gtimer { timeout = 5, autostart = true, call_now = false, single_shot = true, callback = function()
    --         -- self:scan_access_points()
    --     -- end }
    -- elseif new_state == DeviceState.ACTIVATED then
    --     -- local active_access_point = self._private.wifi_device_proxy.ActiveAccessPoint
    --     -- self:scan_access_points()
    --     -- self:emit_signal("wireless_state", true, active_access_point.Ssid)
    -- end
end

local function get_wifi_device(self)
    if self._private.wifi_device_proxy ~= nil then
        -- self._private.wifi_device_proxy:disconnect_signal("StateChanged", on_wifi_device_state_changed)
    end

    local devices = self._private.client_proxy:GetDevices()
    for _, device_path in ipairs(devices) do
        local device_proxy = dbus_proxy.Proxy:new {
            bus = dbus_proxy.Bus.SYSTEM,
            name = "org.freedesktop.NetworkManager",
            interface = "org.freedesktop.NetworkManager.Device",
            path = device_path
        }

        if device_proxy.DeviceType == DeviceType.WIFI then
            self._private.wifi_device_proxy = dbus_proxy.Proxy:new {
                bus = dbus_proxy.Bus.SYSTEM,
                name = "org.freedesktop.NetworkManager",
                interface = "org.freedesktop.NetworkManager.Device.Wireless",
                path = device_path
            }
            self._private.wifi_device_proxy_path = device_path

            device_proxy:connect_signal("StateChanged", on_wifi_device_state_changed)
        end
    end
end

function network_manager:connect_to_access_point(access_point, password, auto_connect)
    if #access_point.connection_profiles > 0 then
        local my_context = {call_id = "my-id"}
        self._private.client_proxy:ActivateConnectionAsync(function(proxy, context, success, failure)
            if failure ~= nil then
                print("Failed to activate connection: ", failure)
                print("Failed to activate connection error code: ", failure.code)
                context.failure = failure
                self:emit_signal("access_point::connection::failed", failure, failure_code)
                return
            end


            context.success = success
            self:emit_signal("access_point::connection::success")

        end, my_context, "/", self._private.wifi_device_proxy_path, access_point.path)
    else
        -- self._private.client:add_and_activate_connection_async(create_profile(access_point, password, auto_connect), access_point.device,
        -- access_point.path, nil, function(device, result, data)
        --     device:add_and_activate_connection_finish(result)
        -- end)
    end
end

function network_manager:scan_access_points()
    get_wifi_device(self)

    self._private.access_points = {}

    local my_context = {call_id = "my-id"}
    self._private.wifi_device_proxy:RequestScanAsync(function(proxy, context, success, failure)
        if failure ~= nil then
            print("Wifi rescan error: ", failure)
            print("Wifi rescan failed error code: ", failure.code)
            context.failure = failure
            return
        end
        context.success = success

        local access_points = self._private.wifi_device_proxy:GetAccessPoints()
        for _, access_point_path in ipairs(access_points) do
            local access_point_proxy = dbus_proxy.Proxy:new {
                bus = dbus_proxy.Bus.SYSTEM,
                name = "org.freedesktop.NetworkManager",
                interface = "org.freedesktop.NetworkManager.AccessPoint",
                path = access_point_path
            }

            local ssid = NM.utils_ssid_to_utf8(access_point_proxy.Ssid)
            local security = flags_to_security(access_point_proxy.Flags, access_point_proxy.WpaFlags, access_point_proxy.RsnFlags)

            local connection_profiles = {}

            local connections = self._private.settings_proxy:ListConnections()
            for _, connection_path in ipairs(connections) do
                local connection_proxy = dbus_proxy.Proxy:new {
                    bus = dbus_proxy.Bus.SYSTEM,
                    name = "org.freedesktop.NetworkManager",
                    interface = "org.freedesktop.NetworkManager.Settings.Connection",
                    path = connection_path
                }

                if string.find(connection_proxy.Filename, ssid) then
                    table.insert(connection_profiles, connection_proxy)
                end
            end

            table.insert(self._private.access_points, {
                raw_ssid = access_point_proxy.Ssid,
                ssid = ssid,
                security = security,
                strength = access_point_proxy.Strength,
                path = access_point_path,
                can_activate = #connection_profiles > 0 or security == "",
                connection_profiles = connection_profiles,
            })
        end

        self:emit_signal("access_points", self._private.access_points)
    end, my_context, {})
end

function network_manager:toggle_wireless_state()
    local enable = not self._private.client_proxy.WirelessEnabled
    if enable == true then
        self:set_network_state(true)
    end

    self._private.client_proxy:Set("org.freedesktop.NetworkManager", "Powered", lgi.GLib.Variant("b", enable))
    self._private.client_proxy.Powered = {signature = "b", value = enable}
end

function network_manager:set_network_state(state)
    self._private.client_proxy.Enable(state)
end

function network_manager:open_settings()
    awful.spawn("nm-connection-editor", false)
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, network_manager, true)

    ret._private = {}
    ret._private.access_points = {}

    ret._private.client_proxy = dbus_proxy.Proxy:new {
        bus = dbus_proxy.Bus.SYSTEM,
        name = "org.freedesktop.NetworkManager",
        interface = "org.freedesktop.NetworkManager",
        path = "/org/freedesktop/NetworkManager"
    }

    ret._private.settings_proxy = dbus_proxy.Proxy:new {
        bus = dbus_proxy.Bus.SYSTEM,
        name = "org.freedesktop.NetworkManager",
        interface = "org.freedesktop.NetworkManager.Settings",
        path = "/org/freedesktop/NetworkManager/Settings"
    }

    get_wifi_device(ret)
    ret:scan_access_points()

    return ret
end

if not instance then
    instance = new()
end
return instance