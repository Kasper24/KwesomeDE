-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local tab_button = {
    mt = {}
}

local function new(navigator, id, icon, title)
    return wibox.widget {
        widget = widgets.button.elevated.state,
        halign = "left",
        on_normal_bg = beautiful.icons.computer.color,
        on_release = function()
            navigator:emit_signal("tab::select", id)
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

function tab_button.mt:__call(navigator, id, icon, title)
    return new(navigator, id, icon, title)
end

return setmetatable(tab_button, tab_button.mt)