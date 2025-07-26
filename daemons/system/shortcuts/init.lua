-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local bling = require("external.bling")
local filesystem = require("external.filesystem")
local json = require("external.json")
local library = require("library")
local math = math
local keys = {
	shift = "Shift",
	ctrl = "Control",
	mod = "Mod4",
	alt = "Mod1",
}

local shortcuts = {}
local app = {}

local instance = nil

local PATH = filesystem.filesystem.get_data_dir("shortcuts")
local DATA_PATH = PATH .. "data.json"

local function centered_gemotery(width, height)
	width = width or awful.screen.focused().geometry.width * 0.7
	height = height or awful.screen.focused().geometry.height * 0.9

	return {
		x = (awful.screen.focused().geometry.width / 2) - (width / 2),
		y = (awful.screen.focused().geometry.height / 2) - (height / 2),
		width = width,
		height = height,
	}
end

local function terminal_gemotery(width, height)
	width = width or awful.screen.focused().geometry.width * 0.7
	height = height or awful.screen.focused().geometry.height * 0.5

	return {
		x = (awful.screen.focused().geometry.width / 2) - (width / 2),
		y = 100,
		width = width,
		height = height,
	}
end

local function random_animation()
	local screen_width = awful.screen.focused().geometry.width
	local screen_height = awful.screen.focused().geometry.height

	local x = math.random(screen_width, screen_width + 1500)
	local y = math.random(screen_height, screen_height + 1500)

	x = (math.random(0, 1)) == 1 and x * 1 or x * -1
	y = (math.random(0, 1)) == 1 and y * 1 or y * -1

	return x, y
end

function app:toggle()
	if self.run_or_raise == true then
		library.client.run_or_raise({ class = self.class }, false, self.command, { switchtotag = true })
	else
		awful.spawn(self.command)
	end
end

function app:scratchpad_toggle()
	-- if self.scratchpad.rubato.x.state == false and self.scratchpad.rubato.y.state == false then
	--     self.scratchpad.geometry = self.geometry
	--     if self.new_animation_on_toggle then
	--         local x, y = random_animation()
	--         self.scratchpad.rubato.x.pos = x
	--         self.scratchpad.rubato.y.pos = y
	--     end
	-- end

	self.scratchpad:toggle()
end

function shortcuts:new(opts)
	opts = opts or {}

	local ret = gobject({})
	gtable.crush(ret, app, true)

	ret.id = opts.id
	ret.key = opts.key
	ret.command = opts.command
	ret.class = opts.class
	ret.scratchpad_command = opts.scratchpad_command or opts.command
	ret.scratchpad_class = opts.scratchpad_class or opts.class
	ret.launch_modifiers = opts.launch_modifiers or { keys.mod, keys.ctrl }
	ret.scratchpad_modifiers = opts.scratchpad_modifiers or { keys.mod, keys.alt }
	ret.geometry = opts.geometry or centered_gemotery()
	ret.new_animation_on_toggle = opts.new_animation_on_toggle == nil and true or opts.new_animation_on_toggle
	ret.run_or_raise = opts.run_or_raise == nil and false or opts.run_or_raise

	local x, y = random_animation()
	ret.x = opts.x or x
	ret.y = opts.y or y

	ret.scratchpad = bling.module.scratchpad:new({
		command = ret.scratchpad_command,
		rule = { class = ret.scratchpad_class },
		sticky = false,
		autoclose = false,
		floating = true,
		geometry = ret.geometry,
		reapply = true,
		dont_focus_before_close = true,
		-- rubato = {
		--     x = library.animation:new{
		--         easing = library.animation.easing.inBounce,
		--         pos = ret.x,
		--         duration = 1.5
		--     },
		--     y = library.animation:new{
		--         easing = library.animation.easing.inBounce,
		--         pos = ret.y,
		--         duration = 1.5
		--     }
		-- }
	})

	-- ret.scratchpad:connect_signal("turn_on", function()
	--     ret.scratchpad.rubato.x.easing = library.animation.easing.inBounce
	--     ret.scratchpad.rubato.y.easing = library.animation.easing.inBounce
	-- end)

	-- ret.scratchpad:connect_signal("turn_off", function()
	--     ret.scratchpad.rubato.x.easing = library.animation.easing.outBounce
	--     ret.scratchpad.rubato.y.easing = library.animation.easing.outBounce
	-- end)

	awful.keyboard.append_global_keybindings({
		awful.key({
			modifiers = ret.scratchpad_modifiers,
			key = ret.key,
			group = "apps",
			description = "toggle " .. ret.id .. " scratchpad ",
			on_press = function()
				ret:scratchpad_toggle()
			end,
		}),
	})

	awful.keyboard.append_global_keybindings({
		awful.key({
			modifiers = ret.launch_modifiers,
			key = ret.key,
			group = "apps",
			description = "launch " .. ret.id,
			on_press = function()
				ret:toggle()
			end,
		}),
	})
end

function shortcuts:init()
	local file = filesystem.file.new_for_path(DATA_PATH)
	file:read(function(error, content)
		if error == nil then
			local json = json.decode(content) or {}
			for _, app in ipairs(json) do
				shortcuts:new(app)
			end
		end
	end)
end

local function new()
	local ret = gobject({})
	gtable.crush(ret, shortcuts, true)

	ret._private = {}

	return ret
end

if not instance then
	instance = new()
end
return instance
