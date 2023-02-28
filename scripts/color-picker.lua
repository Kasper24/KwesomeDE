#!/usr/bin/lua

local lgi = require('lgi')
local Gtk = lgi.require('Gtk', '3.0')
local format = string.format
local floor = math.floor
local tonumber = tonumber

local App = Gtk.Application({
    application_id = 'GtkColorPicker'
})

local function rgba_to_hex(color)
    local r = floor(color.red * 255)
    local g = floor(color.green * 255)
    local b = floor(color.blue * 255)

    return '#' .. format('%02x%02x%02x', r, g, b)
end

function App:on_startup()
    local color = arg[1]
    local Dialog  = Gtk.ColorSelectionDialog({
        title = 'Pick a Color',
    })
    Dialog:set_wmclass('Color Picker', 'Color Picker')

    local Gdk = lgi.require('Gdk', '3.0')

    if color then
        local color_obj = Gdk.RGBA()
        color_obj.red = tonumber(color:sub(2, 3), 16) / 255
        color_obj.green = tonumber(color:sub(4, 5), 16) / 255
        color_obj.blue = tonumber(color:sub(6, 7), 16) / 255
        Dialog:get_color_selection():set_current_rgba(color_obj)
    end

    self:add_window(Dialog)
end

function App:on_activate()
    local Res = self.active_window:run()

    if Res == Gtk.ResponseType.OK then
        local color = self.active_window:get_color_selection():get_current_rgba()
        print(rgba_to_hex(color))
        self.active_window:destroy()
    elseif Res == Gtk.ResponseType.CANCEL then
        self.active_window:destroy()
    else
        self.active_window:destroy()
    end
end

return App:run()