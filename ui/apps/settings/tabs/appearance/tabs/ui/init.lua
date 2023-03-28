local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local theme_daemon = require("daemons.system.theme")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local ui = {
    mt = {}
}

local function checkbox(key)
    local name = wibox.widget {
        widget = widgets.text,
        size = 15,
        text = key:sub(1, 1):upper() .. key:sub(2):gsub("_", " ") .. ":"
    }

    local checkbox = wibox.widget {
        widget = widgets.checkbox,
        state = theme_daemon["get_ui_" .. key](theme_daemon),
        handle_active_color = beautiful.icons.computer.color,
        on_turn_on = function()
            theme_daemon["set_ui_" .. key](theme_daemon, true)
        end,
        on_turn_off = function()
            theme_daemon["set_ui_" .. key](theme_daemon, false)
        end
    }

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        forced_height = dpi(40),
        spacing = dpi(15),
        name,
        checkbox
    }
end

local function slider(text, initial_value, maximum, round, on_changed, minimum, signal)
    local name = wibox.widget {
        widget = widgets.text,
        forced_width = dpi(200),
        size = 15,
        text = text
    }

    local slider_text_input = widgets.slider_text_input {
        slider_width = dpi(400),
        round = round,
        value = initial_value,
        minimum = minimum or 0,
        maximum = maximum,
        bar_active_color = beautiful.icons.computer.color,
        selection_bg = beautiful.icons.computer.color
    }

    SETTINGS_APP:connect_signal("tab::select", function()
        slider_text_input:get_text_input():unfocus()
    end)

    SETTINGS_APP:connect_signal("visibility", function(self, visible)
        if visible == false then
            slider_text_input:get_text_input():unfocus()
        end
    end)

    SETTINGS_APP:get_client():connect_signal("unfocus", function()
        slider_text_input:get_text_input():unfocus()
    end)

    SETTINGS_APP:get_client():connect_signal("mouse::leave", function()
        slider_text_input:get_text_input():unfocus()
    end)

    slider_text_input:connect_signal("property::value", function(self, value)
        on_changed(value)
    end)

    if signal then
        theme_daemon:connect_signal(signal, function(self, value)
            slider_text_input:set_value(tostring(value))
        end)
    end

    return wibox.widget {
        layout = wibox.layout.align.horizontal,
        name,
        slider_text_input
    }
end

local function file_picker(title, initial_value, on_changed)
    local file_picker = wibox.widget {
        widget = widgets.file_picker,
        forced_width = dpi(400),
        initial_value = initial_value,
        on_changed = function(text)
            on_changed(text)
        end
    }

    SETTINGS_APP:connect_signal("tab::select", function()
        file_picker:get_text_input():unfocus()
    end)

    SETTINGS_APP:connect_signal("visibility", function(self, visible)
        if visible == false then
            file_picker:get_text_input():unfocus()
        end
    end)

    SETTINGS_APP:get_client():connect_signal("mouse::leave", function()
        file_picker:get_text_input():unfocus()
    end)

    SETTINGS_APP:get_client():connect_signal("unfocus", function()
        file_picker:get_text_input():unfocus()
    end)

    return wibox.widget {
        layout = wibox.layout.align.horizontal,
        {
            widget = widgets.text,
            forced_width = dpi(200),
            size = 15,
            text = title,
        },
        file_picker
    }
end

local function new()
    return wibox.widget {
        layout = wibox.layout.overflow.vertical,
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(10),
        step = 50,
        spacing = dpi(15),
        file_picker("Profile image:", theme_daemon:get_profile_image(), function(text)
            theme_daemon:set_profile_image(text)
        end),
        {
            layout = wibox.layout.fixed.vertical,
            forced_height = dpi(60),
            spacing = dpi(5),
            slider("DPI:", theme_daemon:get_dpi(), 250, true, function(value)
                theme_daemon:set_dpi(value)
            end),
            {
                widget = widgets.text,
                italic = true,
                size = 10,
                text = "* Restart AwesomeWM for this to take effect"
            }
        },
        slider("Useless gap:", theme_daemon:get_useless_gap(), 250, true, function(value)
            theme_daemon:set_useless_gap(value)
        end, 0, "useless_gap"),
        slider("Client gap:", theme_daemon:get_client_gap(), 250, true, function(value)
            theme_daemon:set_client_gap(value)
        end, 0, "client_gap"),
        slider("Opacity:", theme_daemon:get_ui_opacity(), 1, false, function(value)
            theme_daemon:set_ui_opacity(value)
        end),
        slider("Corner Radius:", theme_daemon:get_ui_border_radius(), 100, true, function(value)
            theme_daemon:set_ui_border_radius(value)
        end),
        slider("Animations FPS:", theme_daemon:get_ui_animations_framerate(), 360, true, function(value)
            theme_daemon:set_ui_animations_framerate(value)
        end, 1),
        checkbox("animations"),
        checkbox("show_lockscreen_on_login"),
    }
end

function ui.mt:__call()
    return new()
end

return setmetatable(ui, ui.mt)