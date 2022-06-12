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
local widgets = require("presentation.ui.widgets")
local beautiful = require("beautiful")
local system_daemon = require("daemons.system.system")
local email_daemon = require("daemons.web.email")
local github_daemon = require("daemons.web.github")
local gitlab_daemon = require("daemons.web.gitlab")
local weather_daemon = require("daemons.web.weather")
local settings = require("services.settings")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi

local welcome = { }
local instance = nil

local window = [[ lua -e "
    local lgi = require 'lgi'
    local Gtk = lgi.require('Gtk', '3.0')

    -- Create top level window with some properties and connect its 'destroy'
    -- signal to the event loop termination.
    local window = Gtk.Window {
    title = 'no-one-gonna-match-this3',
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

    window:set_wmclass('Welcome', 'Welcome')

    -- Show window and start the loop.
    window:show_all()
    Gtk.main()
"
]]

local accent_color = beautiful.random_accent_color()

function welcome:show()
    helpers.client.run_or_raise({class = "Welcome"}, false, window, { switchtotag = true })
    self._private.visible = true
end

function welcome:hide()
    self._private.client:kill()
    self._private.visible = false
end

function welcome:toggle()
    if self._private.visible == true then
        self:hide()
    else
        self:show()
    end
end

local function indicator(active)
    return wibox.widget
    {
        widget = wibox.container.background,
        forced_width = dpi(20),
        shape = gshape.circle,
        bg = active and accent_color or helpers.color.lighten(beautiful.colors.surface, 0.2)
    }
end

local function last_page(on_next_pressed)
    local icon = widgets.text
    {
        halign = "center",
        size = 120,
        font = beautiful.circle_check_icon.font,
        text = beautiful.circle_check_icon.icon
    }

    local title = widgets.text
    {
        halign = "center",
        size = 30,
        text = "Congratulations"
    }

    local description = widgets.text
    {
        halign = "center",
        size = 13,
        text = [[Your system is now ready to be used!
For more information visit the following links.]],
    }

    local github_link = widgets.button.text.normal
    {
        forced_width = dpi(300),
        animate_size = false,
        halign = "center",
        size = 13,
        text_normal_bg = accent_color,
        text = "Github...",
        on_press = function()
            awful.spawn("xdg-open ")
        end,
    }

    local reddit_link = widgets.button.text.normal
    {
        forced_width = dpi(300),
        animate_size = false,
        halign = "center",
        size = 13,
        text_normal_bg = accent_color,
        text = "Reddit...",
        on_press = function()
            awful.spawn("xdg-open ")
        end,
    }

    local awesome_link = widgets.button.text.normal
    {
        forced_width = dpi(300),
        animate_size = false,
        halign = "center",
        size = 13,
        text_normal_bg = accent_color,
        text = "Awesome...",
        on_press = function()
            awful.spawn("xdg-open https://awesomewm.org/apidoc/")
        end,
    }

    local finish_button = widgets.button.text.normal
    {
        animate_size = false,
        halign = "center",
        text_normal_bg = accent_color,
        size = 13,
        text = "Finish",
        on_press = function()
            settings:set_value("welcome.show", false)
            on_next_pressed()
        end,
    }

    return wibox.widget
    {
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
                    github_link,
                },
                {
                    widget = wibox.container.place,
                    halign = "center",
                    valign = "center",
                    reddit_link,
                },
                {
                    widget = wibox.container.place,
                    halign = "center",
                    valign = "center",
                    awesome_link,
                }
            },
            nil,
            finish_button
        }
    }
end

local function weather_page(on_next_pressed, on_previous_pressed)
    local icon = widgets.text
    {
        halign = "center",
        size = 120,
        font = beautiful.clouds_icon.font,
        text = beautiful.clouds_icon.icon
    }

    local title = widgets.text
    {
        halign = "center",
        size = 30,
        text = "Weather"
    }

    local sign_up_open_weather_map = widgets.button.text.normal
    {
        halign = "center",
        size = 13,
        text_normal_bg = beautiful.colors.on_background,
        text = "1. Sign up and login on OpenWeatherMap.",
        on_press = function()
            awful.spawn("xdg-open https://home.openweathermap.org/users/sign_up", false)
        end
    }

    local visit_the_api_key_tab = widgets.button.text.normal
    {
        halign = "center",
        size = 13,
        text_normal_bg = beautiful.colors.on_background,
        text = "2. Visit the API key tab",
        on_press = function()
            awful.spawn("xdg-open https://home.openweathermap.org/api_keys", false)
        end
    }

    local generate_key = widgets.button.text.normal
    {
        halign = "center",
        size = 13,
        text_normal_bg = beautiful.colors.on_background,
        text = "3. Select a name for your key and click generate",
    }

    local copy_and_paste_key = widgets.button.text.normal
    {
        halign = "center",
        size = 13,
        text_normal_bg = beautiful.colors.on_background,
        text = "4. Copy the generated key and paste it in the prompt below",
    }

    local api_key_prompt = widgets.prompt
    {
        forced_width = dpi(250),
        forced_height = dpi(50),
        reset_on_stop = false,
        prompt = "API Key: ",
        text = weather_daemon:get_api_key() or "",
        icon_font = beautiful.lock_icon.font,
        icon = beautiful.lock_icon.icon,
        icon_color = beautiful.colors.on_background,
        text_color = beautiful.colors.on_background,
    }

    local coordinate_x_prompt = widgets.prompt
    {
        forced_width = dpi(250),
        forced_height = dpi(50),
        reset_on_stop = false,
        prompt = "Lat: ",
        text = weather_daemon:get_coordinate_x() or "",
        icon_font = beautiful.location_dot_icon.font,
        icon = beautiful.location_dot_icon.icon,
        icon_color = beautiful.colors.on_background,
        text_color = beautiful.colors.on_background,
    }

    local coordinate_y_prompt = widgets.prompt
    {
        forced_width = dpi(250),
        forced_height = dpi(50),
        reset_on_stop = false,
        prompt = "Lon: ",
        text = weather_daemon:get_coordinate_y() or "",
        icon_font = beautiful.location_dot_icon.font,
        icon = beautiful.location_dot_icon.icon,
        icon_color = beautiful.colors.on_background,
        fg_cursor = beautiful.colors.on_background,
    }

    local unit_dropdown = widgets.dropdown
    {
        forced_width = dpi(250),
        forced_height = dpi(50),
        prompt = "Unit: ",
        initial_value = weather_daemon:get_unit(),
        values =
        {
            ["metric"] = "metric",
            ["imperial"] = "imperial",
            ["standard"] = "standard",
        },
        on_value_selected = function(value)

        end
    }

    local back_button = widgets.button.text.normal
    {
        animate_size = false,
        halign = "center",
        text_normal_bg = accent_color,
        size = 13,
        text = "Back",
        on_press = function()
            on_previous_pressed()
        end,
    }

    local next_button = widgets.button.text.normal
    {
        animate_size = false,
        halign = "center",
        text_normal_bg = accent_color,
        size = 13,
        text = "Next",
        on_press = function()
            weather_daemon:set_unit(unit_dropdown:get_value())
            weather_daemon:set_api_key(api_key_prompt:get_text())
            weather_daemon:set_coordinate_x(coordinate_x_prompt:get_text())
            weather_daemon:set_coordinate_y(coordinate_y_prompt:get_text())
            weather_daemon:refresh()
            on_next_pressed()
        end,
    }

    return wibox.widget
    {
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
                        api_key_prompt.widget,
                    },
                    {
                        widget = wibox.container.place,
                        halign = "center",
                        valign = "center",
                        coordinate_x_prompt.widget,
                    },
                    {
                        widget = wibox.container.place,
                        halign = "center",
                        valign = "center",
                        coordinate_y_prompt.widget,
                    },
                    {
                        widget = wibox.container.place,
                        halign = "center",
                        valign = "center",
                        unit_dropdown
                    }
                },
            },
            nil,
            {
                layout = wibox.layout.align.horizontal,
                expand = "outside",
                back_button,
                {
                    widget = wibox.container.margin,
                    margins = { left = dpi(20), right = dpi(20) },
                    {
                        layout = wibox.layout.fixed.horizontal,
                        spacing = dpi(30),
                        indicator(false),
                        indicator(false),
                        indicator(false),
                        indicator(false),
                        indicator(false),
                        indicator(true),
                        indicator(false),
                    }
                },
                next_button
            },
        }
    }
end

local function gitlab_page(on_next_pressed, on_previous_pressed)
    local icon = widgets.text
    {
        halign = "center",
        size = 120,
        font = beautiful.gitlab_icon.font,
        text = beautiful.gitlab_icon.icon
    }

    local title = widgets.text
    {
        halign = "center",
        size = 30,
        text = "Gitlab"
    }

    local login_on_gitlab = widgets.button.text.normal
    {
        halign = "center",
        size = 13,
        text_normal_bg = beautiful.colors.on_background,
        text = "1. Login on GitLab.",
        on_press = function()
            awful.spawn("xdg-open https://gitlab.com", false)
        end
    }

    local visit_access_tokens_tab = widgets.button.text.normal
    {
        halign = "center",
        size = 13,
        text_normal_bg = beautiful.colors.on_background,
        text = "2. Visit the access tokens tab.",
        on_press = function()
            awful.spawn("xdg-open https://gitlab.com/-/profile/personal_access_tokens", false)
        end
    }

    local enter_a_name_and_date = widgets.button.text.normal
    {
        halign = "center",
        size = 13,
        text_normal_bg = beautiful.colors.on_background,
        text = "3. Enter a name and optional expiry date for the token.",
    }

    local select_the_desired_scopes = widgets.button.text.normal
    {
        halign = "center",
        size = 13,
        text_normal_bg = beautiful.colors.on_background,
        text = "4. Select the desired scopes.",
    }

    local press_create_access_token = widgets.button.text.normal
    {
        halign = "center",
        size = 13,
        text_normal_bg = beautiful.colors.on_background,
        text = "5. Press Create personal access token.",
    }

    local host_prompt = widgets.prompt
    {
        forced_width = dpi(300),
        forced_height = dpi(50),
        reset_on_stop = false,
        prompt = "Host: ",
        text = gitlab_daemon:get_host() or "",
        icon_font = beautiful.server_icon.font,
        icon = beautiful.server_icon.icon,
        icon_color = beautiful.colors.on_background,
        text_color = beautiful.colors.on_background,
    }

    local access_token_prompt = widgets.prompt
    {
        forced_width = dpi(300),
        forced_height = dpi(50),
        reset_on_stop = false,
        prompt = "Access Token: ",
        text = gitlab_daemon:get_access_token() or "",
        icon_font = beautiful.lock_icon.font,
        icon = beautiful.lock_icon.icon,
        icon_color = beautiful.colors.on_background,
        text_color = beautiful.colors.on_background,
    }

    local back_button = widgets.button.text.normal
    {
        animate_size = false,
        halign = "center",
        text_normal_bg = accent_color,
        size = 13,
        text = "Back",
        on_press = function()
            on_previous_pressed()
        end,
    }

    local next_button = widgets.button.text.normal
    {
        animate_size = false,
        halign = "center",
        text_normal_bg = accent_color,
        size = 13,
        text = "Next",
        on_press = function()
            gitlab_daemon:set_access_token(access_token_prompt:get_text())
            gitlab_daemon:set_host(host_prompt:get_text())
            gitlab_daemon:refresh()
            on_next_pressed()
        end,
    }

    return wibox.widget
    {
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
                    access_token_prompt.widget,
                },
                {
                    widget = wibox.container.place,
                    halign = "center",
                    valign = "center",
                    host_prompt.widget,
                }
            },
            nil,
            {
                layout = wibox.layout.align.horizontal,
                expand = "outside",
                back_button,
                {
                    widget = wibox.container.margin,
                    margins = { left = dpi(20), right = dpi(20) },
                    {
                        layout = wibox.layout.fixed.horizontal,
                        spacing = dpi(30),
                        indicator(false),
                        indicator(false),
                        indicator(false),
                        indicator(false),
                        indicator(true),
                        indicator(false),
                        indicator(false),
                    }
                },
                next_button
            },
        }
    }
end

local function github_page(on_next_pressed, on_previous_pressed)
    local icon = widgets.text
    {
        halign = "center",
        size = 120,
        font = beautiful.github_icon.font,
        text = beautiful.github_icon.icon
    }

    local title = widgets.text
    {
        halign = "center",
        size = 30,
        text = "Github"
    }

    local description = widgets.text
    {
        halign = "center",
        size = 13,
        text = "Please fill your GitHub username in order for the GitHub panel info to show.",
    }

    local username_prompt = widgets.prompt
    {
        forced_width = dpi(300),
        forced_height = dpi(50),
        reset_on_stop = false,
        prompt = "Username: ",
        text = github_daemon:get_username() or "",
        icon_font = beautiful.user_icon.font,
        icon = beautiful.user_icon.icon,
        icon_color = beautiful.colors.on_background,
        text_color = beautiful.colors.on_background,
    }

    local back_button = widgets.button.text.normal
    {
        animate_size = false,
        halign = "center",
        text_normal_bg = accent_color,
        size = 13,
        text = "Back",
        on_press = function()
            on_previous_pressed()
        end,
    }

    local next_button = widgets.button.text.normal
    {
        animate_size = false,
        halign = "center",
        text_normal_bg = accent_color,
        size = 13,
        text = "Next",
        on_press = function()
            github_daemon:set_username(username_prompt:get_text())
            github_daemon:refresh()
            on_next_pressed()
        end,
    }

    return wibox.widget
    {
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
                    username_prompt.widget,
                },
            },
            nil,
            {
                layout = wibox.layout.align.horizontal,
                expand = "outside",
                back_button,
                {
                    widget = wibox.container.margin,
                    margins = { left = dpi(20), right = dpi(20) },
                    {
                        layout = wibox.layout.fixed.horizontal,
                        spacing = dpi(30),
                        indicator(false),
                        indicator(false),
                        indicator(false),
                        indicator(true),
                        indicator(false),
                        indicator(false),
                        indicator(false),
                    }
                },
                next_button
            },
        }
    }
end

local function email_page(on_next_pressed, on_previous_pressed)
    local icon = widgets.text
    {
        halign = "center",
        size = 120,
        font = beautiful.envelope_icon.font,
        text = beautiful.envelope_icon.icon
    }

    local title = widgets.text
    {
        halign = "center",
        size = 30,
        text = "Email"
    }

    local description = widgets.text
    {
        halign = "center",
        size = 13,
        text = "Please fill your email info in order for the email panel info to show.",
    }

    local machine_prompt = widgets.prompt
    {
        forced_width = dpi(300),
        forced_height = dpi(50),
        reset_on_stop = false,
        prompt = "Machine: ",
        text = email_daemon:get_machine() or "mail.google.com",
        icon_font = beautiful.server_icon.font,
        icon = beautiful.server_icon.icon,
        icon_color = beautiful.colors.on_background,
        text_color = beautiful.colors.on_background,
    }

    local login_prompt = widgets.prompt
    {
        forced_width = dpi(300),
        forced_height = dpi(50),
        reset_on_stop = false,
        prompt = "Login: ",
        text = email_daemon:get_login() or "",
        icon_font = beautiful.user_icon.font,
        icon = beautiful.user_icon.icon,
        icon_color = beautiful.colors.on_background,
        text_color = beautiful.colors.on_background,
    }

    local password_prompt = widgets.prompt
    {
        forced_width = dpi(300),
        forced_height = dpi(50),
        reset_on_stop = false,
        prompt = "Password: ",
        text = email_daemon:get_password() or "",
        icon_font = beautiful.lock_icon.font,
        icon = beautiful.lock_icon.icon,
        icon_color = beautiful.colors.on_background,
        text_color = beautiful.colors.on_background,
    }

    local back_button = widgets.button.text.normal
    {
        animate_size = false,
        halign = "center",
        text_normal_bg = accent_color,
        size = 13,
        text = "Back",
        on_press = function()
            on_previous_pressed()
        end,
    }

    local next_button = widgets.button.text.normal
    {
        animate_size = false,
        halign = "center",
        text_normal_bg = accent_color,
        size = 13,
        text = "Next",
        on_press = function()
            email_daemon:update_net_rc(machine_prompt:get_text(), login_prompt:get_text(), password_prompt:get_text())
            on_next_pressed()
        end,
    }

    return wibox.widget
    {
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
                    machine_prompt.widget,
                },
                {
                    widget = wibox.container.place,
                    halign = "center",
                    valign = "center",
                    login_prompt.widget,
                },
                {
                    widget = wibox.container.place,
                    halign = "center",
                    valign = "center",
                    password_prompt.widget,
                }
            },
            nil,
            {
                layout = wibox.layout.align.horizontal,
                expand = "outside",
                back_button,
                {
                    widget = wibox.container.margin,
                    margins = { left = dpi(20), right = dpi(20) },
                    {
                        layout = wibox.layout.fixed.horizontal,
                        spacing = dpi(30),
                        indicator(false),
                        indicator(false),
                        indicator(true),
                        indicator(false),
                        indicator(false),
                        indicator(false),
                        indicator(false),
                    }
                },
                next_button
            },
        }
    }
end

local function password_page(on_next_pressed, on_previous_pressed)
    local icon = widgets.text
    {
        halign = "center",
        size = 120,
        font = beautiful.lock_icon.font,
        text = beautiful.lock_icon.icon
    }

    local title = widgets.text
    {
        halign = "center",
        size = 30,
        text = "Password"
    }

    local description = widgets.text
    {
        halign = "center",
        size = 13,
        text = "Please pick a password for the lock screen.",
    }

    local password_prompt = widgets.prompt
    {
        forced_width = dpi(300),
        forced_height = dpi(50),
        reset_on_stop = false,
        prompt = "Password: ",
        text = system_daemon:get_password() or "",
        icon_font = beautiful.lock_icon.font,
        icon = beautiful.lock_icon.icon,
        icon_color = beautiful.colors.on_background,
        text_color = beautiful.colors.on_background,
    }

    local back_button = widgets.button.text.normal
    {
        animate_size = false,
        halign = "center",
        text_normal_bg = accent_color,
        size = 13,
        text = "Back",
        on_press = function()
            on_previous_pressed()
        end,
    }

    local next_button = widgets.button.text.normal
    {
        animate_size = false,
        halign = "center",
        text_normal_bg = accent_color,
        size = 13,
        text = "Next",
        on_press = function()
            system_daemon:set_password(password_prompt:get_text())
            on_next_pressed()
        end,
    }

    return wibox.widget
    {
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
                    password_prompt.widget,
                },
            },
            nil,
            {
                layout = wibox.layout.align.horizontal,
                expand = "outside",
                back_button,
                {
                    widget = wibox.container.margin,
                    margins = { left = dpi(20), right = dpi(20) },
                    {
                        layout = wibox.layout.fixed.horizontal,
                        spacing = dpi(30),
                        indicator(false),
                        indicator(true),
                        indicator(false),
                        indicator(false),
                        indicator(false),
                        indicator(false),
                        indicator(false),
                    }
                },
                next_button
            },
        }
    }
end

local function welcome_page(on_next_pressed, on_previous_pressed)
    local function picture(value)
        return wibox.widget
        {
            widget = wibox.widget.imagebox,
            forced_width = dpi(260),
            forced_height = dpi(100),
            horizontal_fit_policy = "fit",
            vertical_fit_policy = "fit",
            image = beautiful.overview_pictures[value]
        }
    end

    local icon = wibox.widget
    {
        widget = wibox.widget.imagebox,
        halign = "center",
        forced_height = dpi(140),
        forced_width = dpi(140),
        image = beautiful.profile_icon,
    }

    local title = widgets.text
    {
        halign = "center",
        size = 25,
        text = "Hi " .. os.getenv("USER"):upper() .. ", Welcome to KwesomeDE!"
    }

    local pictures = wibox.widget
    {
        layout = wibox.layout.grid,
        forced_num_rows = 4,
        forced_num_cols = 2,
        spacing = dpi(5),
        picture(1),
        picture(2),
        picture(3),
        picture(4),
        picture(5),
        picture(6),
        picture(7),
        picture(8),
    }

    local quit_button = widgets.button.text.normal
    {
        animate_size = false,
        halign = "center",
        text_normal_bg = accent_color,
        size = 13,
        text = "Quit",
        on_press = function()
            on_previous_pressed()
        end,
    }

    local next_button = widgets.button.text.normal
    {
        animate_size = false,
        halign = "center",
        text_normal_bg = accent_color,
        size = 13,
        text = "Next",
        on_press = function()
            on_next_pressed()
        end,
    }

    return wibox.widget
    {
        widget = wibox.container.margin,
        margins = dpi(15),
        {
            layout = wibox.layout.align.vertical,
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(20),
                icon,
                title,
                pictures
            },
            nil,
            {
                layout = wibox.layout.align.horizontal,
                expand = "outside",
                quit_button,
                {
                    widget = wibox.container.margin,
                    margins = { left = dpi(20), right = dpi(20) },
                    {
                        layout = wibox.layout.fixed.horizontal,
                        spacing = dpi(30),
                        indicator(true),
                        indicator(false),
                        indicator(false),
                        indicator(false),
                        indicator(false),
                        indicator(false),
                        indicator(false),
                    }
                },
                next_button
            },
        }
    }
end

local function widget(self)
    local stack = {}
    local _welcome_page = {}
    local _password_page = {}
    local _email_page = {}
    local _github_page = {}
    local _gitlab_page = {}
    local _weather_page = {}
    local _last_page = {}

    _welcome_page = welcome_page(function()
        stack:raise_widget(_password_page)
    end,
    function()
        self:hide()
    end)

    _password_page = password_page(function()
        stack:raise_widget(_email_page)
    end,
    function()
        stack:raise_widget(_welcome_page)
    end)

    _email_page = email_page(function()
        stack:raise_widget(_github_page)
    end,
    function()
        stack:raise_widget(_password_page)
    end)

    _github_page = github_page(function()
        stack:raise_widget(_gitlab_page)
    end,
    function()
        stack:raise_widget(_email_page)
    end)

    _gitlab_page = gitlab_page(function()
        stack:raise_widget(_weather_page)
    end,
    function()
        stack:raise_widget(_github_page)
    end)

    _weather_page = weather_page(function()
        stack:raise_widget(_last_page)
    end,
    function()
        stack:raise_widget(_gitlab_page)
    end)

    _last_page = last_page(function()
        self:hide()
    end)

    stack = wibox.widget
    {
        layout = wibox.layout.stack,
        top_only = true,
        _welcome_page,
        _password_page,
        _email_page,
        _github_page,
        _gitlab_page,
        _weather_page,
        _last_page
    }

    return stack
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, welcome, true)

    ret._private = {}

    ruled.client.connect_signal("request::rules", function()
        ruled.client.append_rule
        {
            rule = { name = "no-one-gonna-match-this3" },
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
                c.y = (c.screen.geometry.height / 2) - (dpi(780) / 2)

                awful.titlebar(c,
                {
                    position = "top",
                    size = dpi(780),
                    bg = beautiful.colors.background
                }) : setup
                {
                    widget = widget(ret)
                }
            end
        }
    end)

    if settings:get_value("welcome.show") ~= false then
        ret:show()
    end

    return ret
end

if not instance then
    instance = new()
end
return instance