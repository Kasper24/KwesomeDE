-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local ruled = require("ruled")
local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local beautiful = require("beautiful")
local record_daemon = require("daemons.system.record")
local pactl_daemon = require("daemons.hardware.pactl")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local pairs = pairs

local record = { }
local instance = nil

local window = [[ lua -e "
    local lgi = require 'lgi'
    local Gtk = lgi.require('Gtk', '3.0')

    -- Create top level window with some properties and connect its 'destroy'
    -- signal to the event loop termination.
    local window = Gtk.Window {
    title = 'no-one-gonna-match-this2',
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

    window:set_wmclass('Record', 'Record')

    -- Show window and start the loop.
    window:show_all()
    Gtk.main()
"
]]

local accent_color = beautiful.random_accent_color()

local function resolution()
    local title = widgets.text
    {
        size = 15,
        text = "Resolution:"
    }

    local dropdown = widgets.dropdown
    {
        initial_value = record_daemon:get_resolution(),
        values =
        {
            ["7680x4320"] = "7680x4320",
            ["3440x1440"] = "3440x1440",
            ["2560x1440"] = "2560x1440",
            ["2560x1080"] = "2560x1080",
            ["1920x1080"] = "1920x1080",
            ["1600x900"] = "1600x900",
            ["1280x720"] = "1280x720",
            ["640x480"] = "640x480",
        },
        on_value_selected = function(value)
            record_daemon:set_resolution(value)
        end
    }

    return wibox.widget
    {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15),
        title,
        dropdown
    }
end

local function fps()
    local title = widgets.text
    {
        size = 15,
        text = "FPS:"
    }

    local value_text = widgets.text
    {
        size = 15,
        text = record_daemon:get_fps(),
    }

    local plus_button = widgets.button.text.normal
    {
        forced_width = dpi(50),
        forced_height = dpi(50),
        text_normal_bg = accent_color,
        font = beautiful.circle_plus_icon.font,
        text = beautiful.circle_plus_icon.icon,
        on_release = function()
            value_text:set_text(record_daemon:increase_fps())
        end
    }

    local minus_button = widgets.button.text.normal
    {
        forced_width = dpi(50),
        forced_height = dpi(50),
        text_normal_bg = accent_color,
        font = beautiful.circle_minus_icon.font,
        text = beautiful.circle_minus_icon.icon,
        on_release = function()
            value_text:set_text(record_daemon:decrease_fps())
        end
    }

    return wibox.widget
    {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15),
        title,
        minus_button,
        value_text,
        plus_button,
    }
end

local function delay()
    local title = widgets.text
    {
        size = 15,
        text = "Delay:"
    }

    local value_text = widgets.text
    {
        size = 15,
        text = record_daemon:get_delay(),
    }

    local plus_button = widgets.button.text.normal
    {
        forced_width = dpi(50),
        forced_height = dpi(50),
        text_normal_bg = accent_color,
        font = beautiful.circle_plus_icon.font,
        text = beautiful.circle_plus_icon.icon,
        on_release = function()
            value_text:set_text(record_daemon:increase_delay())
        end
    }

    local minus_button = widgets.button.text.normal
    {
        forced_width = dpi(50),
        forced_height = dpi(50),
        text_normal_bg = accent_color,
        font = beautiful.circle_minus_icon.font,
        text = beautiful.circle_minus_icon.icon,
        on_release = function()
            value_text:set_text(record_daemon:decrease_delay())
        end
    }

    return wibox.widget
    {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15),
        title,
        minus_button,
        value_text,
        plus_button,
    }
end

local function audio_source()
    local title = widgets.text
    {
        size = 15,
        text = "Audio Source:"
    }

    local dropdown = widgets.dropdown
    {
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

    return wibox.widget
    {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15),
        title,
        dropdown
    }
end

local function folder()
    local title = widgets.text
    {
        size = 15,
        text = "Folder: "
    }

    local folder_text  = widgets.text
    {
        width = dpi(350),
        size = 12,
        text = record_daemon:get_folder(),
    }

    local set_folder_button  = widgets.button.text.normal
    {
        text_normal_bg = accent_color,
        size = 15,
        text = "...",
        on_press = function()
            record_daemon:set_folder()
        end,
    }

    record_daemon:connect_signal("folder::updated", function(self, folder)
        folder_text.text = folder
    end)

    return wibox.widget
    {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15),
        title,
        folder_text,
        set_folder_button,
    }
end

local function format()
    local title = widgets.text
    {
        size = 15,
        text = "Format:"
    }

    local dropdown = widgets.dropdown
    {
        initial_value = record_daemon:get_format(),
        values =
        {
            ["mp4"] = "mp4",
            ["mov"] = "mov",
            ["webm"] = "webm",
            ["flac"] = "flac",
        },
        on_value_selected = function(value)
            record_daemon:set_format(value)
        end
    }

    return wibox.widget
    {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15),
        title,
        dropdown
    }
end

local function main(self)
    local title = widgets.text
    {
        bold = true,
        size = 15,
        text = "Record",
    }

    local close_button = widgets.button.text.normal
    {
        forced_width = dpi(50),
        forced_height = dpi(50),
        font = beautiful.xmark_icon.font,
        text = beautiful.xmark_icon.icon,
        on_release = function()
            self:hide()
        end
    }

    local record_button = widgets.button.text.normal
    {
        forced_width = dpi(50),
        size = 15,
        normal_bg = beautiful.random_accent_color(),
        text_normal_bg = beautiful.colors.background,
        text = record_daemon:get_is_recording() and "Stop" or "Record",
        animate_size = false,
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

    return wibox.widget
    {
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
    helpers.client.run_or_raise({class = "Record"}, false, window, { switchtotag = true })
    self._private.visible = true
end

function record:hide()
    self._private.client:kill()
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
    local ret = gobject{}
    gtable.crush(ret, record, true)

    ret._private = {}

    ruled.client.connect_signal("request::rules", function()
        ruled.client.append_rule
        {
            rule = { name = "no-one-gonna-match-this2" },
            properties = { floating = true, width = dpi(550), height = 1, placement = awful.placement.centered },
            callback = function(c)
                ret._private.client = c

                c:connect_signal("unmanage", function()
                    ret._private.visible = false
                    ret._private.client = nil
                end)

                c.can_resize = false
                c.custom_titlebar = false
                c.can_tile = false

                -- Settings placement in properties doesn't work
                c.x = (c.screen.geometry.width / 2) - (dpi(550) / 2)
                c.y = (c.screen.geometry.height / 2) - (dpi(520) / 2)

                awful.titlebar(c,
                {
                    position = "top",
                    size = dpi(520),
                    bg = beautiful.colors.background
                }) : setup
                {
                    widget = main(ret)
                }
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