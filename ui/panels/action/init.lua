-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local capi = {
    screen = screen
}

local action_panel = {}
local instance = nil

local path = ...
local header = require(path .. ".header")
local dashboard = require(path .. ".dashboard")
local info = require(path .. ".info")
local media = require(path .. ".media")

local function separator()
    return wibox.widget {
        widget = wibox.widget.separator,
        forced_width = dpi(1),
        forced_height = dpi(1),
        shape = helpers.ui.rrect(beautiful.border_radius),
        orientation = "horizontal",
        color = beautiful.colors.surface
    }
end

local function widget(self)
    return wibox.widget {
        widget = wibox.container.margin,
        margins = dpi(25),
        {
            layout = widgets.overflow.vertical,
            spacing = dpi(30),
            scrollbar_widget = {
                widget = wibox.widget.separator,
                shape = helpers.ui.rrect(beautiful.border_radius)
            },
            scrollbar_width = dpi(10),
            step = 50,
            header,
            separator(),
            dashboard(self),
            separator(),
            info(self),
            separator(),
            media
        }
    }
end

local function fake_widget(image)
    return wibox.widget {
        widget = wibox.widget.imagebox,
        image = image
    }
end

function action_panel:show()
    self.state = true

    self.widget.screen = awful.screen.focused()
    self.widget.minimum_height = awful.screen.focused().workarea.height
    self.widget.maximum_height = awful.screen.focused().workarea.height

    local image = wibox.widget.draw_to_image_surface(self.widget.widget, self.widget.width, self.widget.height)
    self.widget.widget = fake_widget(image)
    self.animation.easing = helpers.animation.easing.outExpo
    self.widget.visible = true
    if self.actual_x == nil then
        self.actual_x = self.widget.x
    end
    self.animation:set(self.actual_x)
    self:emit_signal("visibility", true)
end

function action_panel:hide()
    if self.state == false then
        return
    end

    self.state = false

    local image = wibox.widget.draw_to_image_surface(self.widget.widget, self.widget.width, self.widget.height)
    self.widget.widget = fake_widget(image)
    self.animation.easing = helpers.animation.easing.inExpo
    self.animation:set(4000)
    self:emit_signal("visibility", false)
end

function action_panel:toggle()
    if self.animation.state == true then
        return
    end

    if self.widget.visible == false then
        self:show()
    else
        self:hide()
    end
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, action_panel, true)

    ret.state = false

    ret.real_widget = widget(ret)
    ret.widget = widgets.popup {
        type = "dock",
        visible = false,
        ontop = true,
        minimum_width = dpi(550),
        maximum_width = dpi(550),
        minimum_height = capi.screen.primary.workarea.height,
        maximum_height = capi.screen.primary.workarea.height,
        placement = function(widget)
            awful.placement.top_right(widget, {
                honor_workarea = true,
                honor_padding = true,
                attach = true
            })
        end,
        shape = helpers.ui.rrect(beautiful.border_radius),
        bg = beautiful.colors.background,
        widget = ret.real_widget
    }

    ret.animation = helpers.animation:new{
        pos = 4000,
        easing = helpers.animation.easing.outExpo,
        duration = 0.8,
        update = function(_, pos)
            ret.widget.x = pos
        end,
        signals = {
            ["ended"] = function()
                if ret.state == true then
                    ret.widget.widget = ret.real_widget
                else
                    ret.widget.visible = false
                end
            end
        }
    }

    return ret
end

if not instance then
    instance = new()
end
return instance
