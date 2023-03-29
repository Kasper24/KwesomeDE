-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gshape = require("gears.shape")
local gtable = require("gears.table")
local wibox = require("wibox")
local twidget = require("ui.widgets.text")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable
local capi = {
    root = root,
    mouse = mouse
}

local radio_group = {
    mt = {}
}

function radio_group:set_buttons(buttons)
    self._private.buttons = buttons

    for index, button in ipairs(buttons) do
        if index == 1 then
            local checkbox = button:get_children_by_id("checkbox")[1]
            checkbox.checked = true
        end

        button.radio_group = self
        self._private.buttons_layout:add(button)
    end
end

function radio_group:get_buttons()
    return self._private.buttons
end

function radio_group:set_widget_template(widget_template)
    self:set_widget(widget_template)
    self._private.buttons_layout = widget_template:get_children_by_id("buttons")[1]
end

local function new()
    local widget = wibox.container.background()
    gtable.crush(widget, radio_group, true)

    widget:connect_signal("button::select", function(self, id)
        for _, button in ipairs(self._private.buttons) do
            local checkbox = button:get_children_by_id("checkbox")[1]
            if button.id == id then
                checkbox.checked = true
            else
                checkbox.checked = false
            end
        end
    end)

    return widget
end

function radio_group.button(id, label, color, check_color)
   local widget = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15),
        {
            widget = wibox.widget.checkbox,
            id = "checkbox",
            forced_width = dpi(25),
            forced_height = dpi(25),
            shape = gshape.circle,
            color = color,
            check_color = check_color,
            paddings = dpi(2),
        },
        {
            widget = twidget,
            size = 15,
            text = label,
            color = beautiful.colors.on_background
        }
    }

    local checkbox = widget:get_children_by_id("checkbox")[1]
    checkbox:connect_signal("mouse::enter", function()
        capi.root.cursor("hand2")
        local wibox = capi.mouse.current_wibox
        if wibox then
            wibox.cursor = "hand2"
        end
    end)

    checkbox:connect_signal("mouse::leave", function()
        capi.root.cursor("left_ptr")
        local wibox = capi.mouse.current_wibox
        if wibox then
            wibox.cursor = "left_ptr"
        end
    end)

    checkbox:connect_signal("button::press", function(_, lx, ly, button, mods, find_widgets_result)
        if button == 1 then
            widget.radio_group:emit_signal("button::select", id)
        end
    end)

    return widget
end

function radio_group.horizontal()
    local widget = new()
    widget:set_widget_template(wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        id = "buttons",
        spacing = dpi(15),
    })
    return widget
end

function radio_group.vertical()
    local widget = new()
    widget:set_widget_template(wibox.widget {
        layout = wibox.layout.fixed.vertical,
        id = "buttons",
        spacing = dpi(15),
    })
    return widget
end

function radio_group.mt:__call()
    return new()
end

return setmetatable(radio_group, radio_group.mt)
