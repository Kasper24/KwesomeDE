-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gtable = require("gears.table")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local tasklist_daemon = require("daemons.system.tasklist")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local pcall = pcall
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
            normal_bg = beautiful.colors.surface,
            on_normal_bg = client.font_icon.color,
            on_release = function()
                self:select_client(client)
            end,
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
                            text_normal_bg = client.font_icon.color,
                            text_on_normal_bg = beautiful.colors.transparent,
                            client = client
                        },
                        {
                            widget = widgets.text,
                            halign = "center",
                            valign = "center",
                            size = 15,
                            text_normal_bg = beautiful.colors.on_background,
                            text_on_normal_bg = beautiful.colors.transparent,
                            text = client.name
                        }
                    },
                    {
                        widget = widgets.client_thumbnail,
                        text_normal_bg = client.font_icon.color,
                        text_on_normal_bg = beautiful.colors.transparent,
                        client = client
                    }
                }
            }
        }
    }
end

function window_switcher:select_client(client)
    local is_valid = pcall(function()
        return self._private.selected_client.valid
    end) and self._private.selected_client.valid
    if self._private.selected_client ~= nil and is_valid then
        self._private.selected_client.window_switcher_widget:get_children_by_id("button")[1]:turn_off()
    end

    if client.window_switcher_widget then
        client.window_switcher_widget:get_children_by_id("button")[1]:turn_on()
        self._private.selected_client = client
    end
end

function window_switcher:cycle_clients(increase)
    local clients = tasklist_daemon:get_clients()
    if #clients > 1 then
        local client = gtable.cycle_value(clients, self._private.selected_client, (increase and 1 or -1))
        self:select_client(client)
    elseif #clients == 1 then
        self:select_client(clients[1])
    end
end

function window_switcher:show()
    local clients = tasklist_daemon:get_clients()
    if #clients == 0 then
        return
    end

    if self._private.focused_client then
        self:select_client(self._private.focused_client)
    else
        self:select_client(clients[1])
    end

    self:_show(#clients * dpi(300) + #clients * dpi(15))
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
        maximum_height = dpi(200),
        animate_method = "width",
        widget = wibox.widget {
            widget = wibox.container.margin,
            margins = dpi(15),
            {
                layout = wibox.layout.manual,
                id = "clients",
            }
        }
    }

    widget._private.sorted_clients = {}
    widget._private.previous_sorted_clients = {}

    widget._show = widget.show
    widget._hide = widget.hide
    gtable.crush(widget, window_switcher, true)

    local clients_layout = widget.widget:get_children_by_id("clients")[1]

    tasklist_daemon:connect_signal("client::pos", function(self, client, pos, pos_without_pinned_apps)
        if client.window_switcher_widget == nil then
            client.window_switcher_widget = client_widget(widget, client)
            clients_layout:add_at(client.window_switcher_widget, { x =  pos_without_pinned_apps * 310, y = 0})
            if widget.visible then
                widget:_show(#tasklist_daemon:get_clients() * dpi(300) + #tasklist_daemon:get_clients() * dpi(15), true)
            end
        else
            clients_layout:move_widget(client.window_switcher_widget, { x = pos_without_pinned_apps * 310, y = 0})
        end
    end)

    tasklist_daemon:connect_signal("client::removed", function(self, client)
        clients_layout:remove_widgets(client.window_switcher_widget)
        client.window_switcher_widget = nil
    end)

    capi.client.connect_signal("focus", function(client)
        widget._private.focused_client = client
    end)

    capi.client.connect_signal("unfocus", function()
        widget._private.focused_client = nil
    end)

    return widget
end

if not instance then
    instance = new()
end
return instance
