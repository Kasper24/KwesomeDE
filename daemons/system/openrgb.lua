-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local beautiful = require("beautiful")
local Color = require("external.lua-color")

local openrgb_daemon = {}
local instance = nil

local function print_device_info(self)
    -- Print the extracted device information
    for _, device in pairs(self._private.devices) do
        print("Device ID: " .. device.id)
        print("Name: " .. device.name)
        print("Type: " .. device.type)
        print("Description: " .. device.description)
        print("Modes:")
        for _, mode in ipairs(device.modes) do
            print("  - " .. mode)
        end
        print("Zones:")
        for _, zone in ipairs(device.zones) do
            print("  - " .. zone)
        end
        print("------------------------------------")
    end
end

function openrgb_daemon:turn_off()
    local cmd = "openrgb "
    for _, device in pairs(self._private.devices) do
        cmd = cmd .. "-d " .. device.id .. " -c " .. "000000 -m Direct "
    end

    awful.spawn.with_shell(cmd)
end

function openrgb_daemon:update_colors()
    local h, _, __ = Color(beautiful.colors.random_accent_color()):hsv()
    local color = tostring(Color {
        h = h,
        s = 1,
        v = 1
    }):gsub("#", "")

    local cmd = "openrgb "
    for _, device in pairs(self._private.devices) do
        cmd = cmd .. "-d " .. device.id .. " -c " .. color .. " -m Direct "
    end

    awful.spawn.with_shell(cmd)
end

local function extract_zones(zonesString)
    local tempZones = {}
    for zone in zonesString:gmatch("'([^']+)'") do
        table.insert(tempZones, zone)
    end

    local remainingZonesString = zonesString:gsub("'%s?([^']+)'%s?", "")
    for zone in remainingZonesString:gmatch("([^%s]+)") do
        table.insert(tempZones, zone)
    end
    return tempZones
end

local function get_device_info(self)
    self._private.devices = {}

    awful.spawn.easy_async("openrgb -l", function(stdout)
        local id, name, type, description, modes, zones, leds

        for line in stdout:gmatch("[^\r\n]+") do
            local temp_id, temp_name = line:match("(%d+):%s+(.+)")
            if temp_id and temp_name then
                id = tonumber(temp_id)
                name = temp_name
                self._private.devices[id] = { id = id, name = name }
            elseif line:find("Type:") then
                type = line:match("Type:%s+(.+)")
                self._private.devices[id].type = type
            elseif line:find("Description:") then
                description = line:match("Description:%s+(.+)")
                self._private.devices[id].description = description
            elseif line:find("Modes:") then
                modes = {}
                local modesString = line:match("Modes:%s+(.+)")
                for mode in modesString:gmatch("%S+") do
                  table.insert(modes, mode)
                end
                self._private.devices[id].modes = modes
            elseif line:find("Zones:") then
                zones = line:match("Zones:%s+(.+)")
                self._private.devices[id].zones = extract_zones(zones)
            end
        end

        print_device_info(self)

    end)
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, openrgb_daemon, true)
    ret._private = {}

    get_device_info(ret)

    return ret
end

if not instance then
    instance = new()
end
return instance
