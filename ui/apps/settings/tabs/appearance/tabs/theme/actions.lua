-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local theme_daemon = require("daemons.system.theme")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local actions = {
    mt = {}
}

local function color_button(index)
    local background = wibox.widget {
        widget = wibox.container.background,
        forced_width = dpi(200),
        forced_height = dpi(40),
        shape = helpers.ui.rrect(),
    }

    local color_text_input = wibox.widget {
        widget = widgets.text_input,
        unfocus_on_client_clicked = false,
        size = 12,
        selection_bg = beautiful.icons.computer.color,
        widget_template = wibox.widget {
            widget = wibox.widget.textbox,
            id = "text_role",
            halign = "center",
		}
    }

    local color_button = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(5),
        {
            widget = widgets.text,
            halign = "center",
            size = 12,
            text = index
        },
        {
            widget = widgets.button.normal,
            on_secondary_release = function()
                theme_daemon:set_color(index)
            end,
            {
                layout = wibox.layout.stack,
                background,
                color_text_input
            }
        }
    }

    theme_daemon:connect_signal("colorscheme::generation::success", function(self, colors, wallpaper)
        if wallpaper == theme_daemon:get_selected_colorscheme() then
            local color = colors[index]
            if helpers.color.is_dark(color) then
                color_text_input:set_text_color(beautiful.colors.white)
            else
                color_text_input:set_text_color(beautiful.colors.black)
            end
            color_text_input:set_text(color)
            background.bg = color
        end
    end)

    color_text_input:connect_signal("unfocus", function(self, context, text)
        theme_daemon:set_color(index, text)
    end)

    return color_button
end

local function run_on_set()
    local text_input = wibox.widget {
        widget = widgets.text_input,
        id = "text_input_role",
        forced_height = dpi(55),
        initial = theme_daemon:get_run_on_set(),
        unfocus_on_client_clicked = false,
        selection_bg = beautiful.icons.computer.color,
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
                        icon = beautiful.icons.computer,
                        color = beautiful.icons.computer.color
                    },
                    {
                        layout = wibox.layout.stack,
                        {
                            widget = wibox.widget.textbox,
                            id = "placeholder_role",
                            text = "Run:"
                        },
                        {
                            widget = wibox.widget.textbox,
                            id = "text_role"
                        }
                    }
                }
            }
        }
    }

    text_input:connect_signal("property::text", function(self, text)
        theme_daemon:set_run_on_set(text)
    end)

    return text_input
end

local function new()
    local colors = wibox.widget {
        widget = wibox.layout.grid,
        spacing = dpi(15),
        forced_num_rows = 2,
        forced_num_cols = 8,
        expand = true
    }

    local spinning_circle = widgets.spinning_circle {
        forced_width = dpi(250),
        forced_height = dpi(250),
        thickness = dpi(30),
        run_by_default = false
    }

    local light_dark = wibox.widget {
        widget = widgets.button.normal,
        normal_bg = beautiful.icons.computer.color,
        on_release = function()
            theme_daemon:toggle_dark_light()
        end,
        {
            widget = widgets.text,
            color = beautiful.colors.on_accent,
            size = 15,
            text = "Light",
        }
    }

    local reset_colorscheme = wibox.widget {
        widget = widgets.button.normal,
        normal_bg = beautiful.icons.computer.color,
        on_release = function()
            theme_daemon:reset_colorscheme()
        end,
        {
            widget = widgets.text,
            color = beautiful.colors.on_accent,
            size = 15,
            text = "Reset Colorscheme",
        }
    }

    local save_colorscheme = wibox.widget {
        widget = widgets.button.normal,
        normal_bg = beautiful.icons.computer.color,
        on_release = function()
            theme_daemon:save_colorscheme()
        end,
        {
            widget = widgets.text,
            color = beautiful.colors.on_accent,
            size = 15,
            text = "Save Colorscheme",
        }
    }

    local set_wallpaper = wibox.widget {
        widget = widgets.button.normal,
        normal_bg = beautiful.icons.computer.color,
        on_release = function()
            theme_daemon:set_wallpaper(theme_daemon:get_selected_colorscheme())
        end,
        {
            widget = widgets.text,
            color = beautiful.colors.on_accent,
            size = 15,
            text = "Set Wallpaper",
        }
    }

    local set_colorscheme = wibox.widget {
        widget = widgets.button.normal,
        normal_bg = beautiful.icons.computer.color,
        on_release = function()
            theme_daemon:set_colorscheme(theme_daemon:get_selected_colorscheme())
        end,
        {
            widget = widgets.text,
            color = beautiful.colors.on_accent,
            size = 15,
            text = "Set Colorscheme",
        }
    }

    local set_both = wibox.widget {
        widget = widgets.button.normal,
        normal_bg = beautiful.icons.computer.color,
        on_release = function()
            theme_daemon:set_wallpaper(theme_daemon:get_selected_colorscheme())
            theme_daemon:set_colorscheme(theme_daemon:get_selected_colorscheme())
        end,
        {
            widget = widgets.text,
            color = beautiful.colors.on_accent,
            size = 15,
            text = "Set Both",
        }
    }

    local widget = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        colors,
        run_on_set(),
        {
            layout = wibox.layout.grid,
            spacing = dpi(10),
            forced_num_rows = 3,
            forced_num_cols = 3,
            horizontal_expand = true,
            light_dark,
            reset_colorscheme,
            save_colorscheme,
            set_wallpaper,
            set_colorscheme,
            set_both
        }
    }

    local stack = wibox.widget {
        layout = wibox.layout.stack,
        top_only = true,
        spinning_circle,
        widget
    }

    theme_daemon:connect_signal("colorscheme::generation::start", function()
        spinning_circle:start()
        stack:raise_widget(spinning_circle)
    end)

    theme_daemon:connect_signal("colorscheme::generation::error", function()
        spinning_circle:stop()
        stack:raise_widget(widget)
    end)

    theme_daemon:connect_signal("colorscheme::generation::success", function(self, colors, wallpaper)
        if wallpaper == theme_daemon:get_selected_colorscheme() then
            if helpers.color.is_dark(colors[1]) then
                light_dark:set_text("Light")
            else
                light_dark:set_text("Dark")
            end
            spinning_circle:stop()
            stack:raise_widget(widget)
        end
    end)

    for i = 1, 16 do
        colors:add(color_button(i))
    end

    return stack
end

function actions.mt:__call()
    return new()
end

return setmetatable(actions, actions.mt)
