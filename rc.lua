-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local collectgarbage = collectgarbage
collectgarbage("incremental", 110, 1000)
pcall(require, "luarocks.loader")

local gtimer = require("gears.timer")
gtimer.start_new(5, function()
	collectgarbage("collect")
	collectgarbage("collect")
	return true
end)

local beautiful = require("beautiful")
local theme_daemon = require("daemons.system.theme")
local filesystem = require("external.filesystem")

beautiful.xresources.set_dpi(theme_daemon:get_dpi())
beautiful.init(filesystem.filesystem.get_awesome_config_dir("ui") .. "theme.lua")

require("config")
require("ui")

if DEBUG ~= true then
	require("daemons.system.persistent"):enable()
end