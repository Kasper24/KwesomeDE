-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local helpers = require("helpers")
local capi = { client = client }

local screenshot = { }
local instance = nil

function screenshot:set_show_cursor(state)
    self._private.show_cursor = state
    helpers.settings:set_value("screenshot-show-cursor", state)
end

function screenshot:get_show_cursor()
    return self._private.show_cursor
end

function screenshot:get_delay()
    return self._private.delay
end

function screenshot:increase_delay()
    self._private.delay = self._private.delay + 1
    helpers.settings:set_value("screenshot-delay", self._private.delay)
    return self:get_delay()
end

function screenshot:decrease_delay()
    if self._private.delay > 0 then
        self._private.delay = self._private.delay - 1
        helpers.settings:set_value("screenshot-delay", self._private.delay)
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
                helpers.settings:set_value("screenshot-folder", line)
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

    local screenshot = awful.screenshot {
        directory = self._private.folder,
        interactive = self._private.screenshot_method == "selection"
    }

    screenshot:connect_signal("timer::timeout", function()
        if self._private.screenshot_method == "screen" then
            screenshot.screen = awful.screen.focused()
        elseif self._private.screenshot_method == "window" then
            screenshot.client = capi.client.focus
        end
    end)

    screenshot:connect_signal("file::saved", function(_, file_path, method)
        self:emit_signal("ended", self._private.folder, file_path)
    end)

    -- Adding a small delay so the screenshot widget can hide itself
    -- Using awful.screenshot built in delay fucks it up
    gtimer {
        timeout = math.max(0.5, self._private.delay),
        single_shot = true,
        autostart = true,
        call_now = false,
        callback = function()
            screenshot:refresh()
        end
    }
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, screenshot, true)

    ret._private = {}
    ret._private.screenshot_method = "selection"
    ret._private.delay = helpers.settings:get_value("screenshot-delay")
    ret._private.show_cursor = helpers.settings:get_value("screenshot-show-cursor")
    ret._private.folder = helpers.settings:get_value("screenshot-folder")

    return ret
end

if not instance then
    instance = new()
end
return instance