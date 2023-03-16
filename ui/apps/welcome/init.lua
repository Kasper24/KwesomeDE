-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gshape = require("gears.shape")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local app = require("ui.apps.app")
local beautiful = require("beautiful")
local system_daemon = require("daemons.system.system")
local email_daemon = require("daemons.web.email")
local github_daemon = require("daemons.web.github")
local gitlab_daemon = require("daemons.web.gitlab")
local weather_daemon = require("daemons.web.weather")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi

local instance = nil

local accent_color = beautiful.colors.random_accent_color()

local function indicator(active)
    return wibox.widget {
        widget = widgets.background,
        forced_width = dpi(20),
        shape = gshape.circle,
        bg = active and accent_color or helpers.color.lighten(beautiful.colors.surface_no_opacity, 0.2)
    }
end

local function text_input_widget(icon, placeholder, initial, forced_width, forced_height)
    return wibox.widget {
        widget = widgets.text_input,
        forced_width = forced_width,
        forced_height = forced_height,
        unfocus_keys = { },
        unfocus_on_client_clicked = false,
        initial = initial or "",
        widget_template = wibox.widget {
            widget = widgets.background,
            shape = helpers.ui.rrect(),
            bg = beautiful.colors.surface,
            {
                widget = wibox.container.margin,
                margins = dpi(15),
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = dpi(15),
                    {
                        widget = widgets.text,
                        icon = icon
                    },
                    {
                        layout = wibox.layout.stack,
                        {
                            widget = wibox.widget.textbox,
                            id = "placeholder_role",
                            text = placeholder,
                        },
                        {
                            widget = wibox.widget.textbox,
                            id = "text_role"
                        },
                    }
                }
            }
        }
    }
end

local function last_page(on_next_pressed)
    local icon = wibox.widget {
        widget = widgets.text,
        halign = "center",
        icon = beautiful.icons.circle_check,
        size = 120
    }

    local title = wibox.widget {
        widget = widgets.text,
        halign = "center",
        size = 30,
        text = "Congratulations"
    }

    local description = wibox.widget {
        widget = widgets.text,
        halign = "center",
        size = 13,
        text = [[Your system is now ready to be used!
For more information visit the following links.]]
    }

    local github_link = wibox.widget {
        widget = widgets.button.text.normal,
        forced_width = dpi(300),
        size = 13,
        text_normal_bg = accent_color,
        text = "Github...",
        on_release = function()
            awful.spawn("xdg-open ", false)
        end
    }

    local reddit_link = wibox.widget {
        widget = widgets.button.text.normal,
        forced_width = dpi(300),
        size = 13,
        text_normal_bg = accent_color,
        text = "Reddit...",
        on_release = function()
            awful.spawn("xdg-open ", false)
        end
    }

    local awesome_link = wibox.widget {
        widget = widgets.button.text.normal,
        forced_width = dpi(300),
        size = 13,
        text_normal_bg = accent_color,
        text = "Awesome...",
        on_release = function()
            awful.spawn("xdg-open https://awesomewm.org/apidoc/", false)
        end
    }

    local finish_button = wibox.widget {
        widget = widgets.button.text.normal,
        text_normal_bg = accent_color,
        size = 13,
        text = "Finish",
        on_release = function()
            on_next_pressed()
            system_daemon:set_need_setup_off()
        end
    }

    return wibox.widget {
        widget = wibox.container.margin,
        margins = dpi(15),
        {
            layout = wibox.layout.align.vertical,
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(20),
                icon,
                title,
                description,
                {
                    widget = wibox.container.place,
                    halign = "center",
                    valign = "center",
                    github_link
                },
                {
                    widget = wibox.container.place,
                    halign = "center",
                    valign = "center",
                    reddit_link
                },
                {
                    widget = wibox.container.place,
                    halign = "center",
                    valign = "center",
                    awesome_link
                }
            },
            nil,
            finish_button
        }
    }
end

local function weather_page(on_next_pressed, on_previous_pressed)
    local icon = wibox.widget {
        widget = widgets.text,
        halign = "center",
        icon = beautiful.icons.clouds,
        size = 120
    }

    local title = wibox.widget {
        widget = widgets.text,
        halign = "center",
        size = 30,
        text = "Weather"
    }

    local sign_up_open_weather_map = wibox.widget {
        widget = widgets.button.text.normal,
        size = 13,
        text_normal_bg = beautiful.colors.on_background,
        text = "1. Sign up and login on OpenWeatherMap.",
        on_release = function()
            awful.spawn("xdg-open https://home.openweathermap.org/users/sign_up", false)
        end
    }

    local visit_the_api_key_tab = wibox.widget {
        widget = widgets.button.text.normal,
        size = 13,
        text_normal_bg = beautiful.colors.on_background,
        text = "2. Visit the API key tab",
        on_release = function()
            awful.spawn("xdg-open https://home.openweathermap.org/api_keys", false)
        end
    }

    local generate_key = wibox.widget {
        widget = widgets.button.text.normal,
        size = 13,
        text_normal_bg = beautiful.colors.on_background,
        text = "3. Select a name for your key and click generate"
    }

    local copy_and_paste_key = wibox.widget {
        widget = widgets.button.text.normal,
        size = 13,
        text_normal_bg = beautiful.colors.on_background,
        text = "4. Copy the generated key and paste it in the text input below"
    }

    local api_key_text_input = text_input_widget(
        beautiful.icons.lock,
        "API Key:",
        weather_daemon:get_api_key(),
        dpi(250),
        dpi(50)
    )
    local coordinate_x_text_input = text_input_widget(
        beautiful.icons.location_dot,
        "Lat:",
        weather_daemon:get_coordinate_x(),
        dpi(250),
        dpi(50)
    )
    local coordinate_y_text_input = text_input_widget(
        beautiful.icons.location_dot,
        "Lon:",
        weather_daemon:get_coordinate_y(),
        dpi(250),
        dpi(50)
    )

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

        end
    }

    local back_button = wibox.widget {
        widget = widgets.button.text.normal,
        text_normal_bg = accent_color,
        size = 13,
        text = "Back",
        on_release = function()
            on_previous_pressed()
        end
    }

    local next_button = wibox.widget {
        widget = widgets.button.text.normal,
        text_normal_bg = accent_color,
        size = 13,
        text = "Next",
        on_release = function()
            weather_daemon:set_unit(unit_dropdown:get_value())
            weather_daemon:set_api_key(api_key_text_input:get_text())
            weather_daemon:set_coordinate_x(coordinate_x_text_input:get_text())
            weather_daemon:set_coordinate_y(coordinate_y_text_input:get_text())
            weather_daemon:refresh()
            on_next_pressed()
        end
    }

    return wibox.widget {
        widget = wibox.container.margin,
        margins = dpi(15),
        {
            layout = wibox.layout.align.vertical,
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(20),
                icon,
                title,
                {
                    layout = wibox.layout.fixed.vertical,
                    spacing = dpi(8),
                    sign_up_open_weather_map,
                    visit_the_api_key_tab,
                    generate_key,
                    copy_and_paste_key,
                    {
                        widget = wibox.container.place,
                        halign = "center",
                        valign = "center",
                        api_key_text_input
                    },
                    {
                        widget = wibox.container.place,
                        halign = "center",
                        valign = "center",
                        coordinate_x_text_input
                    },
                    {
                        widget = wibox.container.place,
                        halign = "center",
                        valign = "center",
                        coordinate_y_text_input
                    },
                    {
                        widget = wibox.container.place,
                        halign = "center",
                        valign = "center",
                        unit_dropdown
                    }
                }
            },
            nil,
            {
                layout = wibox.layout.align.horizontal,
                expand = "outside",
                back_button,
                {
                    widget = wibox.container.margin,
                    margins = {
                        left = dpi(20),
                        right = dpi(20)
                    },
                    {
                        layout = wibox.layout.fixed.horizontal,
                        spacing = dpi(30),
                        indicator(false),
                        indicator(false),
                        indicator(false),
                        indicator(false),
                        indicator(false),
                        indicator(true),
                        indicator(false)
                    }
                },
                next_button
            }
        }
    }
end

local function gitlab_page(on_next_pressed, on_previous_pressed)
    local icon = wibox.widget {
        widget = widgets.text,
        halign = "center",
        size = 120,
        icon = beautiful.icons.gitlab,
        size = 120
    }

    local title = wibox.widget {
        widget = widgets.text,
        halign = "center",
        size = 30,
        text = "Gitlab"
    }

    local login_on_gitlab = wibox.widget {
        widget = widgets.button.text.normal,
        size = 13,
        text_normal_bg = beautiful.colors.on_background,
        text = "1. Login on GitLab.",
        on_release = function()
            awful.spawn("xdg-open https://gitlab.com", false)
        end
    }

    local visit_access_tokens_tab = wibox.widget {
        widget = widgets.button.text.normal,
        size = 13,
        text_normal_bg = beautiful.colors.on_background,
        text = "2. Visit the access tokens tab.",
        on_release = function()
            awful.spawn("xdg-open https://gitlab.com/-/profile/personal_access_tokens", false)
        end
    }

    local enter_a_name_and_date = wibox.widget {
        widget = widgets.button.text.normal,
        size = 13,
        text_normal_bg = beautiful.colors.on_background,
        text = "3. Enter a name and optional expiry date for the token."
    }

    local select_the_desired_scopes = wibox.widget {
        widget = widgets.button.text.normal,
        size = 13,
        text_normal_bg = beautiful.colors.on_background,
        text = "4. Select the desired scopes."
    }

    local press_create_access_token = wibox.widget {
        widget = widgets.button.text.normal,
        size = 13,
        text_normal_bg = beautiful.colors.on_background,
        text = "5. Press Create personal access token."
    }

    local host_text_input = text_input_widget(
        beautiful.icons.server,
        "Host:",
        gitlab_daemon:get_host(),
        dpi(300),
        dpi(50)
    )

    local access_token_text_input = text_input_widget(
        beautiful.icons.lock,
        "Access Token:",
        gitlab_daemon:get_access_token(),
        dpi(300),
        dpi(50)
    )

    local back_button = wibox.widget {
        widget = widgets.button.text.normal,
        text_normal_bg = accent_color,
        size = 13,
        text = "Back",
        on_release = function()
            on_previous_pressed()
        end
    }

    local next_button = wibox.widget {
        widget = widgets.button.text.normal,
        text_normal_bg = accent_color,
        size = 13,
        text = "Next",
        on_release = function()
            gitlab_daemon:set_access_token(access_token_text_input:get_text())
            gitlab_daemon:set_host(host_text_input:get_text())
            gitlab_daemon:refresh()
            on_next_pressed()
        end
    }

    return wibox.widget {
        widget = wibox.container.margin,
        margins = dpi(15),
        {
            layout = wibox.layout.align.vertical,
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(20),
                icon,
                title,
                login_on_gitlab,
                visit_access_tokens_tab,
                enter_a_name_and_date,
                select_the_desired_scopes,
                press_create_access_token,
                {
                    widget = wibox.container.place,
                    halign = "center",
                    valign = "center",
                    access_token_text_input
                },
                {
                    widget = wibox.container.place,
                    halign = "center",
                    valign = "center",
                    host_text_input
                }
            },
            nil,
            {
                layout = wibox.layout.align.horizontal,
                expand = "outside",
                back_button,
                {
                    widget = wibox.container.margin,
                    margins = {
                        left = dpi(20),
                        right = dpi(20)
                    },
                    {
                        layout = wibox.layout.fixed.horizontal,
                        spacing = dpi(30),
                        indicator(false),
                        indicator(false),
                        indicator(false),
                        indicator(false),
                        indicator(true),
                        indicator(false),
                        indicator(false)
                    }
                },
                next_button
            }
        }
    }
end

local function github_page(on_next_pressed, on_previous_pressed)
    local icon = wibox.widget {
        widget = widgets.text,
        halign = "center",
        icon = beautiful.icons.github,
        size = 120
    }

    local title = wibox.widget {
        widget = widgets.text,
        halign = "center",
        size = 30,
        text = "Github"
    }

    local description = wibox.widget {
        widget = widgets.text,
        halign = "center",
        size = 13,
        text = "Please fill your GitHub username in order for the GitHub panel info to show."
    }

    local username_text_input = text_input_widget(
        beautiful.icons.user,
        "Username:",
        github_daemon:get_username(),
        dpi(300),
        dpi(50)
    )

    local back_button = wibox.widget {
        widget = widgets.button.text.normal,
        text_normal_bg = accent_color,
        size = 13,
        text = "Back",
        on_release = function()
            on_previous_pressed()
        end
    }

    local next_button = wibox.widget {
        widget = widgets.button.text.normal,
        text_normal_bg = accent_color,
        size = 13,
        text = "Next",
        on_release = function()
            github_daemon:set_username(username_text_input:get_text())
            github_daemon:refresh()
            on_next_pressed()
        end
    }

    return wibox.widget {
        widget = wibox.container.margin,
        margins = dpi(15),
        {
            layout = wibox.layout.align.vertical,
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(20),
                icon,
                title,
                description,
                {
                    widget = wibox.container.place,
                    halign = "center",
                    valign = "center",
                    username_text_input
                }
            },
            nil,
            {
                layout = wibox.layout.align.horizontal,
                expand = "outside",
                back_button,
                {
                    widget = wibox.container.margin,
                    margins = {
                        left = dpi(20),
                        right = dpi(20)
                    },
                    {
                        layout = wibox.layout.fixed.horizontal,
                        spacing = dpi(30),
                        indicator(false),
                        indicator(false),
                        indicator(false),
                        indicator(true),
                        indicator(false),
                        indicator(false),
                        indicator(false)
                    }
                },
                next_button
            }
        }
    }
end

local function email_page(on_next_pressed, on_previous_pressed)
    local icon = wibox.widget {
        widget = widgets.text,
        halign = "center",
        icon = beautiful.icons.envelope,
        size = 120
    }

    local title = wibox.widget {
        widget = widgets.text,
        halign = "center",
        size = 30,
        text = "Email"
    }

    local description = wibox.widget {
        widget = widgets.text,
        halign = "center",
        size = 13,
        text = "Please fill your email info in order for the email panel info to show."
    }

    local machine_text_input = text_input_widget(
        beautiful.icons.server,
        "Machine:",
        email_daemon:get_machine(),
        dpi(300),
        dpi(50)
    )

    local login_text_input = text_input_widget(
        beautiful.icons.user,
        "Login:",
        email_daemon:get_login(),
        dpi(300),
        dpi(50)
    )

    local password_text_input = text_input_widget(
        beautiful.icons.lock,
        "Password:",
        email_daemon:get_password(),
        dpi(300),
        dpi(50)
    )

    local back_button = wibox.widget {
        widget = widgets.button.text.normal,
        text_normal_bg = accent_color,
        size = 13,
        text = "Back",
        on_release = function()
            on_previous_pressed()
        end
    }

    local next_button = wibox.widget {
        widget = widgets.button.text.normal,
        text_normal_bg = accent_color,
        size = 13,
        text = "Next",
        on_release = function()
            email_daemon:update_net_rc(machine_text_input:get_text(), login_text_input:get_text(), password_text_input:get_text())
            on_next_pressed()
        end
    }

    return wibox.widget {
        widget = wibox.container.margin,
        margins = dpi(15),
        {
            layout = wibox.layout.align.vertical,
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(20),
                icon,
                title,
                description,
                {
                    widget = wibox.container.place,
                    halign = "center",
                    valign = "center",
                    machine_text_input
                },
                {
                    widget = wibox.container.place,
                    halign = "center",
                    valign = "center",
                    login_text_input
                },
                {
                    widget = wibox.container.place,
                    halign = "center",
                    valign = "center",
                    password_text_input
                }
            },
            nil,
            {
                layout = wibox.layout.align.horizontal,
                expand = "outside",
                back_button,
                {
                    widget = wibox.container.margin,
                    margins = {
                        left = dpi(20),
                        right = dpi(20)
                    },
                    {
                        layout = wibox.layout.fixed.horizontal,
                        spacing = dpi(30),
                        indicator(false),
                        indicator(false),
                        indicator(true),
                        indicator(false),
                        indicator(false),
                        indicator(false),
                        indicator(false)
                    }
                },
                next_button
            }
        }
    }
end

local function welcome_page(on_next_pressed, on_previous_pressed)
    local icon = wibox.widget {
        widget = widgets.profile,
        halign = "center",
        forced_height = dpi(140),
        forced_width = dpi(140),
    }

    local title = wibox.widget {
        widget = widgets.text,
        halign = "center",
        size = 25,
        text = "Hi " .. os.getenv("USER"):upper() .. ", Welcome to KwesomeDE!"
    }

    local overview = wibox.widget {
        widget = wibox.widget.imagebox,
        horizontal_fit_policy = "fit",
        vertical_fit_policy = "fit",
        image = beautiful.overview
    }

    local quit_button = wibox.widget {
        widget = widgets.button.text.normal,
        text_normal_bg = accent_color,
        size = 13,
        text = "Quit",
        on_release = function()
            on_previous_pressed()
        end
    }

    local next_button = wibox.widget {
        widget = widgets.button.text.normal,
        text_normal_bg = accent_color,
        size = 13,
        text = "Next",
        on_release = function()
            on_next_pressed()
        end
    }

    return wibox.widget {
        widget = wibox.container.margin,
        margins = dpi(15),
        {
            layout = wibox.layout.align.vertical,
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(20),
                icon,
                title,
                overview
            },
            nil,
            {
                layout = wibox.layout.align.horizontal,
                expand = "outside",
                quit_button,
                {
                    widget = wibox.container.margin,
                    margins = {
                        left = dpi(20),
                        right = dpi(20)
                    },
                    {
                        layout = wibox.layout.fixed.horizontal,
                        spacing = dpi(30),
                        indicator(true),
                        indicator(false),
                        indicator(false),
                        indicator(false),
                        indicator(false),
                        indicator(false),
                        indicator(false)
                    }
                },
                next_button
            }
        }
    }
end

local function widget(self)
    local stack = {}
    local _welcome_page = {}
    local _email_page = {}
    local _github_page = {}
    local _gitlab_page = {}
    local _weather_page = {}
    local _last_page = {}

    _welcome_page = welcome_page(function()
        stack:raise_widget(_email_page)
    end, function()
        self:hide()
    end)

    _email_page = email_page(function()
        stack:raise_widget(_github_page)
    end, function()
        stack:raise_widget(_welcome_page)
    end)

    _github_page = github_page(function()
        stack:raise_widget(_gitlab_page)
    end, function()
        stack:raise_widget(_email_page)
    end)

    _gitlab_page = gitlab_page(function()
        stack:raise_widget(_weather_page)
    end, function()
        stack:raise_widget(_github_page)
    end)

    _weather_page = weather_page(function()
        stack:raise_widget(_last_page)
    end, function()
        stack:raise_widget(_gitlab_page)
    end)

    _last_page = last_page(function()
        self:hide()
    end)

    stack = wibox.widget {
        layout = wibox.layout.stack,
        top_only = true,
        _welcome_page,
        _email_page,
        _github_page,
        _gitlab_page,
        _weather_page,
        _last_page
    }

    return stack
end

local function new()
    local app = app {
        title ="Welcome",
        class = "Welcome",
        width = dpi(550),
        height = dpi(780),
    }
    app:set_widget(widget(app))

    return app
end

if not instance then
    instance = new()
end
return instance
