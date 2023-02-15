-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gobject = require("gears.object")
local gtable = require("gears.table")
local gmatrix = require("gears.matrix")
local gshape = require("gears.shape")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("ui.widgets")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local collectgarbage = collectgarbage
local ipairs = ipairs
local capi = {
    client = client,
    tag = tag
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

        self.widget.x = args.coords.x
        self.widget.y = args.coords.y
    end

    local widget = wibox.widget {
        widget = wibox.container.constraint,
        mode = "max",
        width = dpi(300),
        height = dpi(200),
        {
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
                        halign = "center",
                        valign = "center",
                        client = c
                    },
                    {
                        widget = widgets.text,
                        forced_height = dpi(30),
                        halign = "center",
                        valign = "center",
                        size = 15,
                        text = c.name
                    }
                },
                widgets.client_thumbnail(c)
            }
        }
    }

    self.widget.widget = widget
    self.widget.visible = true
end

function task_preview:hide()
    self.widget.visible = false
    self.widget.widget = nil
    collectgarbage("collect")
end

function task_preview:toggle(c, args)
    if self.widget.visible == true then
        self:hide()
    else
        self:show(c, args)
    end
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, task_preview)

    ret.widget = widgets.popup {
        type = 'dropdown_menu',
        visible = false,
        ontop = true,
        bg = beautiful.colors.background,
        shape = function(cr, width, height)
            gshape.infobubble(cr, width, height, nil, nil, dpi(22))
        end,
        widget = wibox.container.background -- A dummy widget to make awful.popup not scream
    }

    capi.client.connect_signal("property::fullscreen", function(c)
        if c.fullscreen then
            ret:hide()
        end
    end)

    capi.client.connect_signal("focus", function(c)
        if c.fullscreen then
            ret:hide()
        end
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance
