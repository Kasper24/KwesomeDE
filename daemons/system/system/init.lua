-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local notifications_daemon = require("daemons.system.notifications")
local library = require("library")
local filesystem = require("external.filesystem")
local capi = {
	awesome = awesome,
}

local PATH = filesystem.filesystem.get_awesome_config_dir("daemons/system/system/pam")
package.cpath = package.cpath .. ";" .. PATH .. "?.so;"
local pam = require("liblua_pam")

local system = {}
local instance = nil

local VERSIONS = {
	{
		version = "0.001",
		changes = {
			"Secrets are now stored in a secured way. Please install gnome-keyring and re-set your Gitlab API key and Openweather access token",
		},
	},
	{
		version = "0.002",
		changes = {
			"Settings have been re-worked. They are now stored as part of the config at ~/.config/awesome/assets/settings.data.json. Please re-set your settings!",
		},
	},
	{
		version = "0.003",
		changes = {
			"Email daemon has been improved. Please re-set your email settings!",
		},
	},
	{
		version = "0.004",
		changes = {
			"Setting files were moved to ~/.local/share/awesome",

			"You can now use your system icon theme by disabling recolor icons at the settings app->appearance->ui->recolor icons option.",

			"Font Awesome Pro icons were replaced with nerd fonts icons.",

			[[You can set custom shortcuts at ~/.local/share/awesome/shortcuts/data.json
            {
                [
                    {
                        "id": "terminal",
                        "key": "t",
                        "command": "alacritty",
                        "class": "Alacritty",
                        "scratchpad_command": "alacritty --class Scratchpad",
                        "scratchpad_class": "Scratchpad",
                        "launch_modifiers": ["Mod4", "Control"],
                        "scratchpad_modifiers": ["Mod4", "Alt"],
                        "geometry": "centered",
                        "new_animation_on_toggle": true,
                        "run_or_raise": false
                    },
                ]
            }]],

			[[You can set monitor configuration at ~/.local/share/awesome/displays/data.json
            {
                [
                    {
                        "name": "HDMI-1",
                        "width": "1920",
                        "height": "1080",
                        "x": "0",
                        "y": "0",
                        "rotate": "normal",
                        "gamma": "1.0",
                        "scale": "1.0",
                        "dpi": "96",
                        "primary": "true"
                    }
                ]
            }]],

			[[You can set power configuration at ~/.local/share/awesome/power/data.json
            {
                "screenBlank": false,
                "powerSaving": false
            }]],

			[[Theme manager has been removed.
            For a better replacement, you can visit github.com/kasper24/walltone.
            You can set wallpaper and colors at ~/.local/share/awesome/theme/data.json.
            {
                "wallpaper": "path/to/wallpaper.png",
                "colorscheme": [
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
                ]
            }]],
		},
	},
}

function system:get_versions()
	return VERSIONS
end

function system:shutdown()
	awful.spawn("systemctl poweroff", false)
end

function system:reboot()
	awful.spawn("systemctl reboot", false)
end

function system:suspend()
	self:lock()
	awful.spawn("systemctl suspend", false)
end

function system:exit()
	capi.awesome.quit()
end

function system:lock()
	notifications_daemon:block_on_locked()
	self:emit_signal("lock")
end

function system:unlock(password)
	local pam_auth = pam:auth_current_user(password)
	if pam_auth then
		notifications_daemon:unblock_on_unlocked()
		self:emit_signal("unlock")
	else
		self:emit_signal("wrong_password")
	end
end

local function system_info(self)
	gtimer.poller({
		timeout = 60,
		callback = function()
			awful.spawn.easy_async("neofetch packages", function(packages_count)
				packages_count = library.string.trim(packages_count:gsub("packages", ""))

				awful.spawn.easy_async("neofetch uptime", function(uptime)
					uptime = library.string.trim(uptime:gsub("time", ""):gsub("up  ", ""))
					self:emit_signal("info", packages_count, uptime)
				end)
			end)
		end,
	})
end

local function updates_info(self)
	local function pacman()
		awful.spawn.easy_async("checkupdates", function(stdout)
			local updates_count = 0
			for line in stdout:gmatch("[^\r\n]+") do
				updates_count = updates_count + 1
			end
			self:emit_signal("package_manager::updates", "Pacman", updates_count, stdout)
		end)
	end

	gtimer.poller({
		timeout = 60 * 60 * 24,
		callback = function()
			awful.spawn.easy_async("neofetch distro", function(distro)
				distro = library.string.trim(distro:gsub("distro ", ""))
				if distro == "Arch Linux" or distro == "EndeavourOS" or distro == "Manjaro Linux" then
					pacman()
				end
			end)
		end,
	})
end

local function find_current_version_index()
	local current_version = library.settings["kwesomede.version"]
	for index, version in ipairs(VERSIONS) do
		if version.version == current_version then
			return index
		end
	end

	return 1
end

local function check_version(self)
	local version = library.settings["kwesomede.version"]

	local last_version = VERSIONS[#VERSIONS]
	if version ~= last_version.version then
		gtimer.delayed_call(function()
			for index = find_current_version_index(), #VERSIONS do
				self:emit_signal("version::new", VERSIONS[index])
			end
			self:emit_signal("version::new::single")
			library.settings["kwesomede.version"] = last_version.version
		end)
		return true
	end

	return false
end

local function new()
	local ret = gobject({})
	gtable.crush(ret, system, true)

	check_version(ret)
	system_info(ret)
	updates_info(ret)

	return ret
end

if not instance then
	instance = new()
end
return instance
