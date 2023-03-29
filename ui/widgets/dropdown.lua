-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gtable = require("gears.table")
local wibox = require("wibox")
local wmenu = require("ui.widgets.menu")
local tbwidget = require("ui.widgets.button.text")
local beautiful = require("beautiful")
local setmetatable = setmetatable
local pairs = pairs

local dropdown = {
    mt = {}
}

function dropdown:reset(index)
    self.menu:reset(index)
end

function dropdown:remove(index)
    self.menu:remove(index)
end

function dropdown:add(key, value)
    return self.menu:add(wmenu.button {
        text = key,
        on_release = function()
            self.on_value_selected(value)
            self:set_text(self.label .. key)
        end
    })
end

function dropdown:select(key, value)
    self.on_value_selected(value)
    self:set_text(self.label .. key)
end

function dropdown:get_value()
    return self:get_text():gsub(self.label, "")
end

local function new(args)
    args = args or {}

    args.menu_width = args.menu_width or nil
    args.label = args.label or ""
    args.initial_value = args.initial_value or ""
    args.values = args.values or {}
    args.on_value_selected = args.on_value_selected or nil

    local dropdown_button = nil

    local menu = wmenu({}, args.menu_width, false)

    dropdown_button = wibox.widget {
        widget = tbwidget.state,
        halign = "left",
        size = 12,
        text = args.label .. args.initial_value,
        text_normal_bg = beautiful.colors.on_background,
        on_release = function()
            menu:toggle()
        end
    }

    gtable.crush(dropdown_button, dropdown)
    gtable.crush(dropdown_button, args)

    for key, value in pairs(args.values) do
        menu:add(wmenu.button {
            text = key,
            on_release = function()
                args.on_value_selected(value)
                dropdown_button:set_text(args.label .. key)
            end
        })
    end

    dropdown_button.menu = menu

    return dropdown_button
end

function dropdown.mt:__call(...)
    return new(...)
end

return setmetatable(dropdown, dropdown.mt)
