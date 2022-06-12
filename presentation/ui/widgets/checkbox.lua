-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local gtable = require("gears.table")
local wbuttontext = require("presentation.ui.widgets.button.text")
local beautiful = require("beautiful")
local setmetatable = setmetatable

local checkbox = { mt = {} }

function checkbox:get_value()
    return self._private.state
end

local function new(args)
    args = args or {}

    args.animate_size = false
    args.font = beautiful.toggle_on_icon.font
    args.text = beautiful.toggle_off_icon.icon
    args.on_normal_bg = "#00000000"

    local on_turn_on = args.on_turn_on
    args.on_turn_on = function(self)
        self:set_text(beautiful.toggle_on_icon.icon)
        if on_turn_on ~= nil then
            on_turn_on()
        end
    end

    local on_turn_off = args.on_turn_off
    args.on_turn_off = function(self)
        self:set_text(beautiful.toggle_off_icon.icon)
        if on_turn_off ~= nil then
            on_turn_off()
        end
    end

    local widget = wbuttontext.state(args)
    gtable.crush(widget, checkbox)

	if args.on_by_default == true then
        widget:set_text(beautiful.toggle_on_icon.icon)
	end

    return widget
end

function checkbox.mt:__call(...)
    return new(...)
end

return setmetatable(checkbox, checkbox.mt)