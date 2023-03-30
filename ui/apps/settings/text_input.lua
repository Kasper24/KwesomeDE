-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local text_input = {
    mt = {}
}

local function new(args)
    args = args or {}

    local widget = wibox.widget {
        widget = widgets.text_input,
        unfocus_on_client_clicked = false,
        initial = args.initial or "",
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
                        color = beautiful.icons.computer.color,
                        icon = args.icon
                    },
                    {
                        layout = wibox.layout.stack,
                        {
                            widget = wibox.widget.textbox,
                            id = "placeholder_role",
                            text = args.placeholder,
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

    SETTINGS_APP:connect_signal("tab::select", function()
        widget:unfocus()
    end)

    SETTINGS_APP:get_client():connect_signal("request::unmanage", function()
        widget:unfocus()
    end)

    SETTINGS_APP:get_client():connect_signal("mouse::leave", function()
        widget:unfocus()
    end)

    SETTINGS_APP:get_client():connect_signal("unfocus", function()
        widget:unfocus()
    end)

    return widget
end

function text_input.mt:__call(args)
    return new(args)
end

return setmetatable(text_input, text_input.mt)