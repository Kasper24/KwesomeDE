local lgi = require("lgi")
local GLib = lgi.GLib
local NM = lgi.NM
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local helpers = require("helpers")
local ipairs = ipairs
local string = string
local table = table
local math = math
local os = os

local network_manager = { }
local instance = nil

local function is_empty(t)
    local next = next
    if next(t) then return false else return true end
end

local function ssid_to_utf8(ap)
    local ssid = ap:get_ssid()
    if not ssid then return "" end
    return NM.utils_ssid_to_utf8(ssid:get_data())
end

local function flags_to_string(flags)
    local str = ""
    for flag, _ in pairs(flags) do
        str = str .. " " .. flag
    end
    if str == "" then str = "NONE" end
    return (str:gsub( "^%s", ""))
end

local function flags_to_security(flags, wpa_flags, rsn_flags)
    local str = ""
    if flags["PRIVACY"] and is_empty(wpa_flags) and is_empty(rsn_flags) then
      str = str .. " WEP"
    end
    if not is_empty(wpa_flags) then
      str = str .. " WPA1"
    end
    if not is_empty(rsn_flags) then
      str = str .. " WPA2"
    end
    if wpa_flags["KEY_MGMT_802_1X"] or rsn_flags["KEY_MGMT_802_1X"] then
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

local function get_ap_info(self, device, access_point)
    local ssid = ssid_to_utf8(access_point)
    if ssid == nil or ssid == "" then
        return
    end

    local frequency = access_point:get_frequency()
    local flags = access_point:get_flags()
    local wpa_flags = access_point:get_wpa_flags()
    local rsn_flags = access_point:get_rsn_flags()
    local security = flags_to_security(flags, wpa_flags, rsn_flags)

    -- remove extra NONE from the flags tables
    flags["NONE"] = nil
    wpa_flags["NONE"] = nil
    rsn_flags["NONE"] = nil

    local connections = self._private.client:get_connections()
    local connection = access_point:filter_connections(connections)

    table.insert(self._private.access_points,{
        raw_ssid = access_point:get_ssid(),
        ssid = ssid,
        bssid = access_point:get_bssid(),
        frequency = frequency,
        channel = NM.utils_wifi_freq_to_channel(frequency),
        mode = access_point:get_mode(),
        flags = flags_to_string(flags),
        wpa_flags = flags_to_string(wpa_flags),
        rsn_flags = flags_to_string(rsn_flags),
        security = security,
        can_activate = #connection > 0 or security == "",
        strength = access_point:get_strength(),
        path = access_point:get_path(),
        device = device,
        connection = connection,
    })
end

local function on_wifi_device_state_changed(self, device)
    local state = device:get_state()
    local state_reason = device:get_state_reason()

    if (state == "UNAVAILABLE" or state == "FAILED" or state == "DEACTIVATING")
        and state_reason ~= "NEW_ACTIVATION" then
        self:emit_signal("wireless_state", false)
    elseif state ==  "DISCONNECTED" and state_reason ~= "NEW_ACTIVATION" then
        gtimer { timeout = 5, autostart = true, call_now = false, single_shot = true, callback = function()
            self:scan_access_points()
        end }
    elseif state == "ACTIVATED" then
        local active_access_point = device:get_active_access_point()
        self:scan_access_points()
        self:emit_signal("wireless_state", true, ssid_to_utf8(active_access_point))
    end
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

function network_manager:connect_to_access_point(access_point, password, auto_connect)
    if #access_point.connection > 0 then
        self._private.client:activate_connection_async(access_point.connection[0], access_point.device, access_point.path,
        nil, function(device, result, data)
            device:activate_connection_finish(result)
        end)
    else
        self._private.client:add_and_activate_connection_async(create_profile(access_point, password, auto_connect), access_point.device,
        access_point.path, nil, function(device, result, data)
            device:add_and_activate_connection_finish(result)
        end)
    end
end

function network_manager:toggle_wireless()
    local enable = not self._private.client:wireless_get_enabled()
    if enable == true then
        self:set_network_state(true)
    end

    local value = GLib.Variant.new_boolean(enable)
    self._private.client:dbus_set_property(NM.DBUS_PATH, NM.DBUS_INTERFACE, "WirelessEnabled", value,
                                        -1, nil, nil, nil)
end

function network_manager:scan_access_points()
    self._private.access_points = {}

    for _, device in ipairs(self._private.client:get_devices()) do
        if device:get_device_type() == "WIFI" then
            device:request_scan_async(nil, function(device, result, data)
                if device:request_scan_finish(result) == true then
                    for _, access_point in ipairs(device:get_access_points()) do
                        get_ap_info(self, device, access_point)
                    end
                    self:emit_signal("access_points", self._private.access_points)
                else
                    print("Wifi rescan failed")
                end
            end, nil)
        end
    end
end

function network_manager:open_settings()
    awful.spawn("nm-connection-editor", false)
end

function network_manager:set_network_state(state)
    -- This doesn't work?
    -- local value = GLib.Variant.new_boolean(state)
    -- self._private.client:dbus_set_property(NM.DBUS_PATH, NM.DBUS_INTERFACE, "NetworkingEnabled", value,
    --                                     -1, nil, nil, nil)
    self._private.client:networking_set_enabled(state)
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, network_manager, true)

    ret._private = {}
    ret._private.access_points = {}

    ret._private.client = NM.Client.new()
    -- local devices = ret._private.client:get_devices()

    -- for _, device in ipairs(devices) do
    --     if device:get_device_type() == "WIFI" then
    --         device.on_state_changed = function(device)
    --             on_wifi_device_state_changed(ret, device)
    --         end

    --         for _, access_point in ipairs(device:get_access_points()) do
    --             get_ap_info(ret, device, access_point)
    --         end
    --     end
    -- end

    -- gtimer.delayed_call(function()
    --     ret:emit_signal("access_points", ret._private.access_points)

    --     local primary_connection = ret._private.client:get_primary_connection()
    --     if primary_connection ~= nil then
    --         local primary_connection_device = primary_connection:get_devices()[1]
    --         if primary_connection_device ~= nil and primary_connection_device:get_device_type() == "WIFI" then
    --             local active_access_point = primary_connection_device:get_active_access_point()
    --             if active_access_point ~= nil then
    --                 ret:emit_signal("wireless_state", ret._private.client:wireless_get_enabled(), ssid_to_utf8(active_access_point))
    --             else
    --                 ret:emit_signal("wireless_state", ret._private.client:wireless_get_enabled())
    --             end
    --         end
    --     end
    -- end)

    -- ret._private.client.on_notify = function()
    --     ret:emit_signal("wireless_state", ret._private.client:wireless_get_enabled(), "")
    -- end

    -- gtimer { timeout = 3, autostart = true, call_now = true, single_shot = false, callback = function()
    --     -- ret:emit_signal("wireless_state", ret._private.client:wireless_get_enabled(), "")
    -- end }

    return ret
end

if not instance then
    instance = new()
end
return instance