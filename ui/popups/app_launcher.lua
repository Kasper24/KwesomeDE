-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("ui.widgets")
local tasklist_daemon = require("daemons.system.tasklist")
local app_launcher_daemon = require("daemons.system.app_launcher")
local bling = require("external.bling")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local ipairs = ipairs
local table = table
local capi = {
    awesome = awesome
}

local instance = nil

local function app_menu(app, font_icon)
    local menu = widgets.menu {
        widgets.menu.button {
            icon = font_icon,
            text = app.name,
            on_release = function(self)
                app:run()
            end
        },
        widgets.menu.button {
            text = "Run as Root",
            on_release = function(self)
                app:run_as_root()
            end
        },
        widgets.menu.checkbox_button {
            state = app_launcher_daemon:is_app_pinned(app.id),
            handle_active_color = font_icon.color,
            text = "Pin App",
            on_release = function(self)
                if app_launcher_daemon:is_app_pinned(app.id) then
                    self:turn_off()
                    app_launcher_daemon:remove_pinned_app(app.id)
                else
                    self:turn_on()
                    app_launcher_daemon:add_pinned_app(app.id)
                end
            end
        }
    }

    for index, action in ipairs(app.desktop_app_info:list_actions()) do
        if index == 1 then
            menu:add(widgets.menu.separator())
        end

        menu:add(widgets.menu.button {
            text = app.desktop_app_info:get_action_name(action),
            on_release = function()
                app.desktop_app_info:launch_action(action)
            end
        })
    end

    return menu
end

local function app(app, app_launcher)
    local font_icon = tasklist_daemon:get_font_icon(app.id:gsub(".desktop", ""),
        app.name,
        app.exec,
        app.startup_wm_class,
        app.icon_name
    )

    local menu = app_menu(app, font_icon)

    local widget = wibox.widget {
        widget = widgets.button.elevated.state,
        id = "button",
        forced_width = dpi(325),
        forced_height = dpi(50),
        paddings = dpi(15),
        halign = "left",
        on_normal_bg = font_icon.color,
        on_release = function()
            app:run_or_select()
        end,
        on_secondary_release = function()
            app:select()
            menu:toggle()
        end,
        {
            layout = wibox.layout.fixed.horizontal,
            spacing = dpi(15),
            {
                widget = widgets.text,
                scale = 0.8,
                text_normal_bg = font_icon.color,
                text_on_normal_bg = beautiful.colors.transparent,
                icon = font_icon
            },
            {
                widget = wibox.container.place,
                halign = "center",
                valign = "center",
                {
                    widget = widgets.text,
                    size = 12,
                    text_normal_bg = beautiful.colors.on_background,
                    text_on_normal_bg = beautiful.colors.transparent,
                    text = app.name
                }
            }
        }
    }

    widget:connect_signal("select", function()
        menu:hide()
        widget:turn_on()
    end)

    widget:connect_signal("unselect", function()
        menu:hide()
        widget:turn_off()
    end)

    app_launcher:connect_signal("scroll", function()
        menu:hide()
    end)

    app_launcher:connect_signal("page::forward", function()
        menu:hide()
    end)

    app_launcher:connect_signal("page::backward", function()
        menu:hide()
    end)

    return widget
end

local function new()
    local app_launcher = bling.widget.app_launcher {
        bg = beautiful.colors.background,
        widget_template = wibox.widget {
            layout = widgets.rofi_grid,
            lazy_load_widgets = false,
            widget_template = wibox.widget {
                widget = wibox.container.margin,
                margins = dpi(15),
                {
                    layout = wibox.layout.fixed.vertical,
                    spacing = dpi(15),
                    {
                        widget = widgets.text_input,
                        id = "text_input_role",
                        forced_width = dpi(650),
                        forced_height = dpi(60),
                        unfocus_keys = { },
                        unfocus_on_clicked_inside = false,
                        unfocus_on_clicked_outside = false,
                        unfocus_on_mouse_leave = false,
                        unfocus_on_tag_change = false,
                        unfocus_on_other_text_input_focus = false,
                        focus_on_subject_mouse_enter = nil,
                        unfocus_on_subject_mouse_leave = nil,
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
                                        icon = beautiful.icons.magnifying_glass
                                    },
                                    {
                                        layout = wibox.layout.stack,
                                        {
                                            widget = wibox.widget.textbox,
                                            id = "placeholder_role",
                                            text = "Search: "
                                        },
                                        {
                                            widget = wibox.widget.textbox,
                                            id = "text_role"
                                        },
                                    }
                                }
                            }
                        }
                    },
                    {
                        layout = wibox.layout.fixed.horizontal,
                        spacing = dpi(15),
                        {
                            layout = wibox.layout.grid,
                            id = "grid_role",
                            orientation = "horizontal",
                            homogeneous = true,
                            spacing = dpi(15),
                            forced_num_cols = 2,
                            forced_num_rows = 8,
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
                                handle_color = beautiful.bg_normal,
                                handle_shape = helpers.ui.rrect(),
                                handle_color = beautiful.colors.on_background
                            }
                        }
                    }
                }
            },
            entry_template = app
        },
    }

    local animation = helpers.animation:new{
        pos = 1,
        easing = helpers.animation.easing.outExpo,
        duration = 0.5,
        update = function(_, pos)
            app_launcher:get_widget().widget.forced_height = pos
        end,
        signals = {
            ["ended"] = function()
                if app_launcher._private.state == false then
                    app_launcher:get_widget().visible = false
                    app_launcher:get_text_input():set_text("")
                    app_launcher:get_rofi_grid():reset()
                end
            end
        }
    }

    function app_launcher:show()
        app_launcher._private.state = true
        app_launcher:get_widget().visible = true
        app_launcher:get_text_input():focus()
        app_launcher:emit_signal("visibility", true)

        animation.easing = helpers.animation.easing.outExpo
        animation:set(dpi(620))
    end

    function app_launcher:hide()
        app_launcher._private.state = false
        app_launcher:get_text_input():unfocus()
        app_launcher:emit_signal("visibility", false)

        animation.easing = helpers.animation.easing.inExpo
        animation:set(1)
    end

    local pinned_apps = {}
    app_launcher_daemon:connect_signal("pinned_app::added", function(self, pinned_app)
        table.insert(pinned_apps, pinned_app.id)
        app_launcher:set_favorites(pinned_apps)
    end)

    app_launcher_daemon:connect_signal("pinned_app::removed", function(self, pinned_app)
        helpers.table.remove_value(pinned_apps, pinned_app.id)
        app_launcher:set_favorites(pinned_apps)
    end)

    app_launcher:get_rofi_grid():connect_signal("button::press", function(grid, lx, ly, button, mods, find_widgets_result)
        if button == 3 then
            local selected_app = app_launcher:get_rofi_grid():get_selected_widget()
            if selected_app then
                selected_app:unselect()
            end
        end
    end)

    capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
        app_launcher:get_widget().widget.bg = old_colorscheme_to_new_map[beautiful.colors.background]
    end)

    return app_launcher
end

if not instance then
    instance = new()
end
return instance
