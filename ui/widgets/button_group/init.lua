-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local gtable = require("gears.table")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local button_group = {
    mt = {}
}

function button_group:select(id)
    for _, value in ipairs(self._private.values) do
        if value.id == id then
            value.button:turn_on()
            if self._private.on_select then
                self._private.on_select(id)
            end
            self:emit_signal("select", id)
        else
            value.button:turn_off()
        end
    end
end

function button_group:set_values(values)
    self._private.values = values

    for _, value in ipairs(values) do
        value.button:set_on_release(function()
            self:select(value.id)
        end)
        self._private.buttons_layout:add(value.button)
    end

    self:select(self._private.values[1].id)
end

function button_group:get_values()
    return self._private.values
end

function button_group:set_widget_template(widget_template)
    self:set_widget(widget_template)
    self._private.buttons_layout = widget_template:get_children_by_id("buttons_layout")[1]
end

function button_group:set_on_select(on_select)
    self._private.on_select = on_select
end

local function new()
    local widget = wibox.container.background()
    gtable.crush(widget, button_group, true)

    return widget
end

function button_group.horizontal()
    local widget = new()
    widget:set_widget_template(wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        id = "buttons_layout",
        spacing = dpi(15),
    })
    return widget
end

function button_group.vertical()
    local widget = new()
    widget:set_widget_template(wibox.widget {
        layout = wibox.layout.fixed.vertical,
        id = "buttons_layout",
        spacing = dpi(15),
    })
    return widget
end

function button_group.mt:__call()
    return new()
end

return setmetatable(button_group, button_group.mt)
