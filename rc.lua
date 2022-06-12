-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

pcall(require, "luarocks.loader")

local gtimer = require("gears.timer")
local beautiful = require("beautiful")
local helpers = require("helpers")
local collectgarbage = collectgarbage

collectgarbage("setpause", 100)
collectgarbage("setstepmul", 400)

beautiful.init(helpers.filesystem.get_awesome_config_dir("presentation") .. "theme/theme.lua")

require("config")
require("presentation")

gtimer { timeout = 5, autostart = true, call_now = true, callback = function()
    collectgarbage("collect")
end }
