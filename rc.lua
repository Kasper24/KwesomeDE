-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

pcall(require, "luarocks.loader")

local gtimer = require("gears.timer")
local collectgarbage = collectgarbage
local capi = {
	awesome = awesome
}

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
local helpers = require("helpers")
beautiful.init(helpers.filesystem.get_awesome_config_dir("ui") .. "theme.lua")
require("config")

if DEBUG ~= true then
	require("ui.popups.loading")
	local persistent_daemon = require("daemons.system.persistent")
	persistent_daemon:enable()
	capi.awesome.connect_signal("startup::finished", function()
		require("ui")
		gtimer{
			timeout = 0.3,
			autostart = true,
			call_now = false,
			single_shot = true,
			callback = function()
				capi.awesome.emit_signal("ui::ready")
			end,
		}
	end)
else
	require("ui")
end