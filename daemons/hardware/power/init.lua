-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local filesystem = require("external.filesystem")
local json = require("external.json")

local display = {}
local instance = nil

local PATH = filesystem.filesystem.get_data_dir("power")
local DATA_PATH = PATH .. "data.json"

function display:init()
	local file = filesystem.file.new_for_path(DATA_PATH)
	file:read(function(error, content)
		if error == nil then
			local json = json.decode(content) or {}
			if json.screenBlank == false then
				awful.spawn("xset s noblank", false)
				awful.spawn("xset s off", false)
			end
			if json.powerSaving == false then
				awful.spawn("xset -dpms", false)
			end
		end
	end)
end

local function new()
	local ret = gobject({})
	gtable.crush(ret, display, true)

	ret._private = {}

	return ret
end

if not instance then
	instance = new()
end
return instance
