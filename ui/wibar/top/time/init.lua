-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local info_panel = require("ui.panels.info")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local capi = {
    awesome = awesome
}

local time = {
    mt = {}
}

local function new()
    local clock = wibox.widget {
        widget = wibox.widget.textclock,
        format = "%d %b %H:%M",
        align = "center",
        valign = "center",
        font = beautiful.font_name .. dpi(14)
    }

    clock.markup = helpers.ui.colorize_text(clock.text, beautiful.icons.envelope.color)
    clock:connect_signal("widget::redraw_needed", function()
        clock.markup = helpers.ui.colorize_text(clock.text, beautiful.icons.envelope.color)
    end)

    capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
        clock:emit_signal("widget::redraw_needed")
    end)

    local widget = wibox.widget {
        widget = wibox.container.margin,
        margins = dpi(5),
        {
            widget = widgets.button.elevated.state,
            id = "button",
            on_release = function()
                info_panel:toggle()
            end,
            clock
        }
    }

    info_panel:connect_signal("visibility", function(self, visibility)
        if visibility == true then
            widget:get_children_by_id("button")[1]:turn_on()
        else
            widget:get_children_by_id("button")[1]:turn_off()
        end
    end)

    return widget
end

function time.mt:__call()
    return new()
end

return setmetatable(time, time.mt)