-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local unpack = unpack or table.unpack -- luacheck: globals unpack (compatibility with Lua 5.1)
local Gio = require("lgi").Gio
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gcolor = require("gears.color")
local gtimer = require("gears.timer")
local wibox = require("wibox")
local beautiful = require("beautiful")
local Color = require("external.lua-color")
local helpers = require("helpers")
local sanitize_filename = helpers.string.sanitize_filename
local filesystem = require("external.filesystem")
local json = require("external.json")
local string = string
local ipairs = ipairs
local pairs = pairs
local table = table
local math = math
local os = os
local capi = {
	awesome = awesome,
	root = root,
	screen = screen,
	client = client,
}

local theme = {}
local instance = nil

local WALLPAPERS_PATH = filesystem.filesystem.get_awesome_config_dir("assets/wallpapers")
local GTK_THEME_FLAT_COLOR_PATH = filesystem.filesystem.get_awesome_config_dir("assets/gtk-themes/FlatColor")
local GTK_THEME_LINEA_NORD_COLOR = filesystem.filesystem.get_awesome_config_dir("assets/gtk-themes/linea-nord-color")
local GTK_CONFIG_FILE_PATH = filesystem.filesystem.get_xdg_config_dir("gtk-3.0") .. "settings.ini"
local INSTALLED_GTK_THEMES_PATH = os.getenv("HOME") .. "/.local/share/themes/"
local ALT_INSTALLED_GTK_THEMES_PATH = os.getenv("HOME") .. "/.themes/"
local BASE_TEMPLATES_PATH = filesystem.filesystem.get_awesome_config_dir("assets/templates")
local BACKGROUND_PATH = filesystem.filesystem.get_cache_dir() .. "wallpaper.png"
local GENERATED_TEMPLATES_PATH = filesystem.filesystem.get_cache_dir("templates")
local WAL_CACHE_PATH = filesystem.filesystem.get_xdg_cache_home("wal")
local RUN_AS_ROOT_SCRIPT_PATH = filesystem.filesystem.get_awesome_config_dir("scripts") .. "run-as-root.sh"
local COLOR_PICKER_SCRIPT_PATH = filesystem.filesystem.get_awesome_config_dir("scripts") .. "color-picker.lua"
local THUMBNAIL_PATH = filesystem.filesystem.get_cache_dir("thumbnails/wallpapers/100-70")

local PICTURES_MIMETYPES = {
	["application/pdf"] = "lximage", -- AI
	["image/x-ms-bmp"] = "lximage", -- BMP
	["application/postscript"] = "lximage", -- EPS
	["image/gif"] = "lximage", -- GIF
	["application/vnd.microsoft.icon"] = "lximage", -- ICo
	["image/jpeg"] = "lximage", -- JPEG
	["image/jp2"] = "lximage", -- JPEG 2000
	["image/png"] = "lximage", -- PNG
	["image/vnd.adobe.photoshop"] = "lximage", -- PSD
	["image/svg+xml"] = "lximage", -- SVG
	["image/tiff"] = "lximage", -- TIFF
	["image/webp"] = "lximage", -- webp
}

local function generate_colorscheme(self, wallpaper, reset, light)
	if self:get_colorschemes()[wallpaper] ~= nil and reset ~= true then
		self:emit_signal("colorscheme::generation::success", self:get_colorschemes()[wallpaper], wallpaper, false)
		return
	end
	self:emit_signal("colorscheme::generation::start")

	local color_count = 16

	local function imagemagick()
		local raw_colors = {}
		local cmd = string.format("magick %s -resize 25%% -colors %d -unique-colors txt:-", wallpaper, color_count)
		awful.spawn.easy_async_with_shell(cmd, function(stdout)
			for line in stdout:gmatch("[^\r\n]+") do
				local hex = line:match("#(.*) s")
				if hex ~= nil then
					hex = "#" .. string.sub(hex, 1, 6)
					table.insert(raw_colors, hex)
				end
			end

			if #raw_colors < 16 then
				if color_count < 37 then
					print("Imagemagick couldn't generate a palette. Trying a larger palette size " .. color_count)
					color_count = color_count + 1
					imagemagick()
					return
				else
					print("Imagemagick couldn't generate a suitable palette, using a default colorscheme instead")
					self:emit_signal("colorscheme::generation::error", wallpaper)
					local colors = {
						"#2E3440",
						"#88C0D0",
						"#BF616A",
						"#5E81AC",
						"#EBCB8B",
						"#A3BE8C",
						"#D08770",
						"#E5E9F0",
						"#4C566A",
						"#88C0D0",
						"#BF616A",
						"#5E81AC",
						"#EBCB8B",
						"#A3BE8C",
						"#D08770",
						"#8FBCBB",
					}
					self:get_colorschemes()[wallpaper] = colors
					self:save_colorscheme()

					if wallpaper == self:get_selected_colorscheme() then
						self:emit_signal("colorscheme::generation::success", colors, wallpaper, true)
					end
					return
				end
			end

			local colors = raw_colors
			for index = 2, 9 do
				colors[index] = colors[index + 7]
			end

			for index = 10, 15 do
				colors[index] = colors[index - 8]
			end

			if light == true then
				local color1 = colors[1]

				for _, color in ipairs(colors) do
					color = helpers.color.change_saturation(color, 0.5)
				end

				colors[1] = helpers.color.lighten(raw_colors[#raw_colors], 0.85)
				colors[8] = color1
				colors[9] = helpers.color.darken(raw_colors[#raw_colors], 0.4)
				colors[16] = raw_colors[1]
			else
				if string.sub(colors[1], 2, 2) ~= "0" then
					colors[1] = helpers.color.darken(colors[1], 0.4)
				end
				colors[8] = helpers.color.blend(colors[8], "#EEEEEE")
				colors[9] = helpers.color.darken(colors[8], 0.3)
				colors[16] = helpers.color.blend(colors[16], "#EEEEEE")
			end

			local sorted_colors = gtable.clone({ unpack(colors, 2, 7) })
			colors[2] = helpers.color.closet_color(sorted_colors, "#FF0000")
			colors[3] = helpers.color.closet_color(sorted_colors, "#00FF00")
			colors[4] = helpers.color.closet_color(sorted_colors, "#FFFF00")
			colors[5] = helpers.color.closet_color(sorted_colors, "#800080")
			colors[6] = helpers.color.closet_color(sorted_colors, "#FF00FF")
			colors[7] = helpers.color.closet_color(sorted_colors, "#0000FF")

			local added_sat = light and 0.5 or 0.3
			local sign = light and -1 or 1

			for index = 10, 15 do
				local _, __, l = Color(colors[index - 8]):hsl()
				colors[index] = helpers.color.lighten(colors[index - 8], sign * l * 0.3)
				colors[index] = helpers.color.saturate(colors[index - 8], added_sat)
			end

			colors[9] = helpers.color.lighten(colors[1], sign * 0.098039216)
			colors[16] = helpers.color.lighten(colors[8], sign * 0.235294118)

			self:get_colorschemes()[wallpaper] = colors
			self:save_colorscheme()
			self:emit_signal("colorscheme::generation::success", colors, wallpaper, true)
		end)
	end

	if self._private.generate_colorscheme_debouncer ~= nil and self._private.generate_colorscheme_debouncer.started then
		self._private.generate_colorscheme_debouncer:stop()
	end
	self._private.generate_colorscheme_debouncer = gtimer({
		timeout = 1,
		autostart = true,
		single_shot = true,
		callback = function()
			imagemagick()
		end,
	})
end

local function reload_gtk()
	local refresh_gsettings = [[ gsettings set org.gnome.desktop.interface \
gtk-theme '%s' && sleep 0.1 && gsettings set \
org.gnome.desktop.interface gtk-theme '%s'
]]

	local refresh_xfsettings = [[ xfconf-query -c xsettings -p /Net/ThemeName -s \
'%s' && sleep 0.1 && xfconf-query -c xsettings -p \
/Net/ThemeName -s '%s'
]]

	local file = filesystem.file.new_for_path(GTK_CONFIG_FILE_PATH)
	file:read(function(error, content)
		if error == nil then
			local gtk_theme = content:match("gtk%-theme%-name=([^\n]+)")

			helpers.run.is_installed("gsettings", function(is_installed)
				if is_installed == true then
					awful.spawn.with_shell(string.format(refresh_gsettings, gtk_theme, gtk_theme))
				end
			end)

			helpers.run.is_installed("xfconf-query", function(is_installed)
				if is_installed == true then
					awful.spawn.with_shell(string.format(refresh_xfsettings, gtk_theme, gtk_theme))
				end
			end)

			helpers.run.is_installed("xsettingsd", function(is_installed)
				if is_installed == true then
					local path = os.tmpname()
					local file = filesystem.file.new_for_path(path)

					file:write(string.format('Net/ThemeName "%s" \n', gtk_theme), function(error)
						if error == nil then
							awful.spawn(string.format("timeout 0.2s xsettingsd -c %s", path), false)
						end
					end)
				end
			end)
		end
	end)
end

local function on_finished_generating()
	gtimer.start_new(5, function()
		reload_gtk()
		return false
	end)
end

local function generate_sequences(colors)
	local function set_special(index, color, alpha)
		if (index == 11 or index == 708) and alpha ~= 100 then
			return string.format("\27]%s;[%s]%s\27\\", index, alpha, color)
		end

		return string.format("\27]%s;%s\27\\", index, color)
	end

	local function set_color(index, color)
		return string.format("\27]4;%s;%s\27\\", index, color)
	end

	local sequences = ""

	for index, color in ipairs(colors) do
		sequences = sequences .. set_color(index - 1, color)
	end

	sequences = sequences .. set_special(10, colors[16])
	sequences = sequences .. set_special(11, colors[1], 0)
	sequences = sequences .. set_special(12, colors[16])
	sequences = sequences .. set_special(13, colors[16])
	sequences = sequences .. set_special(17, colors[16])
	sequences = sequences .. set_special(19, colors[1])
	sequences = sequences .. set_color(232, colors[1])
	sequences = sequences .. set_color(256, colors[16])
	sequences = sequences .. set_color(257, colors[1])
	sequences = sequences .. set_special(708, colors[1], 0)

	local file = filesystem.file.new_for_path(GENERATED_TEMPLATES_PATH .. "sequences")
	file:write(sequences)

	-- Backwards compatibility with wal/wpgtk
	local file = filesystem.file.new_for_path(WAL_CACHE_PATH .. "sequences")
	file:write(sequences)

	for index = 0, 20 do
		local file = filesystem.file.new_for_path("/dev/pts/" .. index)
		file:exists(function(error, exists)
			if error == nil and exists == true then
				file:write_root(sequences)
			end
		end)
	end
end

local function replace_template_colors(color, color_name, line)
	color = Color(color)

	if line:match("{" .. color_name .. ".rgba}") then
		local string = string.format("%s, %s, %s, %s", color.r, color.g, color.b, color.a)
		return line:gsub("{" .. color_name .. ".rgba}", string)
	elseif line:match("{" .. color_name .. ".rgb}") then
		local string = string.format("%s, %s, %s", color.r, color.g, color.b)
		return line:gsub("{" .. color_name .. ".rgb}", string)
	elseif line:match("{" .. color_name .. ".octal}") then
		local string = string.format("%s, %s, %s, %s", color.r, color.g, color.b, color.a)
		return line:gsub("{" .. color_name .. "%.octal}", string)
	elseif line:match("{" .. color_name .. ".xrgba}") then
		local string = string.format("%s/%s/%s/%s", color.r, color.g, color.b, color.a)
		return line:gsub("{" .. color_name .. ".xrgba}", string)
	elseif line:match("{" .. color_name .. ".strip}") then
		local string = tostring(color):gsub("#", "")
		return line:gsub("{" .. color_name .. ".strip}", string)
	elseif line:match("{" .. color_name .. ".red}") then
		return line:gsub("{" .. color_name .. ".red}", color.r)
	elseif line:match("{" .. color_name .. ".green}") then
		return line:gsub("{" .. color_name .. ".green}", color.g)
	elseif line:match("{" .. color_name .. ".blue}") then
		return line:gsub("{" .. color_name .. ".blue}", color.b)
	elseif line:match("{" .. color_name .. ".alpha}") then
		return line:gsub("{" .. color_name .. ".alpha}", color.a * 100)
	elseif line:match("{" .. color_name .. "}") then
		return line:gsub("{" .. color_name .. "}", tostring(color))
	end
end

local function generate_templates(self)
	filesystem.filesystem.scan(BASE_TEMPLATES_PATH, function(error, files)
		if error == nil and files then
			for index, file in ipairs(files) do
				local name = file.name
				if name:match(".base") ~= nil then
					local template_path = BASE_TEMPLATES_PATH .. name
					local file = filesystem.file.new_for_path(template_path)
					file:read(function(error, content)
						if error == nil then
							local lines = {}
							local users = {}
							local copy_to = {}

							if content ~= nil then
								for line in content:gmatch("[^\r\n]+") do
									if line:match("{{") then
										line = line:gsub("{{", "{")
									end
									if line:match("}}") then
										line = line:gsub("}}", "}")
									end

									if line:match("user=") then
										local user = line:gsub("user=", "")
										table.insert(users, user)
										line = ""
									end
									if line:match("copy_to=") then
										local path = line:gsub("copy_to=", "")
										table.insert(copy_to, path)
										line = ""
									end

									local colors = self:get_active_colorscheme_colors()

									for index = 0, 15 do
										local color = replace_template_colors(colors[index + 1], "color" .. index, line)
										if color ~= nil then
											line = color
										end
									end

									local background = replace_template_colors(colors[1], "background", line)
									if background ~= nil then
										line = background
									end

									local foreground = replace_template_colors(colors[16], "foreground", line)
									if foreground ~= nil then
										line = foreground
									end

									local cursor = replace_template_colors(colors[16], "cursor", line)
									if cursor ~= nil then
										line = cursor
									end

									if line:match("{wallpaper}") then
										line = line:gsub("{wallpaper}", self:get_active_wallpaper())
									end

									table.insert(lines, line)
								end
							end

							local same_user = false
							if #users > 0 then
								for _, user in ipairs(users) do
									if user == os.getenv("USER") then
										same_user = true
									end
								end
								if same_user == false then
									return
								end
							end

							-- Store the output as a string
							local output = table.concat(lines, "\n")

							-- Get the name of the file
							name = name:gsub("%.base$", "")

							-- Save to ~/.cache/awesome/templates
							local file = filesystem.file.new_for_path(GENERATED_TEMPLATES_PATH .. name)
							file:write(output)

							-- Backwards compatibility with wal/wpgtk
							local file = filesystem.file.new_for_path(WAL_CACHE_PATH .. name)
							file:write(output)

							-- Save to addiontal location specified in the template file
							for _, path in ipairs(copy_to) do
								path = path:gsub("~", os.getenv("HOME"))
								if path:match(os.getenv("HOME")) then
									local file = filesystem.file.new_for_path(path)
									file:write(output)
								else
									awful.spawn.with_shell(
										RUN_AS_ROOT_SCRIPT_PATH
											.. " 'cp -r "
											.. WAL_CACHE_PATH
											.. name
											.. " "
											.. path
											.. "'"
									)
								end
							end

							if index >= #files then
								on_finished_generating()
							end
						end
					end)
				end
			end
		end
	end)
end

local function install_gtk_theme()
	awful.spawn(string.format("cp -r %s %s", GTK_THEME_FLAT_COLOR_PATH, INSTALLED_GTK_THEMES_PATH), false)
	awful.spawn(string.format("cp -r %s %s", GTK_THEME_LINEA_NORD_COLOR, INSTALLED_GTK_THEMES_PATH), false)

	awful.spawn(string.format("cp -r %s %s", GTK_THEME_FLAT_COLOR_PATH, ALT_INSTALLED_GTK_THEMES_PATH), false)
	awful.spawn(string.format("cp -r %s %s", GTK_THEME_LINEA_NORD_COLOR, ALT_INSTALLED_GTK_THEMES_PATH), false)
end

local function image_wallpaper(self, screen)
	local widget = wibox.widget({
		widget = wibox.widget.imagebox,
		resize = true,
		horizontal_fit_policy = "fit",
		vertical_fit_policy = "fit",
		image = self:get_active_wallpaper(),
	})

	self._private.wallpaper_widget = widget

	awful.wallpaper({
		screen = screen,
		widget = widget,
	})
end

local function mountain_wallpaper(self, screen)
	local colors = self:get_active_wallpaper_colors()

	local widget = wibox.widget({
		layout = wibox.layout.stack,
		{
			widget = wibox.container.background,
			id = "background",
			bg = {
				type = "linear",
				from = { 0, 0 },
				to = { 0, 100 },
				stops = {
					{ 0, beautiful.colors.random_accent_color(colors) },
					{ 0.75, beautiful.colors.random_accent_color(colors) },
					{ 1, beautiful.colors.random_accent_color(colors) },
				},
			},
		},
		{
			widget = wibox.widget.imagebox,
			resize = true,
			horizontal_fit_policy = "fit",
			vertical_fit_policy = "fit",
			image = beautiful.mountain_background,
		},
	})

	self._private.wallpaper_widget = widget

	awful.wallpaper({
		screen = screen,
		widget = widget,
	})
end

local function digital_sun_wallpaper(self, screen)
	local colors = self:get_active_wallpaper_colors()

	local widget = wibox.widget({
		fit = function(_, width, height)
			return width, height
		end,
		draw = function(self, _, cr, width, height)
			cr:set_source(gcolor({
				type = "linear",
				from = { 0, 0 },
				to = { 0, height },
				stops = { { 0, colors[1] }, { 0.75, colors[9] }, { 1, colors[1] } },
			}))
			cr:paint()
			-- Clip the first 33% of the screen
			cr:rectangle(0, 0, width, height / 3)

			-- Clip-out some increasingly large sections of add the sun "bars"
			for i = 0, 6 do
				cr:rectangle(0, height * 0.28 + i * (height * 0.055 + i / 2), width, height * 0.055)
			end
			cr:clip()

			-- Draw the sun
			cr:set_source(gcolor({
				type = "linear",
				from = { 0, 0 },
				to = { 0, height },
				stops = {
					{ 0, beautiful.colors.random_accent_color(colors) },
					{ 1, beautiful.colors.random_accent_color(colors) },
				},
			}))
			cr:arc(width / 2, height / 2, height * 0.35, 0, math.pi * 2)
			cr:fill()

			-- Draw the grid
			local lines = width / 8
			cr:reset_clip()
			cr:set_line_width(0.5)
			cr:set_source(gcolor(beautiful.colors.random_accent_color(colors)))

			for i = 1, lines do
				cr:move_to(-width + i * math.sin(i * (math.pi / (lines * 2))) * 30, height)
				cr:line_to(width / 4 + i * ((width / 2) / lines), height * 0.75 + 2)
				cr:stroke()
			end

			for i = 1, 10 do
				cr:move_to(0, height * 0.75 + i * 30 + i * 2)
				cr:line_to(width, height * 0.75 + i * 30 + i * 2)
				cr:stroke()
			end
		end,
	})

	self._private.wallpaper_widget = widget

	awful.wallpaper({
		screen = screen,
		widget = widget,
	})
end

local function binary_wallpaper(self, screen)
	local function binary()
		local ret = {}
		for _ = 1, 30 do
			for _ = 1, 100 do
				table.insert(ret, math.random() > 0.5 and 1 or 0)
			end
			table.insert(ret, "\n")
		end

		return table.concat(ret)
	end

	local colors = self:get_active_wallpaper_colors()

	local widget = wibox.widget({
		widget = wibox.layout.stack,
		{
			widget = wibox.container.background,
			fg = beautiful.colors.random_accent_color(colors),
			{
				widget = wibox.widget.textbox,
				halign = "center",
				valign = "center",
				markup = "<tt><b>[SYSTEM FAILURE]</b></tt>",
			},
		},
		{
			widget = wibox.widget.textbox,
			halign = "center",
			valign = "center",
			wrap = "word",
			text = binary(),
		},
	})

	self._private.wallpaper_widget = widget

	awful.wallpaper({
		screen = screen,
		bg = colors[1],
		fg = beautiful.colors.random_accent_color(colors),
		widget = widget,
	})
end

local function get_we_wallpaper_id(path)
	local last_slash_pos = path:find("/[^/]*$")
	if last_slash_pos then
		local prefix = path:sub(1, last_slash_pos - 1)
		local second_to_last_slash_pos = prefix:find("/[^/]*$")

		if second_to_last_slash_pos then
			local substring = prefix:sub(second_to_last_slash_pos + 1, last_slash_pos - 1)
			return substring
		end
	end
end

local function we_error_handler(self)
	if DEBUG then
		return
	end

	local id = get_we_wallpaper_id(self:get_active_wallpaper())
	local test_cmd = string.format(
		"%s --assets-dir %s %s --fps %s --class linux-wallpaperengine --x %s --y %s --width %s --height %s",
		self:get_wallpaper_engine_command(),
		self:get_wallpaper_engine_assets_folder(),
		self:get_wallpaper_engine_workshop_folder() .. "/" .. id,
		self:get_wallpaper_engine_fps(),
		0,
		0,
		1,
		1
	)

	-- I'm not sure why, but running wallpaper engine inside easy_async_with_shell
	-- results in weird issues, so using it only for error handling then kill it
	-- and spawn a new one using .spawn
	local pid = awful.spawn.easy_async_with_shell(test_cmd, function(_, stderr, __, exitcode)
		stderr = helpers.string.trim(stderr)
		if stderr ~= "" then
			local crashed = exitcode == 6
			self:emit_signal("wallpaper_engine::error", stderr, crashed)
		end
	end)
	gtimer.start_new(1, function()
		awful.spawn("kill -9 " .. pid, false)
		return false
	end)
end

local function we_wallpaper(self, screen)
	if DEBUG then
		return
	end

	local id = get_we_wallpaper_id(self:get_active_wallpaper())
	local cmd = string.format(
		"%s --assets-dir %s %s --fps %s --class linux-wallpaperengine --x %s --y %s --width %s --height %s",
		self:get_wallpaper_engine_command(),
		self:get_wallpaper_engine_assets_folder(),
		self:get_wallpaper_engine_workshop_folder() .. "/" .. id,
		self:get_wallpaper_engine_fps(),
		screen.geometry.x,
		screen.geometry.y,
		screen.geometry.width,
		screen.geometry.height
	)
	awful.spawn.with_shell(cmd)
end

local function sort_wallpapers(self)
	table.sort(self._private.wallpapers, function(a, b)
		return a.name < b.name
	end)

	table.sort(self._private.we_wallpapers, function(a, b)
		return a.name < b.name
	end)
end

local function on_wallpapers_updated(self)
	self:set_selected_tab(self:get_selected_tab())

	if gtable.count_keys(self:get_wallpapers()) > 0 then
		self:set_selected_colorscheme(self:get_wallpapers()[1].path, "image")
	end
	if gtable.count_keys(self:get_wallpapers_and_we_wallpapers()) > 0 then
		self:set_selected_colorscheme(self:get_wallpapers_and_we_wallpapers()[1].path, "mountain")
		self:set_selected_colorscheme(self:get_wallpapers_and_we_wallpapers()[1].path, "digital_sun")
		self:set_selected_colorscheme(self:get_wallpapers_and_we_wallpapers()[1].path, "binary")
	end
	if gtable.count_keys(self:get_we_wallpapers()) > 0 then
		self:set_selected_colorscheme(self:get_we_wallpapers()[1].path, "wallpaper_engine")
	end

	self:emit_signal(
		"wallpapers",
		self:get_wallpapers(),
		self:get_wallpapers_and_we_wallpapers(),
		self:get_we_wallpapers()
	)
end

local function scan_wallpapers(self)
	self._private.wallpapers = {}
	self._private.we_wallpapers = {}

	filesystem.filesystem.make_directory_with_parents(THUMBNAIL_PATH, function()
		filesystem.filesystem.scan(WALLPAPERS_PATH, function(error, files)
			if error == nil and files then
				for _, file in ipairs(files) do
					local mimetype = Gio.content_type_guess(file.full_path)
					if PICTURES_MIMETYPES[mimetype] then
						helpers.ui.scale_image_save(
							file.full_path,
							THUMBNAIL_PATH .. file.name,
							100,
							70,
							function(image)
								table.insert(self._private.wallpapers, {
									uid = file.full_path,
									path = file.full_path,
									thumbnail = image,
									name = file.name,
								})
							end
						)
					end
				end
			end

			filesystem.filesystem.scan(self:get_wallpaper_engine_workshop_folder(), function(error, files)
				if error == nil and files then
					for index, file in ipairs(files) do
						local mimetype = Gio.content_type_guess(file.full_path)
						if PICTURES_MIMETYPES[mimetype] then
							local json_file = filesystem.file.new_for_path(file.path_no_name .. "project.json")
							json_file:read(function(error, content)
								if error == nil then
									local name = json.decode(content).title
									helpers.ui.scale_image_save(
										file.full_path,
										THUMBNAIL_PATH .. sanitize_filename(name),
										100,
										70,
										function(image)
											table.insert(self._private.we_wallpapers, {
												uid = file.full_path,
												path = file.full_path,
												thumbnail = image,
												name = name,
											})

											if index == #files then
												sort_wallpapers(self)
												on_wallpapers_updated(self)
											end
										end
									)
								elseif index == #files then
									sort_wallpapers(self)
									on_wallpapers_updated(self)
								end
							end)
						end
					end
				else
					sort_wallpapers(self)
					on_wallpapers_updated(self)
				end
			end)
		end)
	end)
end

local function watch_wallpapers_changes(self)
	if self._private.watch_wallpapers_changes_debouncer == nil then
		self._private.watch_wallpapers_changes_debouncer = gtimer({
			timeout = 5,
			autostart = true,
			single_shot = true,
			callback = function()
				scan_wallpapers(self)
			end,
		})
	end

	local wallpapers_watcher = helpers.inotify:watch(WALLPAPERS_PATH, {
		helpers.inotify.Events.create,
		helpers.inotify.Events.delete,
		helpers.inotify.Events.moved_from,
		helpers.inotify.Events.moved_to,
	})
	wallpapers_watcher:connect_signal("event", function()
		self._private.watch_wallpapers_changes_debouncer:again()
	end)

	self._private.we_wallpapers_watcher = helpers.inotify:watch(self:get_wallpaper_engine_workshop_folder(), {
		helpers.inotify.Events.create,
		helpers.inotify.Events.delete,
		helpers.inotify.Events.moved_from,
		helpers.inotify.Events.moved_to,
	})
	self._private.we_wallpapers_watcher:connect_signal("event", function()
		self._private.watch_wallpapers_changes_debouncer:again()
	end)
end

-- Colorschemes
function theme:save_colorscheme()
	helpers.settings["theme.colorschemes"] = self._private.colorschemes
end

function theme:get_colorschemes()
	if self._private.colorschemes == nil then
		self._private.colorschemes = {}
		local colorschemes = helpers.settings["theme.colorschemes"]
		for path, colorscheme in pairs(colorschemes) do
			path = path:gsub("~", os.getenv("HOME"))
			self._private.colorschemes[path] = colorscheme
		end
	end

	return self._private.colorschemes
end

function theme:reset_colorscheme()
	local bg = self:get_selected_colorscheme_colors()[1]
	local light = not helpers.color.is_dark(bg)
	generate_colorscheme(self, self:get_selected_colorscheme(), true, light)
end

function theme:toggle_dark_light()
	local bg = self:get_selected_colorscheme_colors()[1]
	local light = helpers.color.is_dark(bg)
	generate_colorscheme(self, self:get_selected_colorscheme(), true, light)
end

function theme:set_color(index, color)
	if color == nil then
		awful.spawn.easy_async(
			COLOR_PICKER_SCRIPT_PATH .. " '" .. self:get_selected_colorscheme_colors()[index] .. "'",
			function(stdout)
				stdout = helpers.string.trim(stdout)
				if stdout ~= "" and stdout ~= nil then
					self:get_selected_colorscheme_colors()[index] = stdout
					self:emit_signal(
						"colorscheme::generation::success",
						self:get_selected_colorscheme_colors(),
						self:get_selected_colorscheme(),
						true
					)
				end
			end
		)
	else
		self:get_selected_colorscheme_colors()[index] = color
		self:emit_signal(
			"colorscheme::generation::success",
			self:get_selected_colorscheme_colors(),
			self:get_selected_colorscheme(),
			true
		)
	end
end

-- Wallpaper
function theme:set_wallpaper(wallpaper, type, is_startup)
	self._private.active_wallpaper = wallpaper
	helpers.settings["theme.active_wallpaper"] = wallpaper

	type = type or self:get_selected_tab()
	self._private.wallpaper_type = type
	helpers.settings["theme.wallpaper_type"] = type

	if type == "wallpaper_engine" then
		we_error_handler(self)
	end

	for s in capi.screen do
		local wallpaper_engine_instances = helpers.client.find({
			class = "linux-wallpaperengine",
			screen = s,
		})
		for _, wallpaper_engine_instance in ipairs(wallpaper_engine_instances) do
			wallpaper_engine_instance:kill()
		end

		if self:get_wallpaper_type() == "image" then
			image_wallpaper(self, s)
		elseif self:get_wallpaper_type() == "mountain" then
			mountain_wallpaper(self, s)
		elseif self:get_wallpaper_type() == "digital_sun" then
			digital_sun_wallpaper(self, s)
		elseif self:get_wallpaper_type() == "binary" then
			binary_wallpaper(self, s)
		elseif self:get_wallpaper_type() == "wallpaper_engine" then
			we_wallpaper(self, s)
		end
	end

	if self:get_wallpaper_type() ~= "wallpaper_engine" then
		wibox.widget.draw_to_svg_file(
			self._private.wallpaper_widget,
			BACKGROUND_PATH,
			capi.screen.primary.geometry.width,
			capi.screen.primary.geometry.height
		)
		capi.awesome.emit_signal("wallpaper::changed", BACKGROUND_PATH, is_startup)
	end
end

function theme:get_wallpaper_path()
	return BACKGROUND_PATH
end

function theme:get_wallpaper_type()
	if self._private.wallpaper_type == nil then
		self._private.wallpaper_type = helpers.settings["theme.wallpaper_type"]
	end

	return self._private.wallpaper_type
end

function theme:get_active_wallpaper()
	if self._private.active_wallpaper == nil then
		self._private.active_wallpaper = helpers.settings["theme.active_wallpaper"]:gsub("~", os.getenv("HOME"))
	end

	return self._private.active_wallpaper
end

function theme:get_active_wallpaper_colors()
	return self:get_colorschemes()[self:get_active_wallpaper()]
end

function theme:get_wallpapers()
	return self._private.wallpapers
end

function theme:get_we_wallpapers()
	return self._private.we_wallpapers
end

function theme:get_wallpapers_and_we_wallpapers()
	return gtable.join(self._private.wallpapers, self._private.we_wallpapers)
end

function theme:preview_we_wallpaper(we_wallpaper, geometry)
	local id = get_we_wallpaper_id(we_wallpaper)
	local cmd = string.format(
		"%s --assets-dir %s %s --class linux-wallpaperengine-preview --fps %s --x %s --y %s",
		self:get_wallpaper_engine_command(),
		self:get_wallpaper_engine_assets_folder(),
		self:get_wallpaper_engine_workshop_folder() .. "/" .. id,
		self:get_wallpaper_engine_fps(),
		geometry.x + geometry.width,
		geometry.y
	)
	awful.spawn.with_shell(cmd)
end

-- Active colorscheme
function theme:set_colorscheme(colorscheme)
	self._private.active_colorscheme = colorscheme
	helpers.settings["theme.active_colorscheme"] = colorscheme

	self:save_colorscheme()

	beautiful.reload()
	install_gtk_theme()
	generate_templates(self)
	generate_sequences(self:get_active_colorscheme_colors())
end

function theme:get_active_colorscheme()
	if self._private.active_colorscheme == nil then
		self._private.active_colorscheme = helpers.settings["theme.active_colorscheme"]:gsub("~", os.getenv("HOME"))
	end

	return self._private.active_colorscheme
end

function theme:get_active_colorscheme_colors()
	local colorscheme_colors = self:get_colorschemes()[self:get_active_colorscheme()]
	return colorscheme_colors
end

-- Selected colorscheme
function theme:set_selected_colorscheme(colorscheme, tab)
	self._private[tab].selected_colorscheme = colorscheme
	generate_colorscheme(self, colorscheme)
end

function theme:get_selected_colorscheme(tab)
	tab = tab or self:get_selected_tab()
	return self._private[tab].selected_colorscheme
end

function theme:get_selected_colorscheme_colors()
	return self:get_colorschemes()[self:get_selected_colorscheme()]
end

function theme:set_selected_tab(tab)
	self._private.selected_tab = tab
	local colorscheme = self:get_selected_colorscheme()
	if colorscheme then
		self:set_selected_colorscheme(colorscheme, tab)
	end
	self:emit_signal("tab::select", tab)
end

function theme:get_selected_tab()
	return self._private.selected_tab or "image"
end

-- Command after generation
function theme:set_run_on_set(run_on_set)
	self._private.run_on_set = run_on_set
	helpers.settings["theme.run_on_set"] = run_on_set
end

function theme:get_run_on_set()
	if self._private.run_on_set == nil then
		self._private.run_on_set = helpers.settings["theme.run_on_set"]
	end

	return self._private.run_on_set
end

-- Wallpaper engine command
function theme:set_wallpaper_engine_command(wallpaper_engine_command)
	self._private.wallpaper_engine_command = wallpaper_engine_command
	helpers.settings["wallpaper_engine.command"] = wallpaper_engine_command
end

function theme:get_wallpaper_engine_command()
	if self._private.wallpaper_engine_command == nil then
		self._private.wallpaper_engine_command =
			helpers.settings["wallpaper_engine.command"]:gsub("~", os.getenv("HOME"))
	end

	return self._private.wallpaper_engine_command
end

-- Wallpaper engine assets folder
function theme:set_wallpaper_engine_assets_folder(wallpaper_engine_assets_folder)
	self._private.wallpaper_engine_assets_folder = wallpaper_engine_assets_folder
	helpers.settings["wallpaper_engine.assets_folder"] = wallpaper_engine_assets_folder
end

function theme:get_wallpaper_engine_assets_folder()
	if self._private.wallpaper_engine_assets_folder == nil then
		self._private.wallpaper_engine_assets_folder =
			helpers.settings["wallpaper_engine.assets_folder"]:gsub("~", os.getenv("HOME"))
	end

	return self._private.wallpaper_engine_assets_folder
end

-- Wallpaper engine assets folder
function theme:set_wallpaper_engine_workshop_folder(wallpaper_engine_workshop_folder)
	self._private.wallpaper_engine_workshop_folder = wallpaper_engine_workshop_folder
	helpers.settings["wallpaper_engine.workshop_folder"] = wallpaper_engine_workshop_folder
	scan_wallpapers(self)

	self._private.we_wallpapers_watcher = helpers.inotify:watch(wallpaper_engine_workshop_folder, {
		helpers.inotify.Events.create,
		helpers.inotify.Events.delete,
		helpers.inotify.Events.moved_from,
		helpers.inotify.Events.moved_to,
	})
	self._private.we_wallpapers_watcher:connect_signal("event", function()
		self._private.watch_wallpapers_changes_debouncer:again()
	end)
end

function theme:get_wallpaper_engine_workshop_folder()
	if self._private.wallpaper_engine_workshop_folder == nil then
		self._private.wallpaper_engine_workshop_folder =
			helpers.settings["wallpaper_engine.workshop_folder"]:gsub("~", os.getenv("HOME"))
	end

	return self._private.wallpaper_engine_workshop_folder
end

-- Wallpaper engine fps
function theme:set_wallpaper_engine_fps(wallpaper_engine_fps)
	self._private.wallpaper_engine_fps = wallpaper_engine_fps
	helpers.settings["wallpaper_engine.fps"] = wallpaper_engine_fps

	if
		#helpers.client.find({
			class = "linux-wallpaperengine",
		}) > 0 and self:get_wallpaper_type() == "wallpaper_engine"
	then
		self:set_wallpaper(self:get_active_wallpaper(), "wallpaper_engine")
	end
end

function theme:get_wallpaper_engine_fps()
	if self._private.wallpaper_engine_fps == nil then
		self._private.wallpaper_engine_fps = helpers.settings["wallpaper_engine.fps"]
	end

	return self._private.wallpaper_engine_fps
end

local function new()
	local ret = gobject({})
	gtable.crush(ret, theme, true)

	ret._private = {}
	ret._private.image = {}
	ret._private.mountain = {}
	ret._private.digital_sun = {}
	ret._private.binary = {}
	ret._private.wallpaper_engine = {}

	gtimer.delayed_call(function()
		if
			#helpers.client.find({
				class = "linux-wallpaperengine",
			}) > 0 and ret:get_wallpaper_type() == "wallpaper_engine"
		then
			return
		end
		ret:set_wallpaper(ret:get_active_wallpaper(), ret:get_wallpaper_type(), true)
	end)

	scan_wallpapers(ret)
	watch_wallpapers_changes(ret)

	capi.client.connect_signal("request::manage", function(client)
		if client.class == "linux-wallpaperengine" and client.screen == capi.screen.primary then
			gtimer.start_new(3, function()
				if not client or not client.valid then
					return
				end

				local screenshot = awful.screenshot({
					client = client,
				})
				screenshot:refresh()
				wibox.widget.draw_to_svg_file(
					screenshot.content_widget,
					"/home/kasper/.cache/awesome/wallpaper.png",
					client.width,
					client.height
				)
				capi.awesome.emit_signal("wallpaper::changed")
				return false
			end)
		end
	end)

	capi.awesome.connect_signal("wallpaper::changed", function(background_path, is_startup)
		gtimer.start_new(5, function()
			if ret:get_run_on_set() and not is_startup then
				awful.spawn.with_shell(ret:get_run_on_set())
			end
		end)
	end)

	return ret
end

if not instance then
	instance = new()
end
return instance
