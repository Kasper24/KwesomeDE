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

function action_panel:show()
    self.state = true

    self.widget.screen = awful.screen.focused()
    self.widget.minimum_height = awful.screen.focused().workarea.height
    self.widget.maximum_height = awful.screen.focused().workarea.height

    self.fake_widget.visible = true
    self.fake_widget.y = self.widget.y
    self.fake_widget.widget.image = wibox.widget.draw_to_image_surface(self.widget.widget, self.widget.width, self.widget.height)
    self.animation.easing = helpers.animation.easing.outExpo
    self.animation:set(self.widget.x)
    self:emit_signal("visibility", true)
end

function action_panel:hide()
    self.state = false

    self.fake_widget.widget.image = wibox.widget.draw_to_image_surface(self.widget.widget, self.widget.width, self.widget.height)
    self.animation.easing = helpers.animation.easing.inExpo
    self.animation:set(4000)

    self.fake_widget.visible = true
    self.widget.visible = false
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
        widget = {
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
                dashboard(ret),
                separator(),
                info(ret),
                separator(),
                media
            }
        }
    }

    ret.fake_widget = widgets.popup {
        type = "dock",
        visible = false,
        ontop = true,
        minimum_width = dpi(550),
        maximum_width = dpi(550),
        minimum_height = capi.screen.primary.workarea.height,
        maximum_height = capi.screen.primary.workarea.height,
        widget = wibox.widget.imagebox,
    }

    ret.animation = helpers.animation:new{
        pos = 4000,
        easing = helpers.animation.easing.outExpo,
        duration = 0.8,
        update = function(_, pos)
            ret.fake_widget.x = pos
        end,
        signals = {
            ["ended"] = function()
                if ret.state == true then
                    print("1")
                    ret.widget.visible = true
                else
                    print("2")
                    ret.widget.visible = false
                end

                require("gears.timer") {
                    timeout = 3,
                    single_shot = true,
                    call_now = false,
                    autostart = true,
                    callback = function()
                        ret.fake_widget.visible = false
                    end
                }
            end
        }
    }

    return ret
end

if not instance then
    instance = new()
end
return instance
