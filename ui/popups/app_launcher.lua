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

local function new()
    local app_on_accent_color = beautiful.colors.random_accent_color()

    local app_launcher = bling.widget.app_launcher {
        widget_template = wibox.widget {
            layout = wibox.layout.fixed.horizontal,
            {
                layout = wibox.layout.stack,
                {
                    widget = widgets.wallpaper,
                    forced_width = dpi(600),
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
                            forced_width = dpi(550),
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
                                    reset_on_stop = true,
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
            local button = wibox.widget {
                widget = widgets.button.text.state,
                forced_width = dpi(400),
                forced_height = dpi(60),
                paddings = dpi(15),
                halign = "left",
                size = 12,
                on_normal_bg = app_on_accent_color,
                text_normal_bg = beautiful.colors.on_background,
                text_on_normal_bg = beautiful.colors.on_accent,
                text = app.name
            }

            button:connect_signal("selected", function()
                button:turn_on()
            end)

            button:connect_signal("unselected", function()
                button:turn_off()
            end)

            return button
        end
    }

    local animation = helpers.animation:new{
        pos = 1,
        easing = helpers.animation.easing.outExpo,
        duration = 0.8,
        update = function(_, pos)
            app_launcher._private.widget.widget.forced_width = dpi(pos)
        end,
        signals = {
            ["ended"] = function()
                if app_launcher._private.state == false then
                    app_launcher._private.widget.visible = false
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
        animation:set(dpi(1000))
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
