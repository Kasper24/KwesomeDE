-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gtable = require("gears.table")
local wibox = require("wibox")
local bwidget = require("ui.widgets.background")
local tiwidget = require("ui.widgets.text_input")
local tbwidget = require("ui.widgets.button.text")
local beautiful = require("beautiful")
local helpers = require("helpers")
local filesystem = require("external.filesystem")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local folder_picker = {
    mt = {}
}

local FOLDER_PICKER_SCRIPT_PATH = filesystem.filesystem.get_awesome_config_dir("scripts") .. "folder-picker.lua"
local FILE_PICKER_SCRIPT_PATH = filesystem.filesystem.get_awesome_config_dir("scripts") .. "file-picker.lua"

function folder_picker:set_initial_value(initial_value)
    self._private.initial_value = initial_value
    self._private.text_input:set_initial(initial_value)
end

function folder_picker:set_on_changed(on_changed)
    self._private.on_changed = on_changed
end

function folder_picker:set_type(type)
    self._private.type = type
end

function folder_picker:set_text_input_forced_width(text_input_forced_width)
    self._private.text_input.forced_width = text_input_forced_width
end

function folder_picker:set_text_input_forced_height(text_input_forced_height)
    self._private.text_input.forced_height = text_input_forced_height
end

function folder_picker:set_folder_button_forced_width(folder_button_forced_width)
    self._private.folder_button.forced_width = folder_button_forced_width
end

function folder_picker:set_folder_button_forced_height(folder_button_forced_height)
    self._private.folder_button.forced_height = folder_button_forced_height
end

local function new()
    local widget = nil

    local text_input = wibox.widget {
        widget = tiwidget,
        unfocus_on_client_clicked = false,
        selection_bg = beautiful.icons.spraycan.color,
        widget_template = wibox.widget {
            widget = bwidget,
            shape = helpers.ui.rrect(),
            bg = beautiful.colors.surface,
            {
                widget = wibox.container.margin,
                margins = dpi(10),
                {
                    widget = wibox.widget.textbox,
                    id = "text_role"
                }
            }
		}
    }

    local folder_button = wibox.widget {
        widget = tbwidget.normal,
        forced_width = dpi(60),
        forced_height = dpi(35),
        size = 15,
        text_normal_bg = beautiful.colors.on_background,
        icon = beautiful.icons.folder_open,
        on_release = function()
            local script = widget._private.type == "file" and FILE_PICKER_SCRIPT_PATH or FOLDER_PICKER_SCRIPT_PATH

            awful.spawn.easy_async(script .. " '" .. widget._private.initial_value .. "'", function(stdout)
                stdout = helpers.string.trim(stdout)
                if stdout ~= "" and stdout ~= nil then
                    widget._private.on_changed(stdout)
                    text_input:set_text(stdout)
                end
            end)
        end
    }

    widget = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15),
        text_input,
        folder_button
    }

    gtable.crush(widget, folder_picker, true)

	function widget:get_text_input()
		return text_input
	end

    widget._private.initial_value = ""
    widget._private.text_input = text_input
    widget._private.folder_button = folder_button
    widget._private.text_changed = false

    text_input:connect_signal("property::text", function(self, text)
        widget._private.text_changed = true
    end)

    text_input:connect_signal("unfocus", function(self, context, text)
        if widget._private.text_changed then
            widget._private.on_changed(text)
            widget._private.text_changed = false
        end
    end)

    return widget

end

function folder_picker.mt:__call()
    return new()
end

return setmetatable(folder_picker, folder_picker.mt)