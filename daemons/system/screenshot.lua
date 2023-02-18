-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local helpers = require("helpers")
local string = string
local os = os
local capi = {
    client = client
}

local screenshot = {}
local instance = nil

function screenshot:set_show_cursor(state)
    self._private.show_cursor = state
    helpers.settings:set_value("screenshot-show-cursor", state)
end

function screenshot:get_show_cursor()
    return self._private.show_cursor
end

function screenshot:set_delay(delay)
    self._private.delay = delay
    helpers.settings:set_value("screenshot-delay", self._private.delay)
end

function screenshot:get_delay()
    return self._private.delay
end

function screenshot:set_folder(folder)
    if folder then
        self._private.folder = folder
        helpers.settings:set_value("screenshot-folder", folder)
    else
        awful.spawn.easy_async("yad --file --directory", function(stdout)
            for line in stdout:gmatch("[^\r\n]+") do
                if line ~= "" then
                    self._private.folder = line
                    helpers.settings:set_value("screenshot-folder", line)
                    self:emit_signal("folder::updated", line)
                end
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
        end

        awful.spawn.easy_async_with_shell(command, function(stdout, stderr)
            local file = helpers.file.new_for_path(self._private.folder .. file_name)
            file:exists(function(error, exists)
                if error == nil then
                    if exists == true then
                        awful.spawn("xclip -selection clipboard -t image/png -i " .. self._private.folder .. file_name,
                            false)
                        self:emit_signal("ended", self._private.screenshot_method, self._private.folder, file_name)
                    else
                        self:emit_signal("error::create_file", stderr)
                    end
                end
            end)
        end)
    end

    gtimer.start_new(self._private.delay, function()
        local folder = helpers.file.new_for_path(self._private.folder)
        folder:exists(function(error, exists)
            if exists == false then
                helpers.filesystem.make_directory(self._private.folder, function(error)
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

local function new()
    local ret = gobject {}
    gtable.crush(ret, screenshot, true)

    ret._private = {}
    ret._private.screenshot_method = "selection"
    ret._private.delay = helpers.settings:get_value("screenshot-delay")
    ret._private.show_cursor = helpers.settings:get_value("screenshot-show-cursor")
    ret._private.folder = helpers.settings:get_value("screenshot-folder"):gsub("~", os.getenv("HOME"))

    return ret
end

if not instance then
    instance = new()
end
return instance
