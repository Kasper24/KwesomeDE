-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gtable = require("gears.table")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("ui.widgets")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local ipairs = ipairs
local capi = {
    client = client
}

local window_switcher = {}
local instance = nil

local function focus_client(client)
    local is_valid = pcall(function()
        return client.valid
    end) and client.valid
    if client == nil or not is_valid then
        return
    end

    if not client:isvisible() and client.first_tag then
        client.first_tag:view_only()
    end

    client:emit_signal("request::activate")
    client:raise()
    client.minimized = false
end

local function client_widget(self, client)
    if client == nil then
        return
    end

    local is_selected = client == self._private.selected_client

    local widget = wibox.widget {
        widget = wibox.container.constraint,
        mode = "max",
        width = dpi(300),
        height = dpi(200),
        {
            widget = widgets.button.elevated.state,
            id = "button",
            on_by_default = is_selected,
            normal_bg = beautiful.colors.background,
            normal_border_width = dpi(5),
            normal_border_color = beautiful.colors.surface,
            on_normal_border_color = client.font_icon.color,
            on_release = function()
                self:select_client(client)
            end,
            child = {
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
                            client = client
                        },
                        {
                            widget = widgets.text,
                            halign = "center",
                            valign = "center",
                            size = 15,
                            text = client.name
                        }
                    },
                    {
                        widget = widgets.client_thumbnail,
                        client = client
                    }
                }
            }
        }
    }

    client.window_switcher_widget = widget

    return widget
end

function window_switcher:select_client(client)
    self._private.selected_client.window_switcher_widget:get_children_by_id("button")[1]:turn_off()
    client.window_switcher_widget:get_children_by_id("button")[1]:turn_on()
    self._private.selected_client = client
end

function window_switcher:cycle_clients(increase)
    local client = gtable.cycle_value(self._private.sorted_clients, self._private.selected_client, (increase and 1 or -1))
    self:select_client(client)
end

function window_switcher:show(set_selected_client)
    if #capi.client.get() == 0 then
        self:hide(false)
        return
    end

    if set_selected_client == true or set_selected_client == nil then
        self._private.selected_client = capi.client.focus
    end

    self._private.sorted_clients = helpers.client.get_sorted_clients()
    local clients_layout = self.widget:get_children_by_id("clients")[1]
    clients_layout:reset()
    for _, client in ipairs(self._private.sorted_clients) do
        clients_layout:add(client_widget(self, client))
    end

    self:_show()
end

function window_switcher:hide(focus)
    if focus == nil or focus == true then
        focus_client(self._private.selected_client)
    end

    self:_hide()
end

function window_switcher:toggle()
    if self.visible == true then
        self:hide()
    else
        self:show(true)
    end
end

local function new()
    local widget = widgets.animated_popup {
        placement = awful.placement.centered,
        visible = false,
        ontop = true,
        shape = helpers.ui.rrect(),
        bg = beautiful.colors.background,
        maximum_height = dpi(300),
        widget = wibox.widget {
            widget = wibox.container.margin,
            margins = dpi(15),
            {
                layout = wibox.layout.fixed.horizontal,
                id = "clients",
                spacing = dpi(15)
            }
        }
    }

    widget._private.sorted_clients = {}
    widget._show = widget.show
    widget._hide = widget.hide
    gtable.crush(widget, window_switcher, true)

    capi.client.connect_signal("manage", function()
        if widget.visible == true then
            widget:show()
        end
    end)

    capi.client.connect_signal("unmanage", function(client)
        if widget.visible == true then
            if client == widget._private.selected_client then
                widget:cycle_clients(true)
            end

            widget:show(false)
        end
    end)

    return widget
end

if not instance then
    instance = new()
end
return instance
