-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local helpers = require("helpers")
local wifi_tab = require("ui.apps.settings.tabs.wifi")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable
local capi = {
    awesome = awesome
}

local main = {
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

local function navbar_button(app, id, icon, title)
    return wibox.widget {
        widget = widgets.button.elevated.state,
        halign = "left",
        on_normal_bg = beautiful.icons.spraycan.color,
        on_release = function()
            app:emit_signal("tab::select", id)
        end,
        {
            layout = wibox.layout.fixed.horizontal,
            spacing = dpi(15),
            {
                widget = widgets.text,
                size = 13,
                halign = "left",
                text_normal_bg = beautiful.colors.on_background,
                text_on_normal_bg = beautiful.colors.on_accent,
                icon = icon,
            },
            {
                widget = widgets.text,
                size = 13,
                halign = "left",
                text_normal_bg = beautiful.colors.on_background,
                text_on_normal_bg = beautiful.colors.on_accent,
                text = title,
            }
        }
    }

end

local function tabs(app)
    local groups = {
        {
            {
                id = "wifi",
                button = navbar_button(app, "wifi", beautiful.icons.network.wifi_high, "Wi-Fi"),
                tab = wifi_tab()
            },
            {
                id = "bluetooth",
                button = navbar_button(app, "bluetooth", beautiful.icons.bluetooth.on, "Bluetooth"),
                tab = wifi_tab()
            },
        },
        {
            {
                id = "accounts",
                button = navbar_button(app, "accounts", beautiful.icons.user, "Accounts"),
                tab = wifi_tab()
            },
        },
        {
            {
                id = "theme",
                button = navbar_button(app, "theme", beautiful.icons.user, "Theme"),
                tab = wifi_tab()
            },
            {
                id = "look_and_feel",
                button = navbar_button(app, "look_and_feel", beautiful.icons.user, "Look and Feel"),
                tab = wifi_tab()
            },
            {
                id = "wallpaper_engine",
                button = navbar_button(app, "wallpaper_engine", beautiful.icons.user, "Wallpaper Engine"),
                tab = wifi_tab()
            },
            {
                id = "picom",
                button = navbar_button(app, "picom", beautiful.icons.user, "Picom"),
                tab = wifi_tab()
            }
        }
    }

    local picture = wibox.widget {
        widget = widgets.profile,
        forced_height = dpi(50),
        forced_width = dpi(50),
        valign = "center",
        clip_shape = helpers.ui.rrect(),
    }

    local name = wibox.widget {
        widget = widgets.text,
        size = 15,
        italic = true,
        text = os.getenv("USER") .. "@" .. capi.awesome.hostname
    }

    local user = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15),
        picture,
        name
    }

    local navbar_buttons = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
    }

    local navbar = wibox.widget {
        widget = wibox.container.constraint,
        mode = "max",
        width = dpi(300),
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(30),
            user,
            navbar_buttons
        }
    }

    local tabs_stack = wibox.widget {
        layout = wibox.layout.stack,
        top_only = true,
    }

    for index, group in ipairs(groups) do
        for _, entry in ipairs(group) do
            navbar_buttons:add(entry.button)
            tabs_stack:add(entry.tab)
        end
        if index ~= #groups then
            navbar_buttons:add(separator())
        end
    end

    app:connect_signal("tab::select", function(self, id)
        for _, group in ipairs(groups) do
            for _, entry in ipairs(group) do
                if entry.id == id then
                    tabs_stack:raise_widget(entry.tab)
                    entry.button:turn_on()
                else
                    entry.button:turn_off()
                end
            end
        end
    end)

    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        fill_space = true,
        spacing = dpi(15),
        navbar,
        {
            widget = wibox.container.place,
            halign = "center",
            valign = "top",
            tabs_stack
        }
    }
end

local function new(app)
    local back_button = wibox.widget {
        widget = widgets.button.text.normal,
        forced_width = dpi(50),
        forced_height = dpi(50),
        text_normal_bg = beautiful.icons.spraycan.color,
        icon = beautiful.icons.left,
        on_release = function()

        end
    }

    local title = wibox.widget {
        widget = widgets.text,
        bold = true,
        size = 15,
        text = "Settings"
    }

    local close_button = wibox.widget {
        widget = widgets.button.text.normal,
        forced_width = dpi(40),
        forced_height = dpi(40),
        text_normal_bg = beautiful.icons.spraycan.color,
        icon = beautiful.icons.xmark,
        on_release = function()
            theme_app:hide()
        end
    }

    local widget = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        {
            layout = wibox.layout.align.horizontal,
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(15),
                back_button,
                title
            },
            nil,
            close_button
        },
        {
            widget = wibox.container.margin,
            margins = dpi(20),
            tabs(app)
        }
    }

    return widget
end

function main.mt:__call(app)
    return new(app)
end

return setmetatable(main, main.mt)
