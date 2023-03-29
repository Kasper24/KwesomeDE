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

local wallpapers_grid = {
    mt = {}
}

local function new(wallpapers_key, entry_template)
    local layout = wibox.widget {
        layout = widgets.rofi_grid,
        widget_template = wibox.widget {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            {
                widget = widgets.text_input,
                id = "text_input_role",
                -- forced_width = dpi(800),
                forced_height = dpi(55),
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
                                icon = beautiful.icons.magnifying_glass,
                                color = beautiful.icons.computer.color
                            },
                            {
                                layout = wibox.layout.stack,
                                {
                                    widget = wibox.widget.textbox,
                                    id = "placeholder_role",
                                    text = "Search:"
                                },
                                {
                                    widget = wibox.widget.textbox,
                                    id = "text_role"
                                }
                            }
                        }
                    }
                }
            },
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(10),
                {
                    layout = wibox.layout.grid,
                    id = "grid_role",
                    orientation = "horizontal",
                    homogeneous = true,
                    spacing = dpi(5),
                    forced_num_cols = 5,
                    forced_num_rows = 4,
                },
                {
                    layout = wibox.container.rotate,
                    direction = 'west',
                    {
                        widget = wibox.widget.slider,
                        id = "scrollbar_role",
                        forced_width = dpi(5),
                        forced_height = dpi(10),
                        minimum = 1,
                        value = 1,
                        bar_shape = helpers.ui.rrect(),
                        bar_height= 3,
                        bar_color = beautiful.colors.transparent,
                        bar_active_color = beautiful.colors.transparent,
                        handle_width = dpi(50),
                        handle_shape = helpers.ui.rrect(),
                        handle_color = beautiful.colors.on_background
                    }
                }
            }
        },
        entry_template = entry_template
    }

    SETTINGS_APP:connect_signal("tab::select", function()
        layout:get_text_input():unfocus()
    end)

    SETTINGS_APP:get_client():connect_signal("request::unmanage", function()
        layout:get_text_input():unfocus()
    end)

    SETTINGS_APP:get_client():connect_signal("unfocus", function()
        layout:get_text_input():unfocus()
    end)

    SETTINGS_APP:get_client():connect_signal("mouse::leave", function()
        layout:get_text_input():unfocus()
    end)

    theme_daemon:connect_signal("tab::select", function()
        layout:get_text_input():unfocus()
    end)

    theme_daemon:connect_signal("wallpapers", function()
        layout:set_entries(theme_daemon["get_" .. wallpapers_key](theme_daemon))
        collectgarbage("collect")
        collectgarbage("collect")
    end)

    layout:set_entries(theme_daemon["get_" .. wallpapers_key](theme_daemon))
    collectgarbage("collect")
    collectgarbage("collect")

    return layout
end

function wallpapers_grid.mt:__call(wallpapers_key, entry_template)
    return new(wallpapers_key, entry_template)
end

return setmetatable(wallpapers_grid, wallpapers_grid.mt)