-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("ui.widgets")
local bling = require("external.bling")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local capi = {
    awesome = awesome
}

local instance = nil

local function fake_widget(image)
    return wibox.widget {
        widget = wibox.widget.imagebox,
        forced_width = dpi(800),
        forced_height = dpi(300),
        image = image
    }
end

local function new()
    local app_on_accent_color = beautiful.colors.random_accent_color()



    local app_launcher = bling.widget.app_launcher {
        bg = beautiful.colors.background,
        widget_template = wibox.widget {
            layout = wibox.layout.fixed.horizontal,
            {
                layout = wibox.layout.stack,
                {
                    widget = widgets.wallpaper,
                    forced_width = dpi(800),
                    forced_height = dpi(300),
                },
                {
                    widget = wibox.container.margin,
                    margins = dpi(15),
                    {
                        widget = wibox.container.place,
                        halign = "left",
                        valign = "top",
                        {
                            widget = widgets.background,
                            forced_width = dpi(750),
                            forced_height = dpi(60),
                            shape = helpers.ui.rrect(),
                            bg = beautiful.colors.background,
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
                    }
                }
            },
            {
                widget = wibox.container.margin,
                margins = dpi(15),
                {
                    layout = wibox.layout.grid,
                    id = "grid_role",
                    orientation = "horizontal",
                    homogeneous = true,
                    spacing = dpi(15),
                    forced_num_cols = 1,
                    forced_num_rows = 7,
                }
            }
        },

        app_template = function(app)
            local widget = wibox.widget {
                widget = widgets.button.elevated.state,
                id = "button",
                forced_width = dpi(500),
                forced_height = dpi(60),
                paddings = dpi(15),
                halign = "left",
                text = app.name,
                child = {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = dpi(15),
                    {
                        widget = widgets.text,
                        icon = helpers.client.get_font_icon(app.id, app.name, app.startup_wm_class, app.icon, app.icon_name)
                    },
                    {
                        widget = widgets.text,
                        size = 12,
                        color = beautiful.colors.on_background,
                        text = app.name
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
            app_launcher._private.widget.widget.forced_width = pos
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
        animation:set(dpi(1300))
    end

    function app_launcher:hide()
        app_launcher._private.state = false
        app_launcher._private.prompt:stop()
        app_launcher:emit_signal("visibility", false)

        animation.easing = helpers.animation.easing.inExpo
        animation:set(1)
    end

    capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
        app_launcher._private.widget.widget.bg = old_colorscheme_to_new_map[beautiful.colors.background]
    end)

    return app_launcher
end

if not instance then
    instance = new()
end
return instance
