local wibox = require("wibox")
local widgets = require("ui.widgets")
local slider_text_input = require("ui.apps.settings.slider_text_input")
local checkbox = require("ui.apps.settings.checkbox")
local separator = require("ui.apps.settings.separator")
local beautiful = require("beautiful")
local picom_daemon = require("daemons.system.picom")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local ui = {
    mt = {}
}


local function checkbox_widget(key)
    local name = key:gsub("(%l)(%w*)", function(a, b)
        return string.upper(a) .. b
    end)
    name = name:gsub("-", " ") .. ":"

    local widget = checkbox {
        name = name,
        state = picom_daemon["get_" .. key](picom_daemon),
        on_turn_on = function()
            picom_daemon["set_" .. key](picom_daemon, true)
        end,
        on_turn_off = function()
            picom_daemon["set_" .. key](picom_daemon, false)
        end
    }

    return widget
end

local function slider_text_input_widget(key,  minimum, maximum, round)
    local name = key:gsub("(%l)(%w*)", function(a, b)
        return string.upper(a) .. b
    end)
    name = name:gsub("-", " ") .. ":"

    local widget = slider_text_input {
        name = name,
        round = round,
        minimum = minimum or 0,
        maximum = maximum,
        value = picom_daemon["get_" .. key](picom_daemon),
        on_changed = function(value)
            picom_daemon["set_" .. key](picom_daemon, value)
        end
    }

    return widget
end

local function new()
    return wibox.widget {
        layout = wibox.layout.overflow.vertical,
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(10),
        step = 50,
        spacing = dpi(15),
        slider_text_input_widget("active-opacity",  0.1, 1, false),
        slider_text_input_widget("inactive-opacity",  0.1, 1, false),
        separator(),
        slider_text_input_widget("corner-radius", 0, 100, true),
        slider_text_input_widget("blur-strength", 0, 20, true),
        separator(),
        slider_text_input_widget("shadow-radius", 0, 100, true),
        slider_text_input_widget("shadow-opacity", 0, 1, false),
        slider_text_input_widget("shadow-offset-x", -500, 500, true),
        slider_text_input_widget("shadow-offset-y", -500, 500, true),
        checkbox_widget("shadow"),
        separator(),
        slider_text_input_widget("fade-delta", 0, 100, true),
        slider_text_input_widget("fade-in-step", 0, 1, false),
        slider_text_input_widget("fade-out-step", 0, 1, false),
        checkbox_widget("fading")
    }
end

function ui.mt:__call()
    return new()
end

return setmetatable(ui, ui.mt)