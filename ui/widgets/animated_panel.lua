-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gtable = require("gears.table")
local wibox = require("wibox")
local pwidget = require("ui.widgets.popup")
local helpers = require("helpers")
local capi = {
    awesome = awesome,
    client = client
}

local animated_panel = {
    mt = {}
}

local function fake_widget(image)
    return wibox.widget {
        widget = wibox.widget.imagebox,
        image = image
    }
end

function animated_panel:show()
    self.state = true

    if self.max_height then
        self.screen = awful.screen.focused()
        self.minimum_height = awful.screen.focused().workarea.height
        self.maximum_height = awful.screen.focused().workarea.height
    end

    self.placement = nil

    local image = wibox.widget.draw_to_image_surface(self.widget, self.width, self.height)
    self.widget = fake_widget(image)

    if self.actual_pos == nil then
        self.actual_pos = self[self.axis]
    end

    self.animation.easing = helpers.animation.easing.outExpo
    self.animation:set(self.actual_pos)
    self.visible = true
    self:emit_signal("visibility", true)
end

function animated_panel:hide()
    if self.state == false then
        return
    end

    self.state = false

    local image = wibox.widget.draw_to_image_surface(self.widget, self.width, self.height)
    self.widget = fake_widget(image)
    self.animation.easing = helpers.animation.easing.inExpo
    self.animation:set(self.start_pos)
    self:emit_signal("visibility", false)
end

function animated_panel:toggle()
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
    gtable.crush(ret, animated_panel, true)
    ret.axis = args.axis or "x"
    ret.start_pos = args.start_pos or 4000
    ret.max_height = args.max_height

    ret.state = false
    ret.animation = helpers.animation:new{
        pos = ret.start_pos,
        easing = helpers.animation.easing.outExpo,
        duration = 0.8,
        update = function(_, pos)
            ret[ret.axis] = pos
        end,
        signals = {
            ["ended"] = function()
                if ret.state == true then
                    ret.widget = args.widget
                else
                    ret.visible = false
                end
            end
        }
    }

    capi.awesome.connect_signal("root::pressed", function()
        ret:hide()
    end)

    capi.client.connect_signal("button::press", function()
        ret:hide()
    end)

    return ret
end

function animated_panel.mt:__call(...)
    return new(...)
end

return setmetatable(animated_panel, animated_panel.mt)