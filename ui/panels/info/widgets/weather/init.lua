-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local weather_daemon = require("daemons.web.weather")
local library = require("library")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable
local tonumber = tonumber
local string = string
local ipairs = ipairs
local math = math
local os = os
local capi = {
    awesome = awesome
}

local weather = {
    mt = {}
}

local weather_codes_map = {
  -- Clear sky
  [0] = { icon = beautiful.icons.sun, desc = "Clear sky" },

  -- Mainly clear, partly cloudy, and overcast
  [1] = { icon = beautiful.icons.sun_cloud, desc = "Mainly clear" },
  [2] = { icon = beautiful.icons.cloud, desc = "Partly cloudy" },
  [3] = { icon = beautiful.icons.cloud_sun, desc = "Overcast" },

  -- Fog and depositing rime fog
  [45] = { icon = beautiful.icons.cloud_fog, desc = "Fog" },
  [48] = { icon = beautiful.icons.cloud_fog, desc = "Depositing rime fog" },

  -- Drizzle: Light, moderate, and dense intensity
  [51] = { icon = beautiful.icons.cloud_drizzle, desc = "Light drizzle" },
  [53] = { icon = beautiful.icons.cloud_drizzle, desc = "Moderate drizzle" },
  [55] = { icon = beautiful.icons.cloud_drizzle, desc = "Dense drizzle" },

  -- Freezing Drizzle: Light and dense intensity
  [56] = { icon = beautiful.icons.cloud_drizzle, desc = "Light freezing drizzle" },
  [57] = { icon = beautiful.icons.cloud_drizzle, desc = "Dense freezing drizzle" },

  -- Rain: Slight, moderate, and heavy intensity
  [61] = { icon = beautiful.icons.cloud_rain, desc = "Slight rain" },
  [63] = { icon = beautiful.icons.cloud_rain, desc = "Moderate rain" },
  [65] = { icon = beautiful.icons.cloud_rain, desc = "Heavy rain" },

  -- Freezing Rain: Light and heavy intensity
  [66] = { icon = beautiful.icons.cloud_rain, desc = "Light freezing rain" },
  [67] = { icon = beautiful.icons.cloud_rain, desc = "Heavy freezing rain" },

  -- Snowfall: Slight, moderate, and heavy intensity
  [71] = { icon = beautiful.icons.cloud_snow, desc = "Slight snow" },
  [73] = { icon = beautiful.icons.cloud_snow, desc = "Moderate snow" },
  [75] = { icon = beautiful.icons.cloud_snow, desc = "Heavy snow" },

  -- Snow grains
  [77] = { icon = beautiful.icons.snowflake, desc = "Snow grains" },

  -- Rain showers: Slight, moderate, and violent
  [80] = { icon = beautiful.icons.cloud_shower, desc = "Slight rain shower" },
  [81] = { icon = beautiful.icons.cloud_shower, desc = "Moderate rain shower" },
  [82] = { icon = beautiful.icons.cloud_shower, desc = "Violent rain shower" },

  -- Snow showers: Slight and heavy
  [85] = { icon = beautiful.icons.cloud_shower, desc = "Slight snow shower" },
  [86] = { icon = beautiful.icons.cloud_shower, desc = "Heavy snow shower" },

  -- Thunderstorm: Slight or moderate
  [95] = { icon = beautiful.icons.cloud_bolt, desc = "Slight or moderate thunderstorm" },

  -- Thunderstorm with slight and heavy hail
  [96] = { icon = beautiful.icons.cloud_bolt, desc = "Thunderstorm with slight hail" },
  [99] = { icon = beautiful.icons.cloud_bolt, desc = "Thunderstorm with heavy hail" },
}

local function curvaceous(cr, x, y, b, step_width, options, draw_line)
    local interpolate = library.bezier.cubic_from_derivative_and_points_min_stretch

    local state = options.curvaceous_state
    if not state or state.last_group ~= options._group_idx then
        -- New data series is being drawn, reset state.
        state = {
            last_group = options._group_idx,
            x = x,
            y = y,
            b = b
        }
        options.curvaceous_state = state
        return
    end

    -- Compute if the bar needs to be cut due to spacing and how much
    local step_spacing = options._step_spacing
    local step_fraction = step_spacing ~= 0 and step_width / (step_width + step_spacing)

    -- Get coordinates from the previous step
    local x0, y0, b0 = state.x, state.y, state.b
    -- Update coordinates in state
    state.x, state.y, state.b = x, y, b
    -- Get derivatives from the previous step
    local y_d, b_d = state.y_d or 0, state.b_d or 0

    -- Guard against NaNs in the y coordinate
    y0 = (y0 == y0) and y0 or b0
    y = (y == y) and y or b

    -- Horizontal linear movement of the curves
    local x_curve = {library.bezier.cubic_through_points(x0, x0 + step_width)}

    -- Vertical movement curve for y
    local y_curve = {interpolate(y_d, y0, y)}
    state.y_d = library.bezier.curve_derivative_at_one(y_curve)
    if step_fraction then
        y_curve = library.bezier.curve_split_at(y_curve, step_fraction)
    end

    -- Paint the value curve
    cr:move_to(x_curve[1], y_curve[1])
    cr:curve_to(x_curve[2], y_curve[2], x_curve[3], y_curve[3], x_curve[4], y_curve[4])

    if not draw_line then
        -- Vertical movement curve for the baseline
        local b_curve = {interpolate(b_d, b0, b)}
        state.b_d = library.bezier.curve_derivative_at_one(b_curve)
        if step_fraction then
            b_curve = library.bezier.curve_split_at(b_curve, step_fraction)
        end

        -- Paint the bar bounded by the baseline curve from below
        cr:line_to(x_curve[4], b_curve[4])
        cr:curve_to(x_curve[3], b_curve[3], x_curve[2], b_curve[2], x_curve[1], b_curve[1])
        cr:close_path()
    end
end

local function to_direction(degrees)
    -- Ref: https://www.campbellsci.eu/blog/convert-wind-directions
    if degrees == nil then
        return "Unknown dir"
    end

    local directions = {"N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW",
                        "NNW", "N"}
    return directions[math.floor((degrees % 360) / 22.5) + 1]
end

local function gen_temperature_str(temp)
    local temp_str = string.format("%.0f", temp)
    local s = temp_str .. "°" .. (weather_daemon:get_unit() == "celsius" and "C" or "F")
    return s
end

local function get_uvi_index_color(uvi)
    if uvi >= 0 and uvi < 3 then
        return beautiful.colors.green
    elseif uvi >= 3 and uvi < 6 then
        return beautiful.colors.yellow
    elseif uvi >= 6 and uvi < 8 then
        return beautiful.colors.magenta
    elseif uvi >= 8 and uvi < 11 then
        return beautiful.colors.red
    elseif uvi >= 11 then
        return beautiful.colors.bright_red
    end
end

local function new()
    local time_format_12h = false

    local icon = wibox.widget {
        widget = widgets.text,
        size = 85,
    }

    local current_weather_widget = wibox.widget {
        layout = wibox.layout.flex.horizontal,
        {
            layout = wibox.layout.align.vertical,
            {
                widget = wibox.container.place,
                align = "center",
                icon
            },
            {
                widget = widgets.text,
                id = "description",
                halign = "center",
                size = 12
            }
        },
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            forced_width = 150,
            {
                layout = wibox.layout.fixed.vertical,
                {
                    widget = widgets.text,
                    id = "temp",
                    size = 40
                },
                {
                    widget = widgets.text,
                    id = "feels_like_temp",
                    halign = "left",
                    size = 12
                }
            },
            {
                layout = wibox.layout.align.vertical,
                expand = "inside",
                {
                    layout = wibox.layout.align.horizontal,
                    {
                        widget = widgets.text,
                        bold = true,
                        size = 12,
                        text = "Wind: ",
                    },
                    {
                        widget = widgets.text,
                        id = "wind",
                        size = 12
                    },
                },
                {
                    layout = wibox.layout.align.horizontal,
                    {
                        widget = widgets.text,
                        bold = true,
                        size = 12,
                        text = "Humidity: ",
                    },
                    {
                        widget = widgets.text,
                        id = "humidity",
                        size = 12
                    },
                },
                {
                    layout = wibox.layout.align.horizontal,
                    {
                        widget = widgets.text,
                        bold = true,
                        size = 12,
                        text = "UV: ",
                    },
                    {
                        widget = widgets.text,
                        id = "uv",
                        size = 12
                    },
                },
            }
        }
    }

    local temperatures = wibox.widget {
        layout = wibox.layout.flex.horizontal
    }

    local hourly_forecast_graph = wibox.widget {
        widget = wibox.widget.graph,
        forced_height = dpi(55),
        stack = false,
        scale = true,
        step_width = dpi(53),
        step_hook = curvaceous,
        background_color = beautiful.colors.transparent,
        color = library.color.darken(beautiful.colors.accent, 0.3),
        opacity = 1
    }

    local hourly_forecast_graph_border = wibox.widget {
        widget = wibox.widget.graph,
        forced_height = dpi(55),
        stack = false,
        scale = true,
        step_width = dpi(53),
        step_hook = curvaceous,
        background_color = beautiful.colors.transparent,
        color = beautiful.colors.accent,
        opacity = 1
    }

    capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
        hourly_forecast_graph.color = library.color.darken(beautiful.icons.sun.color, 0.5)
        hourly_forecast_graph_border.color = beautiful.icons.sun.color
    end)

    local hours = wibox.widget {
        layout = wibox.layout.flex.horizontal,
        spacing = dpi(15)
    }

    local daily_forecast_widget = wibox.widget {
        layout = wibox.layout.flex.horizontal,
        spacing = dpi(5)
    }

    local spinning_circle = widgets.spinning_circle {
        forced_width = dpi(150),
        forced_height = dpi(150)
    }

    local missing_credentials_text = wibox.widget {
        widget = wibox.container.place,
        halign = "center",
        valign = "center",
        {
            widget = widgets.text,
            halign = "center",
            size = 25,
            color = beautiful.colors.on_background,
            text = "Missing Credentials"
        }
    }

    local error_icon = wibox.widget {
        widget = widgets.text,
        halign = "center",
        icon = beautiful.icons.circle_exclamation,
        size = 120
    }

    local weather_widget = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        current_weather_widget,
        {
            layout = wibox.layout.overflow.horizontal,
            forced_width = dpi(500),
            scrollbar_widget = widgets.scrollbar,
            scrollbar_width = dpi(10),
            step = 50,
            {
                widget = wibox.container.margin,
                margins = {
                    bottom = dpi(15)
                },
                {
                    layout = wibox.layout.fixed.vertical,
                    spacing = dpi(15),
                    temperatures,
                    {
                        layout = wibox.layout.stack,
                        vertical_offset = dpi(5),
                        hourly_forecast_graph_border,
                        hourly_forecast_graph
                    },
                    hours,
                    daily_forecast_widget
                }
            }
        }
    }

    local stack = wibox.widget {
        layout = wibox.layout.stack,
        top_only = true,
        spinning_circle,
        missing_credentials_text,
        error_icon,
        weather_widget
    }

    weather_daemon:connect_signal("error", function()
        spinning_circle:stop()
        stack:raise_widget(error_icon)
    end)

    weather_daemon:connect_signal("error::missing_credentials", function()
        spinning_circle:stop()
        stack:raise_widget(missing_credentials_text)
    end)

    weather_daemon:connect_signal("weather", function(self, result)
        spinning_circle:stop()

        hours:reset()
        temperatures:reset()
        hourly_forecast_graph:clear()
        hourly_forecast_graph_border:clear()
        daily_forecast_widget:reset()

        stack:raise_widget(weather_widget)

        icon:set_icon(weather_codes_map[result.current.weather_code].icon)
        icon:set_color(beautiful.colors.accent)
        current_weather_widget:get_children_by_id("temp")[1]:set_text(
            gen_temperature_str(result.current.temperature_2m))
        current_weather_widget:get_children_by_id("feels_like_temp")[1]:set_text("Feels like " ..
            gen_temperature_str(result.current.apparent_temperature))
        current_weather_widget:get_children_by_id("description")[1]:set_text(weather_codes_map[result.current.weather_code].desc)
        current_weather_widget:get_children_by_id("wind")[1]:set_text(
            result.current.wind_speed_10m .. "km/h (" .. to_direction(result.current.wind_direction_10m) .. ")")
        current_weather_widget:get_children_by_id("humidity")[1]:set_text(result.current.relative_humidity_2m)
        current_weather_widget:get_children_by_id("uv")[1]:set_text(result.daily.uv_index_max[1])
        current_weather_widget:get_children_by_id("uv")[1]:set_color(get_uvi_index_color(result.daily.uv_index_max[1]))

        for index, hour in ipairs(result.hourly.time) do
            if index <= 24 then
                hourly_forecast_graph:add_value(result.hourly.temperature_2m[index])
                hourly_forecast_graph_border:add_value(result.hourly.temperature_2m[index])

                if (index - 1) % 2 == 0 then
                    local hour_widget = wibox.widget {
                        widget = widgets.text,
                        forced_width = dpi(50),
                        halign = "center",
                        size = 12,
                        text = os.date(time_format_12h and "%I%p" or "%H:00", tonumber(hour))
                    }

                    local temperature_widget = wibox.widget {
                        widget = widgets.text,
                        halign = "center",
                        size = 15,
                        text = string.format("%.0f", result.hourly.temperature_2m[index]) .. "°"
                    }

                    hours:add(hour_widget)
                    temperatures:add(temperature_widget)
                end
            end
        end

        for index, day in ipairs(result.daily.time) do
            local day_forecast = wibox.widget {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(15),
                {
                    widget = widgets.text,
                    halign = "center",
                    size = 15,
                    text = os.date("%a", day),
                },
                {
                    layout = wibox.layout.fixed.vertical,
                    spacing = dpi(8),
                    {
                        widget = widgets.text,
                        halign = "center",
                        icon = weather_codes_map[result.daily.weather_code[index]].icon,
                        color = beautiful.colors.accent,
                        size = 35
                    },
                    {
                        widget = widgets.text,
                        halign = "center",
                        size = 12,
                        text = gen_temperature_str(result.daily.temperature_2m_min[index])
                    },
                    {
                        widget = widgets.text,
                        halign = "center",
                        size = 12,
                        text = gen_temperature_str(result.daily.temperature_2m_max[index])
                    }
                }
            }

            daily_forecast_widget:add(day_forecast)
        end
    end)

    return stack
end

function weather.mt:__call(...)
    return new()
end

return setmetatable(weather, weather.mt)
