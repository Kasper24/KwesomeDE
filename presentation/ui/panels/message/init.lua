-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local wibox = require("wibox")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local capi = { screen = screen }

local message_panel = { }
local instance = nil

local path = ...

local function separator()
    return wibox.widget
    {
        widget = wibox.widget.separator,
        forced_width = dpi(1),
        forced_height = dpi(1),
        shape = helpers.ui.rrect(beautiful.border_radius),
        orientation = "horizontal",
        color = beautiful.colors.surface
    }
end

function message_panel:show()
    self.widget.screen = awful.screen.focused()
    self.widget.minimum_height = awful.screen.focused().workarea.height
    self.widget.maximum_height = awful.screen.focused().workarea.height
    self.widget.visible = true
    self:emit_signal("visibility", true)
end

function message_panel:hide()
    self.widget.visible = false
    self:emit_signal("visibility", false)
end

function message_panel:toggle()
    if self.widget.visible == false then
        self:show()
    else
        self:hide()
    end
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, message_panel, true)

    ret.widget = awful.popup
    {
        type = "dock",
        visible = false,
        ontop = true,
        minimum_width = dpi(550),
        maximum_width = dpi(550),
        minimum_height = capi.screen.primary.workarea.height,
        maximum_height = capi.screen.primary.workarea.height,
        placement = function(widget)
            awful.placement.top_right(widget,
            {
                honor_workarea = true,
                honor_padding = true,
                attach = true
            })
        end,
        shape = helpers.ui.rrect(beautiful.border_radius),
        bg = beautiful.colors.background,
        widget =
        {
            widget = wibox.container.margin,
            margins = dpi(25),
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(30),
                require(path .. ".notifications"),
                separator(),
                require(path .. ".email_github_gitlab")
            }
        }
    }

    return ret
end

if not instance then
    instance = new()
end
return instance