-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local record_daemon = require("daemons.system.record")
local audio_daemon = require("daemons.hardware.audio")
local app = require("ui.apps.app")
local dpi = beautiful.xresources.apply_dpi
local pairs = pairs

local instance = nil

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
        forced_width = dpi(65),
        size = 15,
        text = "FPS:"
    }

    local slider = widgets.slider_prompt {
        slider_width = dpi(150),
        value = record_daemon:get_fps(),
        round = true,
        maximum = 360,
        bar_active_color = beautiful.icons.video.color,
    }

    slider:connect_signal("property::value", function(self, value, instant)
        record_daemon:set_fps(value)
    end)

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_height = dpi(35),
        spacing = dpi(15),
        title,
        slider
    }
end

local function delay()
    local title = wibox.widget {
        widget = widgets.text,
        forced_width = dpi(65),
        size = 15,
        text = "Delay:"
    }

    local slider = widgets.slider_prompt {
        slider_width = dpi(150),
        value = record_daemon:get_delay(),
        round = true,
        maximum = 100,
        bar_active_color = beautiful.icons.video.color,
    }

    slider:connect_signal("property::value", function(self, value, instant)
        record_daemon:set_delay(value)
    end)

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_height = dpi(35),
        spacing = dpi(15),
        title,
        slider
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
    for _, sink in pairs(audio_daemon:get_sinks()) do
        dropdown:add(sink.description, sink.name)
        if selected == false then
            dropdown:select(sink.description, sink.name)
            selected = true
        end
    end
    for _, source in pairs(audio_daemon:get_sources()) do
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

    local folder_prompt = wibox.widget {
        widget = widgets.prompt,
        forced_width = dpi(350),
        size = 12,
        text = record_daemon:get_folder()
    }

    folder_prompt:connect_signal("text::changed", function(self, text)
        record_daemon:set_folder(text)
    end)

    local set_folder_button = wibox.widget {
        widget = widgets.button.text.normal,
        size = 15,
        text_normal_bg = beautiful.colors.on_background,
        text = "...",
        on_release = function()
            record_daemon:set_folder()
        end
    }

    record_daemon:connect_signal("folder::updated", function(self, folder)
        folder_prompt:set_text(folder)
    end)

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_height = dpi(35),
        spacing = dpi(15),
        title,
        folder_prompt,
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

local function widget(self)
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
        text_normal_bg = beautiful.icons.video.color,
        icon = beautiful.icons.xmark,
        on_release = function()
            self:hide()
        end
    }

    local record_button = wibox.widget {
        widget = widgets.button.text.normal,
        forced_width = dpi(50),
        size = 15,
        normal_bg = beautiful.icons.video.color,
        text_normal_bg = beautiful.colors.on_accent,
        text = record_daemon:get_is_recording() and "Stop" or "Record",
        on_release = function()
            record_daemon:toggle_video()
        end
    }

    record_daemon:connect_signal("started", function()
        record_button:set_text("Stop")
    end)

    record_daemon:connect_signal("ended", function()
        record_button:set_text("Record")
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

local function new()
    local app = app {
        title ="Recorder",
        class = "Recorder",
        width = dpi(550),
        height = dpi(435),
    }
    app:set_widget(widget(app))

    record_daemon:connect_signal("started", function()
        app:set_hidden(true)
    end)

    record_daemon:connect_signal("ended", function()
        app:set_hidden(false)
    end)

    record_daemon:connect_signal("error::create_directory", function()
        app:set_hidden(false)
    end)

    return app
end

if not instance then
    instance = new()
end
return instance
