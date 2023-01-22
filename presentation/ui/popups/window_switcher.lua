-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("presentation.ui.widgets")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local ipairs = ipairs
local capi = { client = client }

local window_switcher  = { }
local instance = nil

local function focus_client(client)
    if not client:isvisible() and client.first_tag then
        client.first_tag:view_only()
    end

    client:emit_signal('request::activate')
    client:raise()
    -- client.minimized = false
end

local function client_widget(self, client)
    local font_icon = beautiful.get_font_icon_for_app_name(client.class)
    local is_selected = client == self._private.clients[self._private.selected_index]

    return wibox.widget
    {
        widget = wibox.container.constraint,
        mode = "max",
        width = dpi(300),
        height = dpi(150),
        {
            widget = wibox.container.background,
            shape = helpers.ui.rrect(beautiful.border_radius),
            border_width = dpi(5),
            border_color = (is_selected) and beautiful.random_accent_color() or beautiful.colors.surface,
            {
                widget = wibox.layout.stack,
                {
                    widget = wibox.container.background,
                    shape = helpers.ui.rrect(beautiful.border_radius),
                    bg = beautiful.colors.background,
                },
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
                                text = client.name
                            }
                        },
                        widgets.client_thumbnail(client)
                    }
                }
            }
        }
    }
end

local function clients_widget(self)
    local clients_layout = wibox.widget
    {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15)
    }

    for _, client in ipairs(self._private.clients) do
        clients_layout:add(client_widget(self, client))
    end

    return wibox.widget
    {
        widget = wibox.container.background,
        shape = helpers.ui.rrect(beautiful.border_radius),
        bg = beautiful.colors.background .. "C8",
        {
            widget = wibox.container.margin,
            margins = dpi(15),
            clients_layout
        }
    }
end

function window_switcher:cycle_clients(increase)
    self._private.selected_index = self._private.selected_index + (increase and 1 or -1)
    if self._private.selected_index > #self._private.clients then
        self._private.selected_index = 1
    elseif self._private.selected_index < 1 then
        self._private.selected_index = #self._private.clients
    end

    self._private.widget.widget = clients_widget(self)
end

function window_switcher:show()
    if #capi.client.get() == 0 then
        return
    end

    self._private.clients = capi.client.get()

    self._private.widget.widget = clients_widget(self)
    self._private.widget.visible = true
end

function window_switcher:hide()
    focus_client(self._private.clients[self._private.selected_index])

    self._private.widget.visible = false
    self._private.widget.widget = nil

    collectgarbage("collect")
end

function window_switcher:toggle()
    if self._private.widget.visible == true then
        self:hide()
    else
        self:show()
    end
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, window_switcher)

    ret._private = {}
    ret._private.selected_index = 1
    ret._private.clients = {}

    ret._private.widget = awful.popup
    {
        type = 'dropdown_menu',
        placement = awful.placement.centered,
        visible = false,
        ontop = true,
        bg = "#00000000",
        widget = wibox.container.background, -- A dummy widget to make awful.popup not scream
    }

    ret._private.widget:connect_signal("property::width", function()
        if ret._private.widget.visible and #capi.client.get() == 0 then
            ret:hide()
        end
    end)

    ret._private.widget:connect_signal("property::height", function()
        if ret._private.widget.visible and #capi.client.get() == 0 then
            ret:hide()
        end
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance