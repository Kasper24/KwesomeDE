-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gshape = require("gears.shape")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local app = require("ui.apps.app")
local beautiful = require("beautiful")
local screenshot_daemon = require("daemons.system.screenshot")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi

local instance = nil

local function separator()
    return wibox.widget {
        widget = widgets.background,
        forced_height = dpi(2),
        shape = helpers.ui.rrect(),
        bg = beautiful.colors.surface,
    }
end

local function setting_container(widget)
    return wibox.widget {
        widget = wibox.container.margin,
        margins = dpi(15),
        widget
    }
end

local function button(icon, text, on_release, on_by_default)
    local icon = wibox.widget {
        widget = widgets.text,
        halign = "center",
        color = beautiful.icons.camera_retro.color,
        text_normal_bg = beautiful.icons.camera_retro.color,
        text_on_normal_bg = beautiful.colors.transparent,
        icon = icon
    }

    local text = wibox.widget {
        widget = widgets.text,
        halign = "center",
        size = 12,
        color = beautiful.colors.on_surface,
        text_normal_bg = beautiful.colors.on_surface,
        text_on_normal_bg = beautiful.colors.transparent,
        text = text
    }

    return wibox.widget {
        widget = widgets.button.state,
        on_by_default = on_by_default,
        forced_width = dpi(120),
        forced_height = dpi(120),
        normal_bg = beautiful.colors.surface,
        on_normal_bg = beautiful.icons.camera_retro.color,
        on_release = function(self)
            on_release(self)
        end,
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            icon,
            text
        }
    }
end

local function show_cursor()
    local checkbox = wibox.widget {
        widget = widgets.checkbox,
        state = screenshot_daemon:get_show_cursor(),
        handle_active_color = beautiful.icons.camera_retro.color,
        on_turn_on = function()
            screenshot_daemon:set_show_cursor(true)
        end,
        on_turn_off = function()
            screenshot_daemon:set_show_cursor(false)
        end
    }

    local text = wibox.widget {
        widget = widgets.text,
        valign = "center",
        size = 15,
        text = "Show Cursor:"
    }

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_height = dpi(35),
        spacing = dpi(15),
        text,
        checkbox
    }
end

local function delay()
    local title = wibox.widget {
        widget = widgets.text,
        size = 15,
        text = "Delay:"
    }

    local slider = widgets.slider_text_input {
        slider_width = dpi(150),
        text_input_width = dpi(60),
        value = screenshot_daemon:get_delay(),
        round = true,
        maximum = 100,
        bar_active_color = beautiful.icons.camera_retro.color,
        selection_bg = beautiful.icons.camera_retro.color,
    }

    slider:connect_signal("property::value", function(self, value, instant)
        screenshot_daemon:set_delay(value)
    end)

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_height = dpi(35),
        spacing = dpi(15),
        title,
        slider
    }
end

local function folder_picker()
    local title = wibox.widget {
        widget = widgets.text,
        size = 15,
        text = "Folder:"
    }

    local folder_picker = wibox.widget {
        widget = widgets.picker.folder,
        text_input_forced_width = dpi(340),
        initial_value = screenshot_daemon:get_folder(),
        on_changed = function(text)
            screenshot_daemon:set_folder(text)
        end
    }

    SCREENSHOT_APP:connect_signal("request::unmanage", function()
        folder_picker:get_text_input():unfocus()
    end)

    SCREENSHOT_APP:connect_signal("unfocus", function()
        folder_picker:get_text_input():unfocus()
    end)

    SCREENSHOT_APP:connect_signal("mouse::leave", function()
        folder_picker:get_text_input():unfocus()
    end)

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_height = dpi(35),
        spacing = dpi(15),
        title,
        folder_picker
    }
end

local function main()
    local buttons = wibox.widget {
        widget = widgets.button_group.horizontal,
        on_select = function(id)
            screenshot_daemon:set_screenshot_method(id)
        end,
        values = {
            {
                id = "selection",
                button = button(beautiful.icons.scissors, "Selection")
            },
            {
                id = "screen",
                button = button(beautiful.icons.computer, "Screen")

            },
            {
                id = "window",
                button = button(beautiful.icons.window, "Window")

            },
            {
                id = "color_picker",
                button = button(beautiful.icons.palette, "Pick Color")

            },
        }
    }

    local screenshot_button = wibox.widget {
        widget = widgets.button.normal,
        forced_height = dpi(50),
        normal_bg = beautiful.icons.camera_retro.color,
        on_release = function()
            screenshot_daemon:screenshot()
        end,
        {
            widget = widgets.text,
            text_normal_bg = beautiful.colors.on_accent,
            size = 15,
            text = "Screenshot",
        }
    }

    return wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        buttons,
        {
            widget = widgets.background,
            shape = helpers.ui.rrect(),
            bg = beautiful.colors.background,
            border_width = dpi(2),
            border_color = beautiful.colors.surface,
            {
                layout = wibox.layout.fixed.vertical,
                setting_container(delay()),
                separator(),
                setting_container(show_cursor()),
                separator(),
                setting_container(folder_picker())
            }
        },
        screenshot_button
    }
end

local function new()
    SCREENSHOT_APP = app {
        title ="Screenshot",
        class = "gnome-screenshot",
        width = dpi(560),
        height = dpi(465),
        show_titlebar = true,
        widget_fn = function()
            return main()
        end
    }

    screenshot_daemon:connect_signal("started", function()
        SCREENSHOT_APP:set_hidden(true)
    end)

    screenshot_daemon:connect_signal("ended", function()
        SCREENSHOT_APP:set_hidden(false)
    end)

    screenshot_daemon:connect_signal("error::create_file", function()
        SCREENSHOT_APP:set_hidden(false)
    end)

    screenshot_daemon:connect_signal("error::create_directory", function()
        SCREENSHOT_APP:set_hidden(false)
    end)

    return SCREENSHOT_APP
end

if not instance then
    instance = new()
end
return instance
