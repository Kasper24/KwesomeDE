-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local collectgarbage = collectgarbage
collectgarbage("incremental", 110, 1000)
pcall(require, "luarocks.loader")

local memory_last_check_count = collectgarbage("count")
local memory_last_run_time = os.time()
local memory_growth_factor = 1.1 -- 10% over last
local memory_long_collection_time = 300 -- five minutes in seconds

local gtimer = require("gears.timer")
gtimer.start_new(5, function()
	local cur_memory = collectgarbage("count")
	-- instead of forcing a garbage collection every 5 seconds
	-- check to see if memory has grown enough since we last ran
	-- or if we have waited a sificiently long time
	local elapsed = os.time() - memory_last_run_time
	local waited_long = elapsed >= memory_long_collection_time
	local grew_enough = cur_memory > (memory_last_check_count * memory_growth_factor)
	if grew_enough or waited_long then
		collectgarbage("collect")
		collectgarbage("collect")
		memory_last_run_time = os.time()
	end
	-- even if we didn't clear all the memory we would have wanted
	-- update the current memory usage.
	-- slow growth is ok so long as it doesn't go unchecked
	memory_last_check_count = collectgarbage("count")
	return true
end)

if os.getenv("AWM_DEBUG") == "true" then
	DEBUG = true
end

require("daemons.hardware.display"):init()
require("daemons.hardware.power"):init()
require("daemons.system.shortcuts"):init()

local beautiful = require("beautiful")
local ui_daemon = require("daemons.system.ui")
local filesystem = require("external.filesystem")

beautiful.xresources.set_dpi(ui_daemon:get_dpi())
beautiful.init(filesystem.filesystem.get_awesome_config_dir("ui") .. "theme.lua")

require("config")
require("ui")

if DEBUG ~= true then
	require("daemons.system.persistent"):enable()
end
