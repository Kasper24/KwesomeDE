-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gshape = require("gears.shape")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

local info_panel = { }
local instance = nil

local path = ...

function info_panel:show()
    self.widget.screen = awful.screen.focused()
    self.widget.visible = true
    self:emit_signal("visibility", true)
end

function info_panel:hide()
    self.widget.visible = false
    self:emit_signal("visibility", false)
end

function info_panel:toggle()
    if self.widget.visible == false then
        self:show()
    else
        self:hide()
    end
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, info_panel, true)

    ret.widget = awful.popup
    {
        type = "dock",
        visible = false,
        ontop = true,
        minimum_width = dpi(800),
        maximum_width = dpi(800),
        minimum_height = dpi(600),
        maximum_height = dpi(600),
        placement = function(widget)
            awful.placement.top(widget,
            {
                honor_workarea = true,
                honor_padding = true,
                attach = true
            })
        end,
        shape = gshape.infobubble,
        bg = beautiful.colors.background,
        widget =
        {
            widget = wibox.container.margin,
            margins = dpi(25),
            {
                layout = wibox.layout.flex.horizontal,
                spacing = dpi(15),
                require(path .. ".calendar"),
                require(path .. ".weather")
            }
        }
    }

    return ret
end

if not instance then
    instance = new()
end
return instance