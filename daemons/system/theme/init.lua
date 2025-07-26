-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local Gio = require("lgi").Gio
local gobject = require("gears.object")
local gtable = require("gears.table")
local filesystem = require("external.filesystem")
local json = require("external.json")

local theme = {}
local instance = nil

local PATH = filesystem.filesystem.get_data_dir("theme")
local DATA_PATH = PATH .. "data.json"
local DEFAULT_WALLPAPER_PATH = "~/.config/awesome/assets/wallpapers/0005.jpg"
local DEFAULT_COLORSCHEME = {
	"#010610",
	"#2C5F9A",
	"#2C5F9A",
	"#2972E4",
	"#4C7ADD",
	"#488CB1",
	"#3493ED",
	"#a1c5ee",
	"#04183f",
	"#0e5db8",
	"#0e5db8",
	"#0e6cff",
	"#2c6ffd",
	"#2397d7",
	"#2294ff",
	"#ffffff",
}

function theme:get_wallpaper_path()
	if not self._private.settings then
		self:init()
	end

	if self._private.settings and self._private.settings.wallpaper then
		return self._private.settings.wallpaper
	else
		return DEFAULT_WALLPAPER_PATH
	end
end

function theme:get_colorscheme()
	if not self._private.settings then
		self:init()
	end

	if self._private.settings and self._private.settings.colorscheme then
		return self._private.settings.colorscheme
	else
		return DEFAULT_COLORSCHEME
	end
end

function theme:init()
	local file = filesystem.file.new_for_path(DATA_PATH)
	if file:exists_block() then
		self._private.settings = json.decode(Gio.File.new_for_path(DATA_PATH):load_contents())
	else
		self._private.settings = {}
	end
end

local function new()
	local ret = gobject({})
	gtable.crush(ret, theme, true)

	ret._private = {}

	return ret
end

if not instance then
	instance = new()
end
return instance
