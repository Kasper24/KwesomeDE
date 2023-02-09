-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gshape = require("gears.shape")
local ruled = require("ruled")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local record_daemon = require("daemons.system.record")
local pactl_daemon = require("daemons.hardware.pactl")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local pairs = pairs
local capi = {
    awesome = awesome
}

local record = {}
local instance = nil

local window = [[ lua -e "
    local lgi = require 'lgi'
    local Gtk = lgi.require('Gtk', '3.0')

    -- Create top level window with some properties and connect its 'destroy'
    -- signal to the event loop termination.
    local window = Gtk.Window {
    title = 'Record',
    default_width = 0,
    default_height = 0,
    on_destroy = Gtk.main_quit
    }

    if tonumber(Gtk._version) >= 3 then
    window.has_resize_grip = true
    end

    local icon = 'screen-recorder'
    pixbuf24 = Gtk.IconTheme.get_default():load_icon(icon, 24, 0)
    pixbuf32 = Gtk.IconTheme.get_default():load_icon(icon, 32, 0)
    pixbuf48 = Gtk.IconTheme.get_default():load_icon(icon, 48, 0)
    pixbuf64 = Gtk.IconTheme.get_default():load_icon(icon, 64, 0)
    pixbuf96 = Gtk.IconTheme.get_default():load_icon(icon, 96, 0)
    window:set_icon_list({pixbuf24, pixbuf32, pixbuf48, pixbuf64, pixbuf96});

    window:set_wmclass('awesome-app-record', 'awesome-app-record')

    -- Show window and start the loop.
    window:show_all()
    Gtk.main()
"
]]

local function resolution()
    local title = wibox.widget {
        widget = widgets.text,
        size = 15,
        text = "Resolution:"
    }

    local dropdown = widgets.dropdown {
        initial_value = record_daemon:get_resolution(),
        values = {
            ["7680x4320"] = "7680x4320",
            ["3440x1440"] = "3440x1440",
            ["2560x1440"] = "2560x1440",
            ["2560x1080"] = "2560x1080",
            ["1920x1080"] = "1920x1080",
            ["1600x900"] = "1600x900",
            ["1280x720"] = "1280x720",
            ["640x480"] = "640x480"
        },
        on_value_selected = function(value)
            record_daemon:set_resolution(value)
        end
    }

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_height = dpi(35),
        spacing = dpi(15),
        title,
        dropdown
    }
end

local function fps()
    local title = wibox.widget {
        widget = widgets.text,
        size = 15,
        text = "FPS:"
    }

    local value_text = wibox.widget {
        widget = widgets.text,
        size = 15,
        text = record_daemon:get_fps()
    }

    local slider = wibox.widget {
        widget = widgets.slider,
        forced_width = dpi(150),
        value = record_daemon:get_fps(),
        maximum = 360,
        bar_height = 5,
        bar_shape = helpers.ui.rrect(beautiful.border_radius),
        bar_color = beautiful.colors.surface,
        bar_active_color = beautiful.colors.random_accent_color(),
        handle_width = dpi(15),
        handle_color = beautiful.colors.on_background,
        handle_shape = gshape.circle
    }

    slider:connect_signal("property::value", function(self, value, instant)
        if instant == false then
            record_daemon:set_fps(value)
            value_text:set_text(value)
        end
    end)

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_height = dpi(35),
        spacing = dpi(15),
        title,
        slider,
        value_text
    }
end

local function delay()
    local title = wibox.widget {
        widget = widgets.text,
        size = 15,
        text = "Delay:"
    }

    local value_text = wibox.widget {
        widget = widgets.text,
        size = 15,
        text = record_daemon:get_delay()
    }

    local slider = wibox.widget {
        widget = widgets.slider,
        forced_width = dpi(150),
        value = record_daemon:get_delay(),
        maximum = 100,
        bar_height = 5,
        bar_shape = helpers.ui.rrect(beautiful.border_radius),
        bar_color = beautiful.colors.surface,
        bar_active_color = beautiful.colors.random_accent_color(),
        handle_width = dpi(15),
        handle_color = beautiful.colors.on_background,
        handle_shape = gshape.circle
    }

    slider:connect_signal("property::value", function(self, value, instant)
        if instant == false then
            record_daemon:set_delay(value)
            value_text:set_text(value)
        end
    end)

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_height = dpi(35),
        spacing = dpi(15),
        title,
        slider,
        value_text
    }
end

local function audio_source()
    local title = wibox.widget {
        widget = widgets.text,
        size = 15,
        text = "Audio Source:"
    }

    local dropdown = widgets.dropdown {
        forced_height = dpi(40),
        menu_width = dpi(700),
        on_value_selected = function(value)
            record_daemon:set_audio_source(value)
        end
    }

    local selected = false
    for _, sink in pairs(pactl_daemon:get_sinks()) do
        dropdown:add(sink.description, sink.name)
        if selected == false then
            dropdown:select(sink.description, sink.name)
            selected = true
        end
    end
    for index, source in pairs(pactl_daemon:get_sources()) do
        dropdown:add(source.description, source.name)
        if selected == false then
            dropdown:select(source.description, source.name)
            selected = true
        end
    end

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_height = dpi(35),
        spacing = dpi(15),
        title,
        dropdown
    }
end

local function folder()
    local title = wibox.widget {
        widget = widgets.text,
        size = 15,
        text = "Folder: "
    }

    local folder_text = wibox.widget {
        widget = widgets.text,
        forced_width = dpi(350),
        size = 12,
        text = record_daemon:get_folder()
    }

    local set_folder_button = wibox.widget {
        widget = widgets.button.text.normal,
        size = 15,
        text = "...",
        on_press = function()
            record_daemon:set_folder()
        end
    }

    record_daemon:connect_signal("folder::updated", function(self, folder)
        folder_text.text = folder
    end)

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_height = dpi(35),
        spacing = dpi(15),
        title,
        folder_text,
        set_folder_button
    }
end

local function format()
    local title = wibox.widget {
        widget = widgets.text,
        size = 15,
        text = "Format:"
    }

    local dropdown = widgets.dropdown {
        initial_value = record_daemon:get_format(),
        values = {
            ["mp4"] = "mp4",
            ["mov"] = "mov",
            ["webm"] = "webm",
            ["flac"] = "flac"
        },
        on_value_selected = function(value)
            record_daemon:set_format(value)
        end
    }

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_height = dpi(35),
        spacing = dpi(15),
        title,
        dropdown
    }
end

local function main(self)
    local title = wibox.widget {
        widget = widgets.text,
        bold = true,
        size = 15,
        text = "Record"
    }

    local close_button = wibox.widget {
        widget = widgets.button.text.normal,
        forced_width = dpi(50),
        forced_height = dpi(50),
        icon = beautiful.icons.xmark,
        on_release = function()
            self:hide()
        end
    }

    local record_button = wibox.widget {
        widget = widgets.button.text.normal,
        forced_width = dpi(50),
        size = 15,
        normal_bg = beautiful.colors.random_accent_color(),
        text_normal_bg = beautiful.colors.background,
        text = record_daemon:get_is_recording() and "Stop" or "Record",
        on_release = function()
            record_daemon:toggle_video()
        end
    }

    record_daemon:connect_signal("started", function()
        record_button.text = "Stop"
    end)

    record_daemon:connect_signal("ended", function()
        record_button.text = "Record"
    end)

    return wibox.widget {
        widget = wibox.container.margin,
        margins = dpi(15),
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            {
                layout = wibox.layout.align.horizontal,
                title,
                nil,
                close_button
            },
            {
                widget = wibox.container.margin,
                left = dpi(10),
                {
                    widget = wibox.layout.fixed.vertical,
                    spacing = dpi(15),
                    resolution(),
                    fps(),
                    delay(),
                    audio_source(),
                    format(),
                    folder()
                }
            },
            record_button
        }
    }
end

function record:show()
    helpers.client.run_or_raise_with_shell({
        class = "awesome-app-record"
    }, true, window)
    self._private.visible = true
end

function record:hide()
    if self._private.client ~= nil then
        self._private.client:kill()
    end
    self._private.visible = false
end

function record:toggle()
    if self._private.visible == true then
        self:hide()
    else
        self:show()
    end
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, record, true)

    ret._private = {}

    ruled.client.connect_signal("request::rules", function()
        ruled.client.append_rule {
            rule = {
                class = "awesome-app-record"
            },
            properties = {
                floating = true,
                width = dpi(550),
                height = 1,
                placement = awful.placement.centered
            },
            callback = function(c)
                ret._private.client = c

                c:connect_signal("unmanage", function()
                    ret._private.visible = false
                    ret._private.client = nil
                end)

                c.custom_titlebar = true
                c.can_resize = false
                c.can_tile = false

                -- Settings placement in properties doesn't work
                c.x = (c.screen.geometry.width / 2) - (dpi(550) / 2)
                c.y = (c.screen.geometry.height / 2) - (dpi(435) / 2)

                local titlebar = widgets.titlebar(c, {
                    position = "top",
                    size = dpi(435),
                    bg = beautiful.colors.background
                })
                titlebar:setup{ widget = main(ret) }

                capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
                    titlebar:set_bg(beautiful.colors.background)
                end)
            end
        }
    end)

    record_daemon:connect_signal("started", function()
        ret._private.client.hidden = true
    end)

    record_daemon:connect_signal("ended", function()
        ret._private.client.hidden = false
    end)

    record_daemon:connect_signal("error::create_directory", function()
        ret._private.client.hidden = false
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance
