-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

pcall(require, "luarocks.loader")

local gtimer = require("gears.timer")
local collectgarbage = collectgarbage

collectgarbage("setpause", 110)
collectgarbage("setstepmul", 1000)
gtimer{
	timeout = 5,
	autostart = true,
	call_now = true,
	callback = function()
		collectgarbage("collect")
	end,
}

local beautiful = require("beautiful")
local filesystem = require("external.filesystem")
beautiful.init(filesystem.filesystem.get_awesome_config_dir("ui") .. "theme.lua")

local theme_daemon = require("daemons.system.theme")
local beautiful = require("beautiful")
beautiful.xresources.set_dpi(theme_daemon:get_dpi())

require("config")
require("ui")

if DEBUG ~= true then
	require("daemons.system.persistent"):enable()
end