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

local function new(icon, placeholder, initial)
    return wibox.widget {
        widget = widgets.text_input,
        unfocus_keys = { },
        unfocus_on_client_clicked = false,
        initial = initial or "",
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
                        icon = icon
                    },
                    {
                        layout = wibox.layout.stack,
                        {
                            widget = wibox.widget.textbox,
                            id = "placeholder_role",
                            text = placeholder,
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
end

function text_input.mt:__call(icon, placeholder, initial)
    return new(icon, placeholder, initial)
end

return setmetatable(text_input, text_input.mt)