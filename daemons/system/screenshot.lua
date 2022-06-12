-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local settings = require("services.settings")
local helpers = require("helpers")
local os = os

local screenshot = { }
local instance = nil

function screenshot:set_show_cursor(state)
    self._private.show_cursor = state
    settings:set_value("screenshot.show_cursor", state)
end

function screenshot:get_show_cursor()
    return self._private.show_cursor
end

function screenshot:get_delay()
    return self._private.delay
end

function screenshot:increase_delay()
    self._private.delay = self._private.delay + 1
    settings:set_value("screenshot.delay", self._private.delay)
    return self:get_delay()
end

function screenshot:decrease_delay()
    if self._private.delay > 0 then
        self._private.delay = self._private.delay - 1
        settings:set_value("screenshot.delay", self._private.delay)
    end
    return self:get_delay()
end

function screenshot:get_folder()
    return self._private.folder
end

function screenshot:set_folder()
    awful.spawn.easy_async("yad --file --directory", function(stdout)
        for line in stdout:gmatch("[^\r\n]+") do
            if line ~= "" then
                self._private.folder = line
                settings:set_value("screenshot.folder", line)
                self:emit_signal("folder::updated", line)
            end
        end
    end)
end

function screenshot:set_screenshot_method(screenshot_method)
    self._private.screenshot_method = screenshot_method
end

function screenshot:screenshot()
    self:emit_signal("started")

    gtimer {
        timeout = self._private.delay,
        single_shot = true,
        autostart = true,
        call_now = false,
        callback = function()
            helpers.filesystem.make_directory(self._private.folder, function(result)
                if result == true then
                    local file_name = os.date("%d-%m-%Y-%H:%M:%S") .. ".png"
                    local command = self._private.show_cursor and "maim " or "maim -u "
                    if self._private.screenshot_method == "selection" then
                        command = command .. "-s " .. self._private.folder .. file_name
                    elseif self._private.screenshot_method == "screen" then
                        command = command .. " " .. self._private.folder .. file_name
                    elseif self._private.screenshot_method == "window" then
                        command = command .. " -i $(xdotool getactivewindow) " .. self._private.folder .. file_name
                    elseif self._private.screenshot_method == "flameshot" then
                        -- Sleep for 0.5 so the screnshot popup can hide itself before opening flameshot
                        command = "sleep 0.5 && flameshot gui"
                    end

                    awful.spawn.easy_async_with_shell(command, function(stdout, stderr)
                        if self._private.screenshot_method ~= "flameshot" then
                            helpers.filesystem.is_file_readable(self._private.folder .. file_name, function(result)
                                if result == true then
                                    awful.spawn("xclip -selection clipboard -t image/png -i " .. self._private.folder .. file_name, false)
                                    self:emit_signal("ended", self._private.screenshot_method, self._private.folder, file_name)
                                else
                                    self:emit_signal("error::create_file", stderr)
                                end
                            end)
                        end
                    end)
                else
                    self:emit_signal("error::create_directory")
                end
            end)
        end
    }
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, screenshot, true)

    ret._private = {}
    ret._private.screenshot_method = "selection"
    ret._private.delay = settings:get_value("screenshot.delay") or 0
    ret._private.show_cursor = settings:get_value("screenshot.show_cursor") or false
    ret._private.folder = settings:get_value("screenshot.folder") or
                                    "/home/" .. os.getenv("USER") .. "/Pictures/Screenshots/"

    return ret
end

if not instance then
    instance = new()
end
return instance