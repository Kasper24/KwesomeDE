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
    return wibox.widget {
        widget = wibox.container.constraint,
        mode = "max",
        width = dpi(300),
        height = dpi(200),
        {
            widget = widgets.button.elevated.state,
            id = "button",
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
end

function window_switcher:select_client(client)
    if self._private.selected_client then
        self._private.selected_client.window_switcher_widget:get_children_by_id("button")[1]:turn_off()
    end
    if client.window_switcher_widget then
        client.window_switcher_widget:get_children_by_id("button")[1]:turn_on()
        self._private.selected_client = client
    end
end

function window_switcher:cycle_clients(increase)
    local client = gtable.cycle_value(helpers.client.get_sorted_clients(), self._private.selected_client, (increase and 1 or -1))
    self:select_client(client)
end

function window_switcher:show()
    if #capi.client.get() == 0 then
        return
    end

    if self._private.focused_client then
        self:select_client(self._private.focused_client)
    end

    local clients = #capi.client.get()
    self:_show(clients * dpi(300) + clients * dpi(15))
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
        self:show()
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
        animate_method = "width",
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
    widget._private.previous_sorted_clients = {}

    widget._show = widget.show
    widget._hide = widget.hide
    gtable.crush(widget, window_switcher, true)

    local clients_layout = widget.widget:get_children_by_id("clients")[1]

    capi.client.connect_signal("unmanage", function(client)
        clients_layout:remove_widgets(client.window_switcher_widget)
    end)

    capi.client.connect_signal("swapped", function(client, other_client, is_source)
        if is_source then
            local client_index = helpers.client.get_client_index(client)
            local other_client_index = helpers.client.get_client_index(other_client)
            clients_layout:set(client_index, client.window_switcher_widget)
            clients_layout:set(other_client_index, other_client.window_switcher_widget)
        end
    end)

    capi.client.connect_signal("ui::ready", function(client)
        if client.window_switcher_widget then
            clients_layout:remove_widgets(client.window_switcher_widget)
        end
        client.window_switcher_widget = client_widget(widget, client)
        local client_index = helpers.client.get_client_index(client)
        if #clients_layout.children < client_index then
            clients_layout:add(client.window_switcher_widget)
        else
            clients_layout:insert(client_index, client.window_switcher_widget)
        end
    end)

    capi.client.connect_signal("focus", function(client)
        widget._private.focused_client = client
    end)

    return widget
end

if not instance then
    instance = new()
end
return instance
