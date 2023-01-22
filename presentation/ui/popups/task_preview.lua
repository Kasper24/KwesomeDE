-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gmatrix = require("gears.matrix")
local gshape = require("gears.shape")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("presentation.ui.widgets")
local dpi = beautiful.xresources.apply_dpi
local collectgarbage = collectgarbage
local ipairs = ipairs
local capi = { client = client, tag = tag }

local task_preview  = { }
local instance = nil

local function _get_widget_geometry(_hierarchy, widget)
    local width, height = _hierarchy:get_size()
    if _hierarchy:get_widget() == widget then
        -- Get the extents of this widget in the device space
        local x, y, w, h = gmatrix.transform_rectangle(
            _hierarchy:get_matrix_to_device(),
            0, 0, width, height)
        return { x = x, y = y, width = w, height = h, hierarchy = _hierarchy }
    end

    for _, child in ipairs(_hierarchy:get_children()) do
        local ret = _get_widget_geometry(child, widget)
        if ret then return ret end
    end
end

local function get_widget_geometry(wibox, widget)
    return _get_widget_geometry(wibox._drawable._widget_hierarchy, widget)
end

local function get_client_content_as_imagebox(c)
    local ss = awful.screenshot {
        client = c,
    }

    ss:refresh()
    local ib = ss.content_widget
    ib.valign = "center"
    ib.halign = "center"
    ib.horizontal_fit_policy = "fit"
    ib.vertical_fit_policy = "fit"
    ib.resize = true

    return ib
end

function task_preview:show(c, args)
    args = args or {}

    args.coords = args.coords or self.coords
    args.wibox = args.wibox
    args.widget = args.widget
    args.offset = args.offset or {}

    if not args.coords and args.wibox and args.widget then
        args.coords = get_widget_geometry(args.wibox, args.widget)
        if args.offset.x ~= nil then
            args.coords.x = args.coords.x + args.offset.x
        end
        if args.offset.y ~= nil then
            args.coords.y = args.coords.y + args.offset.y
        end

        self._private.widget.x = args.coords.x
        self._private.widget.y = args.coords.y
    end

    local font_icon = beautiful.get_font_icon_for_app_name(c.class)

    local widget = wibox.widget
    {
        widget = wibox.container.constraint,
        mode = "max",
        width = dpi(300),
        height = dpi(150),
        {
            widget = wibox.container.background,
            bg = beautiful.colors.background,
            {
                widget = wibox.container.margin,
                margins = dpi(15),
                {
                    layout = wibox.layout.fixed.vertical,
                    spacing = dpi(15),
                    {
                        layout = wibox.layout.fixed.horizontal,
                        spacing = dpi(10),
                        {
                            widget = widgets.text,
                            halign = "center",
                            valign ="center",
                            color = beautiful.random_accent_color(),
                            font = font_icon.font,
                            text = font_icon.icon
                        },
                        {
                            widget = widgets.text,
                            forced_height = dpi(30),
                            halign = "center",
                            valign = "center",
                            size = 15,
                            text = c.name
                        },
                    },
                    widgets.client_thumbnail(c)
                }
            }
        }
    }

    self._private.widget.widget = widget
    self._private.widget.visible = true
end

function task_preview:hide()
    self._private.widget.visible = false
    self._private.widget.widget = nil
    collectgarbage("collect")
end

function task_preview:toggle(c, args)
    if self._private.widget.visible == true then
        self:hide()
    else
        self:show(c, args)
    end
end

local function new(args)
    args = args or {}

    local ret = gobject{}
    ret._private = {}

    gtable.crush(ret, task_preview)
    gtable.crush(ret, args)

    ret._private.widget = awful.popup
    {
        type = 'dropdown_menu',
        visible = false,
        ontop = true,
        bg = "#00000000",
        shape = function(cr, width, height)
            gshape.infobubble(cr, width, height, nil, nil, dpi(27))
        end,
        widget = wibox.container.background, -- A dummy widget to make awful.popup not scream
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