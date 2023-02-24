-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("ui.widgets")
local tasklist_daemon = require("daemons.system.tasklist")
local bling = require("external.bling")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local capi = {
    awesome = awesome
}

local instance = nil

local function new()
    local app_launcher = bling.widget.app_launcher {
        bg = beautiful.colors.background,
        widget_template = wibox.widget {
            layout = wibox.layout.stack,
            {
                widget = widgets.wallpaper,
                forced_width = dpi(600),
            },
            {
                widget = widgets.background,
                bg = beautiful.colors.background_blur,
            },
            {
                widget = wibox.container.margin,
                margins = dpi(15),
                {
                    layout = wibox.layout.fixed.vertical,
                    spacing = dpi(15),
                    {
                        widget = wibox.container.place,
                        halign = "left",
                        valign = "top",
                        {
                            widget = widgets.background,
                            forced_width = dpi(650),
                            forced_height = dpi(60),
                            shape = helpers.ui.rrect(),
                            bg = beautiful.colors.surface_no_opacity,
                            {
                                widget = wibox.container.margin,
                                margins = dpi(15),
                                {
                                    widget = widgets.prompt,
                                    id = "prompt_role",
                                    always_on = true,
                                    icon = beautiful.icons.firefox,
                                }
                            }
                        }
                    },
                    {
                        layout = wibox.layout.grid,
                        id = "grid_role",
                        orientation = "horizontal",
                        homogeneous = true,
                        spacing = dpi(15),
                        forced_num_cols = 5,
                        forced_num_rows = 3,
                    }
                }
            },
        },
        app_template = function(app)
            local font_icon = tasklist_daemon:get_font_icon(app.id:gsub(".desktop", ""),
                app.name,
                app.startup_wm_class,
                app.icon_name
            )

            local menu = widgets.menu {
                widgets.menu.button {
                    icon = font_icon,
                    text = app.name,
                    on_press = function(self)
                        app:spawn()
                    end
                },
                widgets.menu.checkbox_button {
                    state = tasklist_daemon:is_app_pinned{id = app.id},
                    handle_active_color = font_icon.color,
                    text = "Pin App",
                    on_press = function(self)
                        if tasklist_daemon:is_app_pinned{id = app.id} then
                            self:turn_off()
                            tasklist_daemon:remove_pinned_app{id = app.id}
                        else
                            self:turn_on()
                            tasklist_daemon:add_pinned_app{id = app.id}
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
                    on_press = function()
                        app.desktop_app_info:launch_action(action)
                    end
                })
            end

            local widget = wibox.widget {
                widget = widgets.button.elevated.state,
                id = "button",
                forced_width = dpi(120),
                forced_height = dpi(120),
                paddings = dpi(15),
                halign = "center",
                text = app.name,
                on_secondary_press = function()
                    menu:toggle()
                end,
                child = {
                    layout = wibox.layout.fixed.vertical,
                    spacing = dpi(15),
                    {
                        widget = wibox.container.place,
                        halign = "center",
                        valign = "center",
                        {
                            widget = widgets.text,
                            size = 40,
                            icon = font_icon
                        },
                    },
                    {
                        widget = wibox.container.place,
                        halign = "center",
                        valign = "center",
                        {
                            widget = widgets.text,
                            size = 12,
                            color = beautiful.colors.on_background,
                            text = app.name
                        }
                    }
                }
            }

            widget:connect_signal("selected", function()
                widget:turn_on()
            end)

            widget:connect_signal("unselected", function()
                widget:turn_off()
            end)

            return widget
        end
    }

    local animation = helpers.animation:new{
        pos = 1,
        easing = helpers.animation.easing.outExpo,
        duration = 0.5,
        update = function(_, pos)
            app_launcher._private.widget.widget.forced_height = pos
        end,
        signals = {
            ["ended"] = function()
                if app_launcher._private.state == false then
                    app_launcher._private.widget.visible = false
                    app_launcher._private.prompt:set_text("")
                end
            end
        }
    }

    function app_launcher:show()
        app_launcher._private.state = true
        app_launcher._private.widget.visible = true
        app_launcher._private.prompt:start()
        app_launcher:emit_signal("visibility", true)

        animation.easing = helpers.animation.easing.outExpo
        animation:set(dpi(500))
    end

    function app_launcher:hide()
        app_launcher._private.state = false
        app_launcher._private.prompt:stop()
        app_launcher:emit_signal("visibility", false)

        animation.easing = helpers.animation.easing.inExpo
        animation:set(1)
    end

    local pinned_apps = {}
    tasklist_daemon:connect_signal("pinned_app::added", function(self, pinned_app)
        table.insert(pinned_apps, pinned_app.desktop_app_info_id)
        app_launcher:set_favorites(pinned_apps)
    end)

    tasklist_daemon:connect_signal("pinned_app::removed", function(self, pinned_app)
        helpers.table.remove_value(pinned_apps, pinned_app.desktop_app_info_id)
        app_launcher:set_favorites(pinned_apps)
    end)

    capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
        app_launcher._private.widget.widget.bg = old_colorscheme_to_new_map[beautiful.colors.background]
    end)

    return app_launcher
end

if not instance then
    instance = new()
end
return instance
