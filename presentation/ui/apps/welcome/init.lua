local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gshape = require("gears.shape")
local ruled = require("ruled")
local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local beautiful = require("beautiful")
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
        bg = active and accent_color or helpers.color.lighten(beautiful.colors.surface, 50)
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

    local description = widgets.text
    {
        halign = "center",
        size = 13,
        text = "Please fill the details down below for some useful features.",
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
        prompt = "Coordinate X: ",
        text = weather_daemon:get_coordinate_x() or "",
        icon_font = beautiful.clouds_icon.font,
        icon = beautiful.clouds_icon.icon,
        icon_color = beautiful.colors.on_background,
        text_color = beautiful.colors.on_background,
    }

    local coordinate_y_prompt = widgets.prompt
    {
        forced_width = dpi(250),
        forced_height = dpi(50),
        reset_on_stop = false,
        prompt = "Coordinate Y: ",
        text = weather_daemon:get_coordinate_y() or "",
        icon_font = beautiful.clouds_icon.font,
        icon = beautiful.clouds_icon.icon,
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
            ["kelvin"] = "kelvin",
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
                description,
                {
                    widget = wibox.container.place,
                    halign = "center",
                    valign = "center",
                    unit_dropdown
                },
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

    local description = widgets.text
    {
        halign = "center",
        size = 13,
        text = "Please fill the details down below for some useful features.",
    }

    local host_prompt = widgets.prompt
    {
        forced_width = dpi(300),
        forced_height = dpi(50),
        reset_on_stop = false,
        prompt = "Host: ",
        text = gitlab_daemon:get_host() or "",
        icon_font = beautiful.gitlab_icon.font,
        icon = beautiful.gitlab_icon.icon,
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
        icon_font = beautiful.gitlab_icon.font,
        icon = beautiful.gitlab_icon.icon,
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
                description,
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
        text = "Please fill the details down below for some useful features.",
    }

    local username_prompt = widgets.prompt
    {
        forced_width = dpi(300),
        forced_height = dpi(50),
        reset_on_stop = false,
        prompt = "Username: ",
        text = github_daemon:get_username() or "",
        icon_font = beautiful.github_icon.font,
        icon = beautiful.github_icon.icon,
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

local function welcome_page(on_next_pressed, on_previous_pressed)
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
        size = 30,
        text = "Hi " .. os.getenv("USER"):upper() .. "!"
    }

    local description = widgets.text
    {
        halign = "center",
        size = 13,
        text =  "Continue to set up some useful features. Visit the links below for more information about KasperOS!",
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
                description,
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
    local _github_page = {}
    local _gitlab_page = {}
    local _weather_page = {}
    local _last_page = {}

    _welcome_page = welcome_page(function()
        stack:raise_widget(_github_page)
    end,
    function()
        self:hide()
    end)

    _github_page = github_page(function()
        stack:raise_widget(_gitlab_page)
    end,
    function()
        stack:raise_widget(_welcome_page)
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
            properties = { floating = true, width = 550, height = 1, placement = awful.placement.centered },
            callback = function(c)
                ret._private.client = c

                c:connect_signal("unmanage", function()
                    ret._private.visible = false
                    ret._private.client = nil
                end)

                c.can_resize = false
                c.custom_titlebar = false
                c.can_tile = false

                awful.titlebar(c,
                {
                    position = "top",
                    size = dpi(720),
                    bg = string.sub(beautiful.colors.background, 1, 7)
                }) : setup
                {
                    widget = widget(ret)
                }
            end
        }
    end)

    settings:is_settings_readable(function(result)
        if result == false then
            ret:show()
        end
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance