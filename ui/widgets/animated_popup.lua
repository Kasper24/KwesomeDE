-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gtable = require("gears.table")
local wibox = require("wibox")
local pwidget = require("ui.widgets.popup")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi

local animated_popup = {
    mt = {}
}

function animated_popup:show(value, reshow)
    if self.state == true and reshow ~= true then
        return
    end
    self.state = true

    self.animation.pos = 1
    self.animation.easing = helpers.animation.easing.outExpo
    if self.method == "forced_height" then
        self.animation:set(value or self.maximum_height)
    else
        self.animation:set(value or self.maximum_width)
    end
    self.visible = true
    self:emit_signal("visibility", true)
end

function animated_popup:hide()
    if self.state == false then
        return
    end
    self.state = false

    self.animation.easing = helpers.animation.easing.inExpo
    self.animation:set(1)
    self:emit_signal("visibility", false)
end

function animated_popup:toggle()
    if self.animation.state == true then
        return
    end
    if self.visible == false then
        self:show()
    else
        self:hide()
    end
end

local function new(args)
    args = args or {}

    local ret = pwidget(args)
    gtable.crush(ret, animated_popup, true)

    ret.method = "forced_" .. (args.animate_method or "height")

    ret.state = false
    ret.animation = helpers.animation:new{
        pos = 1,
        easing = helpers.animation.easing.outExpo,
        duration = 0.8,
        update = function(_, pos)
            ret.widget[ret.method] = dpi(pos)
        end,
        signals = {
            ["ended"] = function()
                if ret.state == false then
                    ret.visible = false
                end
            end
        }
    }

    return ret
end

function animated_popup.mt:__call(...)
    return new(...)
end

return setmetatable(animated_popup, animated_popup.mt)