-- Provides:
-- wired::disconnected
--      (No parameters)
-- wireless::disconnected
--      (No parameters)
-- wired::connected
--      interface (string)
--      health (bool)
-- wireless::connected
--      essid (string)
--      interface (string)
--      strength (number)
--      strength_level (number)
--      bitrate (number)
--      healthy (bool)
-- wireless::connecting
--      (No parameters)

local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local tostring = tostring
local tonumber = tonumber
local math = math

local network = { }
local instance = nil

local UPDATE_INTERVAL = 1
local interfaces = { wlan_interface = "wlp4s0", lan_interface = "enp0s25" }

local network_mode = nil
local is_startup = true
local is_disconnected = true
local airplane_mode = true

local check_internet_health_script =
[=[
	status_ping=0
	packets="$(ping -q -w2 -c2 1.1.1.1 | grep -o "100% packet loss")"
	if [ ! -z "${packets}" ];
	then
		status_ping=0
	else
		status_ping=1
	fi
	if [ $status_ping -eq 0 ];
	then
		echo 'Connected but no internet'
	fi
]=]
local airplane_wired_status_script = "rfkill list lan"
local airplane_wireless_status_script = "rfkill list wlan"
local airplane_turn_on_script = "sudo rfkill block wlan"
local airplane_turn_off_script = "sudo rfkill unblock wlan"
local wireless_turn_on_script = "nmcli radio wifi on"
local wireless_turn_off_script = "nmcli radio wifi off"

local function update_wireless(self)
    local update_wireless_data = function(strength, strength_level, healthy)
        awful.spawn.easy_async("iwconfig", function(stdout)
            local essid = stdout:match("ESSID:(.-)\n") or "N/A"
            essid = essid:gsub("%\"", "")
            local bitrate = stdout:match("Bit Rate=(.+/s)") or "N/A"

            if essid:match("off/any") == nil and healthy and (is_disconnected or is_startup) then
                self:emit_signal("wireless::connected", essid, interfaces.wlan_interface, strength, strength_level, bitrate, healthy)
                is_disconnected = false
            end
            is_startup = false
        end)
    end

    local update_wireless_connection_state = function(strength, strength_level)
        awful.spawn.easy_async_with_shell(check_internet_health_script, function(stdout)
            if stdout:match("Connected but no internet") then
                update_wireless_data(strength, strength_level, false)
            else
                update_wireless_data(strength, strength_level, true)
            end
        end)
    end

    local update_wireless_strength = function()
        awful.spawn.easy_async_with_shell([[awk 'NR==3 {printf "%3.0f" ,($3/70)*100}' /proc/net/wireless]], function(stdout)
            if not tonumber(stdout) then
                return
            end
            local strength = tonumber(stdout)
            local strength_level = math.floor(strength / 25 + 0.5)
            update_wireless_connection_state(strength, strength_level)
        end)
    end

    network_mode = "wireless"
    update_wireless_strength()
    is_startup = false
end

local function update_wired(self)
    network_mode = "wired"

    awful.spawn.easy_async_with_shell(check_internet_health_script, function(stdout)
        if is_startup or is_disconnected then
            local healthy = stdout:match("Connected but no internet") and false or true
            self:emit_signal("wired::connected", interfaces.lan_interface, healthy)
            is_disconnected = false
        end
        is_startup = false
    end)
end

local function update_disconnected(self)
    if network_mode == "wireless" then
        if not is_disconnected then
            is_disconnected = true
            self:emit_signal("wireless::disconnected")
        end
    elseif network_mode == "wired" then
        if not is_disconnected then
            is_disconnected = true
            self:emit_signal("wired::disconnected")
        end
    end
end

local function check_airplane_mode(self)
    if network_mode == "wireless" then
        awful.spawn.easy_async_with_shell(airplane_wireless_status_script, function(out)
            if out:match("Soft blocked: no") then
                if airplane_mode then
                    airplane_mode = false
                    self:emit_signal("airplane_mode", airplane_mode)
                end
            else
                if airplane_mode == false then
                    airplane_mode = true
                    self:emit_signal("airplane_mode", airplane_mode)
                end
            end
        end)
    elseif network_mode == "wired" then
        awful.spawn.easy_async_with_shell(airplane_wired_status_script, function(out)
            if out:match("Soft blocked: no") then
                if airplane_mode then
                    airplane_mode = false
                    self:emit_signal("airplane_mode", airplane_mode)
                end
            else
                if airplane_mode == false then
                    airplane_mode = true
                    self:emit_signal("airplane_mode", airplane_mode)
                end
            end
        end)
    end
end

local function check_network_mode(self)
    awful.spawn.easy_async_with_shell
    (
        [=[
        wireless="]=] .. tostring(interfaces.wlan_interface) .. [=["
        wired="]=] .. tostring(interfaces.lan_interface) .. [=["
        net="/sys/class/net/"
        wired_state="down"
        wireless_state="down"
        network_mode=""
        # Check network state based on interface's operstate value
        function check_network_state() {
            # Check what interface is up
            if [[ "${wireless_state}" == "up" ]];
            then
                network_mode='wireless'
            elif [[ "${wired_state}" == "up" ]];
            then
                network_mode='wired'
            else
                network_mode='No internet connection'
            fi
        }
        # Check if network directory exist
        function check_network_directory() {
            if [[ -n "${wireless}" && -d "${net}${wireless}" ]];
            then
                wireless_state="$(cat "${net}${wireless}/operstate")"
            fi
            if [[ -n "${wired}" && -d "${net}${wired}" ]]; then
                wired_state="$(cat "${net}${wired}/operstate")"
            fi
            check_network_state
        }
        # Start script
        function print_network_mode() {
            # Call to check network dir
            check_network_directory
            # Print network mode
            printf "${network_mode}"
        }
        print_network_mode
        ]=],
        function(stdout)
            local mode = stdout:gsub("%\n", "")
            if stdout:match("No internet connection") then
                update_disconnected(self)
            elseif stdout:match("wireless") then
                update_wireless(self)
            elseif stdout:match("wired") then
                update_wired(self)
            end
        end
    )
end

function network:toggle_airplane()
    if airplane_mode then
        awful.spawn(airplane_turn_off_script, false)
    else
        awful.spawn(airplane_turn_on_script, false)
    end
end

function network:toggle_wireless()
    if network_mode == "wireless" then
        if is_disconnected then
            awful.spawn(wireless_turn_on_script, false)
            self:emit_signal("wireless::connecting")
        else
            awful.spawn(wireless_turn_off_script, false)
        end
    end
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, network, true)

    return ret
end

if not instance then
    instance = new()
end
return instance