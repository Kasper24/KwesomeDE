-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local filesystem = require("external.filesystem")
local json = require("external.json")

local capi = {
	awesome = awesome,
}

local display = {}
local instance = nil

local PATH = filesystem.filesystem.get_cache_dir("displays")
local DATA_PATH = PATH .. "data.json"

local function build_xrandr_command(display)
    local cmd = "xrandr --output " .. display.name

    if display.primary then
        cmd = cmd .. " --primary"
    end

    if display.width and display.height then
        cmd = cmd .. " --mode " .. display.width .. "x" .. display.height
    end

    if display.refreshRate then
        cmd = cmd .. " --rate " .. display.refreshRate
    end

    if display.x and display.y then
        cmd = cmd .. " --pos " .. display.x .. "x" .. display.y
    end

    if display.rotation then
        cmd = cmd .. " --rotate " .. display.rotation
    end

    if display.gamma then
        cmd = cmd .. " --gamma " .. display.gamma
    end

    if display.scale then
        cmd = cmd .. " --scale " .. display.scale
    end

    if display.dpi then
        cmd = cmd .. " --dpi " .. display.dpi
    end

    return cmd
end

function display:apply()
    local file = filesystem.file.new_for_path(DATA_PATH)
	file:read(function(error, content)
		if error == nil then
            local json = json.decode(content) or {}
            for _, display in ipairs(json) do
                awful.spawn(build_xrandr_command(display), false)
            end
		end
	end)
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, display, true)

    ret._private = {}

    capi.awesome.connect_signal("screen::change", function()
        ret:apply()
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance
