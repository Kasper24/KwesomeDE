local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local helpers = require("helpers")
local picom_daemon = require("daemons.system.picom")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local ui = {
    mt = {}
}

local function separator()
    return wibox.widget {
        widget = widgets.background,
        forced_height = dpi(1),
        shape = helpers.ui.rrect(),
        bg = beautiful.colors.surface
    }
end

local function checkbox(key)
    local display_name = key:gsub("(%l)(%w*)", function(a, b)
        return string.upper(a) .. b
    end)
    display_name = display_name:gsub("-", " ") .. ":"

    local name = wibox.widget {
        widget = widgets.text,
        size = 15,
        text = display_name
    }

    local checkbox = wibox.widget {
        widget = widgets.checkbox,
        state = picom_daemon["get_" .. key](picom_daemon),
        handle_active_color = beautiful.icons.computer.color,
        on_turn_on = function()
            picom_daemon["set_" .. key](picom_daemon, true)
        end,
        on_turn_off = function()
            picom_daemon["set_" .. key](picom_daemon, false)
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

local function slider(key, maximum, round, minimum)
    local display_name = key:gsub("(%l)(%w*)", function(a, b)
        return string.upper(a) .. b
    end)
    display_name = display_name:gsub("-", " ") .. ":"

    local name = wibox.widget {
        widget = widgets.text,
        forced_width = dpi(200),
        size = 15,
        text = display_name
    }

    local slider_text_input = widgets.slider_text_input {
        slider_width = dpi(400),
        round = round,
        minimum = minimum or 0,
        maximum = maximum,
        value = picom_daemon["get_" .. key](picom_daemon),
        bar_active_color = beautiful.icons.computer.color,
        selection_bg = beautiful.icons.computer.color
    }

    slider_text_input:connect_signal("property::value", function(self, value, instant)
        picom_daemon["set_" .. key](picom_daemon, value)
    end)

    return wibox.widget {
        layout = wibox.layout.align.horizontal,
        name,
        slider_text_input
    }
end

local function new()
    return wibox.widget {
        layout = wibox.layout.overflow.vertical,
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(10),
        step = 50,
        spacing = dpi(15),
        slider("active-opacity", 1, false, 0.1),
        slider("inactive-opacity", 1, false, 0.1),
        separator(),
        slider("corner-radius", 100, true),
        slider("blur-strength", 20, true),
        separator(),
        slider("shadow-radius", 100, true),
        slider("shadow-opacity", 1, false),
        slider("shadow-offset-x", 500, true, -500),
        slider("shadow-offset-y", 500, true, -500),
        checkbox("shadow"),
        separator(),
        slider("fade-delta", 100, true),
        slider("fade-in-step", 1, false),
        slider("fade-out-step", 1, false),
        checkbox("fading")
    }
end

function ui.mt:__call()
    return new()
end

return setmetatable(ui, ui.mt)