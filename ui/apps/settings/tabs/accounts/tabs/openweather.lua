local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local helpers = require("helpers")
local text_input_widget = require("ui.apps.settings.tabs.accounts.text_input")
local weather_daemon = require("daemons.web.weather")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local openweather = {
    mt = {}
}

local function new()
    local api_key_text_input = text_input_widget(
        beautiful.icons.lock,
        "API Key:",
        weather_daemon:get_api_key()
    )

    local latitude_text_input = text_input_widget(
        beautiful.icons.location_dot,
        "Latitude:",
        weather_daemon:get_latitude()
    )

    local longitude_text_input = text_input_widget(
        beautiful.icons.location_dot,
        "Longitude:",
        weather_daemon:get_longitude()
    )

    api_key_text_input:connect_signal("unfocus", function(self, text)
        weather_daemon:set_api_key(text)
        weather_daemon:refresh()
    end)

    latitude_text_input:connect_signal("unfocus", function(self, text)
        weather_daemon:set_latitude(text)
        weather_daemon:refresh()
    end)

    longitude_text_input:connect_signal("unfocus", function(self, text)
        weather_daemon:set_longitudes(text)
        weather_daemon:refresh()
    end)

    local unit_dropdown = widgets.dropdown {
        forced_width = dpi(250),
        forced_height = dpi(50),
        label = "Unit: ",
        initial_value = weather_daemon:get_unit(),
        values = {
            ["metric"] = "metric",
            ["imperial"] = "imperial",
            ["standard"] = "standard"
        },
        on_value_selected = function(value)
            weather_daemon:set_unit(value)
            weather_daemon:refresh()
        end
    }

    return wibox.widget {
        layout = wibox.layout.overflow.vertical,
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(10),
        step = 50,
        spacing = dpi(15),
        api_key_text_input,
        longitude_text_input,
        latitude_text_input,
        unit_dropdown
    }
end

function openweather.mt:__call()
    return new()
end

return setmetatable(openweather, openweather.mt)