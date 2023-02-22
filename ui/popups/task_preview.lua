-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gtable = require("gears.table")
local gshape = require("gears.shape")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("ui.widgets")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local capi = {
    client = client,
}

local task_preview = {}
local instance = nil

function task_preview:show(c, args)
    args = args or {}

    args.coords = args.coords or self.coords
    args.wibox = args.wibox
    args.widget = args.widget
    args.offset = args.offset or {}

    if not args.coords and args.wibox and args.widget then
        args.coords = helpers.ui.get_widget_geometry(args.wibox, args.widget)
        if args.offset.x ~= nil then
            args.coords.x = args.coords.x + args.offset.x
        end
        if args.offset.y ~= nil then
            args.coords.y = args.coords.y + args.offset.y
        end

        self.x = args.coords.x
        self.y = args.coords.y
    end

    self.widget:get_children_by_id("font_icon")[1]:set_client(c)
    self.widget:get_children_by_id("name")[1]:set_text(c.name)
    self.widget:get_children_by_id("thumbnail")[1]:set_client(c)

    self.visible = true
end

function task_preview:hide()
    self.visible = false
end

function task_preview:toggle(c, args)
    if self.visible == true then
        self:hide()
    else
        self:show(c, args)
    end
end

local function new()
    local widget = widgets.popup {
        visible = false,
        ontop = true,
        shape = function(cr, width, height)
            gshape.infobubble(cr, width, height, nil, nil, dpi(22))
        end,
        bg = beautiful.colors.background,
        minimum_width = dpi(300),
        maximum_width = dpi(300),
        maximum_height = dpi(200),
        widget = wibox.widget {
            widget = wibox.container.margin,
            margins = dpi(15),
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(15),
                {
                    layout = wibox.layout.fixed.horizontal,
                    forced_height = dpi(30),
                    spacing = dpi(10),
                    {
                        widget = widgets.client_font_icon,
                        id = "font_icon",
                        halign = "center",
                        valign = "center",
                    },
                    {
                        widget = widgets.text,
                        id = "name",
                        forced_height = dpi(30),
                        halign = "center",
                        valign = "center",
                        size = 15,
                    }
                },
                {
                    widget = widgets.client_thumbnail,
                    id = "thumbnail"
                }
            }
        }
    }

    gtable.crush(widget, task_preview, true)

    capi.client.connect_signal("property::fullscreen", function(c)
        if c.fullscreen then
            widget:hide()
        end
    end)

    capi.client.connect_signal("focus", function(c)
        if c.fullscreen then
            widget:hide()
        end
    end)

    return widget
end

if not instance then
    instance = new()
end
return instance
