-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("ui.widgets")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local capi = {
    awesome = awesome,
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

    local font_icon = beautiful.get_font_icon_for_app_name(client.class)
    local is_selected = client == self._private.selected_client

    local widget = wibox.widget {
        widget = wibox.container.constraint,
        mode = "max",
        width = dpi(300),
        height = dpi(150),
        {
            widget = widgets.button.elevated.state,
            id = "button",
            on_by_default = is_selected,
            normal_bg = beautiful.colors.background,
            normal_border_width = dpi(5),
            normal_border_color = beautiful.colors.surface,
            on_normal_border_color = font_icon.color,
            on_release = function()
                self:select_client(client)
                self:hide()
            end,
            child = {
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
                            valign = "center",
                            icon = font_icon
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

    return widget
end

local function clients_widget(self)
    local clients_layout = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15)
    }

    for _, tag in ipairs(helpers.client.get_sorted_clients()) do
        local master = tag["master"]
        if master ~= nil then
            clients_layout:add(client_widget(self, master))
        end

        for _, client in ipairs(tag.clients) do
            clients_layout:add(client_widget(self, client))
        end
    end

    return wibox.widget {
        widget = wibox.container.margin,
        margins = dpi(15),
        clients_layout
    }
end

function window_switcher:select_client(client)
    self._private.selected_client = client
    self.widget.widget = clients_widget(self)
end

function window_switcher:cycle_clients(increase)
    local client = gtable.cycle_value(capi.client.get(), self._private.selected_client, (increase and 1 or -1))
    self:select_client(client)
end

function window_switcher:show(set_selected_client, keygrabber)
    self._private.keygrabber = keygrabber

    if #capi.client.get() == 0 then
        self:hide(false)
        return
    end

    if set_selected_client == true or set_selected_client == nil then
        self._private.selected_client = capi.client.focus
    end

    self.widget.widget = clients_widget(self)
    self.widget.visible = true
end

function window_switcher:hide(focus)
    if focus == nil or focus == true then
        focus_client(self._private.selected_client)
    end

    awful.keygrabber.stop(self._private.keygrabber)

    self.widget.visible = false
    self.widget.widget = nil

    collectgarbage("collect")
end

function window_switcher:toggle(keygrabber)
    if self.widget.visible == true then
        self:hide()
    else
        self:show(true, keygrabber)
    end
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, window_switcher)

    ret._private = {}
    ret._private.sorted_clients = {}

    ret.widget = awful.popup {
        type = 'dropdown_menu',
        placement = awful.placement.centered,
        visible = false,
        ontop = true,
        shape = helpers.ui.rrect(beautiful.border_radius),
        bg = beautiful.colors.background_with_opacity,
        widget = wibox.container.background -- A dummy widget to make awful.popup not scream
    }

    capi.client.connect_signal("manage", function()
        if ret.widget.visible == true then
            ret:show()
        end
    end)

    capi.client.connect_signal("unmanage", function(client)
        if ret.widget.visible == true then
            if client == ret._private.selected_client then
                ret:cycle_clients(true)
            end

            ret:show(false)
        end
    end)

    capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
        ret.bg = old_colorscheme_to_new_map[beautiful.colors.background]
        ret.widget.bg = old_colorscheme_to_new_map[beautiful.colors.background]
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance
