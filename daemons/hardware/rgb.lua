-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local beautiful = require("beautiful")
local helpers = require("helpers")

local rgb = {}
local instance = nil

local script = [[python3 - <<END
from openrgb import OpenRGBClient
from openrgb.utils import RGBColor, DeviceType

client = OpenRGBClient()
mobo = client.get_devices_by_type(DeviceType.MOTHERBOARD)[0]
ram1 = client.get_devices_by_type(DeviceType.DRAM)[0]
ram2 = client.get_devices_by_type(DeviceType.DRAM)[1]
aio = client.get_devices_by_type(DeviceType.COOLER)[0]
fans = client.get_devices_by_type(DeviceType.LEDSTRIP)[0]
gpu = client.get_devices_by_type(DeviceType.GPU)[0]
#mouse = client.get_devices_by_type(DeviceType.MOUSE)[0]
#keyboard = client.get_devices_by_type(DeviceType.KEYBOARD)[0]
led_strip = client.get_devices_by_type(DeviceType.LEDSTRIP)[1]
led_strip2 = client.get_devices_by_type(DeviceType.LEDSTRIP)[2]
led_strip3 = client.get_devices_by_type(DeviceType.LEDSTRIP)[3]

if mobo is not None:
    mobo.set_mode('direct')
    mobo.set_color(RGBColor.fromHSV(h1, 100, 100))

if ram1 is not None:
    ram1.set_mode('direct')
    ram1.set_color(RGBColor.fromHSV(h1, 100, 100))

if ram2 is not None:
    ram2.set_mode('direct')
    ram2.set_color(RGBColor.fromHSV(h1, 100, 100))

if aio is not None:
    aio.set_mode('direct')
    aio.set_color(RGBColor.fromHSV(h1, 100, 100))

if fans is not None:
    fans.set_mode('direct')
    fans.set_color(RGBColor.fromHSV(h2, 100, 100))

if gpu is not None:
    gpu.set_mode('off')
    #gpu.set_mode('static')
    #gpu.set_color(RGBColor.fromHSV(h1, 100, 100))

#if mouse is not None:
    #mouse.set_mode('static')
    #mouse.set_color(RGBColor.fromHSV(h2, 100, 100), 0, 1)
    #mouse.set_color(RGBColor.fromHSV(h1, 100, 100), 1, 2)

#if keyboard is not None:
    #keyboard.set_mode('direct')
    #keyboard.set_color(RGBColor.fromHSV(h2, 100, 100))

if led_strip is not None:
    led_strip.set_color(RGBColor.fromHSV(h2, 100, 100))

if led_strip2 is not None:
    led_strip2.set_color(RGBColor.fromHSV(h2, 100, 100))

if led_strip3 is not None:
    led_strip3.set_color(RGBColor.fromHSV(h1, 100, 100))
END
]]

function rgb:sync_colors_script(new_colors)
    if new_colors == true then
        self._private.color_1 = helpers.color.hex_to_hsv(beautiful.colors.random_accent_color())
        self._private.color_2 = helpers.color.hex_to_hsv(beautiful.colors.random_accent_color())
    end

    local _script = script

    _script = _script:gsub("h1", self._private.color_1.h)
    _script = _script:gsub("h2", self._private.color_2.h)

    awful.spawn.with_shell(_script)
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, rgb, true)
    ret._private = {}

    ret._private.color_1 = helpers.color.hex_to_hsv(beautiful.colors.random_accent_color())
    ret._private.color_2 = helpers.color.hex_to_hsv(beautiful.colors.random_accent_color())

    return ret
end

if not instance then
    instance = new()
end
return instance
