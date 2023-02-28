-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local lgi = require('lgi')
local Gtk = lgi.require('Gtk', '3.0')
local Gdk = lgi.require('Gdk', '3.0')
local GdkPixbuf = lgi.GdkPixbuf
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local helpers = require("helpers")
local filesystem = require("external.filesystem")
local string = string
local os = os
local capi = {
    client = client
}

local screenshot = {}
local instance = nil

local FOLDER_PICKER_SCRIPT_PATH = filesystem.filesystem.get_awesome_config_dir("scripts") .. "folder-picker.lua"

function screenshot:set_show_cursor(state)
    self._private.show_cursor = state
    helpers.settings["screenshot-show-cursor"] = state
end

function screenshot:get_show_cursor()
    return self._private.show_cursor
end

function screenshot:set_delay(delay)
    self._private.delay = delay
    helpers.settings["screenshot-delay"] = delay
end

function screenshot:get_delay()
    return self._private.delay
end

function screenshot:set_folder(folder)
    if folder then
        self._private.folder = folder
        helpers.settings["screenshot-folder"] = folder
    else
        awful.spawn.easy_async(FOLDER_PICKER_SCRIPT_PATH .. " '" .. self._private.folder .. "'", function(stdout)
            stdout = helpers.string.trim(stdout)
            if stdout ~= "" and stdout ~= nil then
                self._private.folder = stdout
                helpers.settings["screenshot-folder"] = stdout
                self:emit_signal("folder::updated", stdout)
            end
        end)
    end
end

function screenshot:get_folder()
    return self._private.folder
end

function screenshot:set_screenshot_method(screenshot_method)
    self._private.screenshot_method = screenshot_method
end

function screenshot:screenshot()
    self:emit_signal("started")

    local function screenshot()
        local file_name = os.date("%d-%m-%Y-%H:%M:%S") .. ".png"
        local command = self._private.show_cursor and "maim " or "maim -u "
        if self._private.screenshot_method == "selection" then
            command = command .. "-s " .. self._private.folder .. file_name
        elseif self._private.screenshot_method == "screen" then
            command = command .. " " .. self._private.folder .. file_name
        elseif self._private.screenshot_method == "window" then
            if capi.client.focus then
                command =  string.format("%s -i %s %s%s", command, capi.client.focus.window, self._private.folder, file_name)
            else
                self:emit_signal("error::create_file", "No focused client")
                return
            end
        elseif self._private.screenshot_method == "color_picker" then
            self:pick_color()
            return
        end

        awful.spawn.easy_async_with_shell(command, function(stdout, stderr)
            local file = filesystem.file.new_for_path(self._private.folder .. file_name)
            file:exists(function(error, exists)
                if error == nil and exists == true then
                    self:copy_screenshot(self._private.folder .. file_name)
                    self:emit_signal("ended", self._private.folder, file_name)
                else
                    self:emit_signal("error::create_file", stderr)
                end
            end)
        end)
    end

    gtimer.start_new(self._private.delay, function()
        local folder = filesystem.file.new_for_path(self._private.folder)
        folder:exists(function(error, exists)
            if exists == false then
                filesystem.filesystem.make_directory(self._private.folder, function(error)
                    if error == nil then
                        screenshot()
                    else
                        self:emit_signal("error::create_directory")
                    end
                end)
            else
                screenshot()
            end
        end)

        return false
    end)
end

function screenshot:pick_color()
    awful.spawn.easy_async("xcolor", function(stdout, stderr)
        stdout = helpers.string.trim(stdout)
        self:copy_color(stdout)
        self:emit_signal("color::picked", stdout)
    end)
end

function screenshot:copy_screenshot(path)
    local image = GdkPixbuf.Pixbuf.new_from_file(path)
    self._private.clipboard:set_image(image)
    self._private.clipboard:store()
end

function screenshot:copy_color(color)
    self._private.clipboard:set_text(color, -1)
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, screenshot, true)

    ret._private = {}
    ret._private.clipboard = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD)

    ret._private.screenshot_method = "selection"
    ret._private.delay = helpers.settings["screenshot-delay"]
    ret._private.show_cursor = helpers.settings["screenshot-show-cursor"]
    ret._private.folder = helpers.settings["screenshot-folder"]:gsub("~", os.getenv("HOME"))

    return ret
end

if not instance then
    instance = new()
end
return instance
