-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local system_daemon = require("daemons.system.system")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local os = os

local lock = {}
local instance = nil

function lock:show()
    self.widget.screen = awful.screen.focused()
    self.widget.visible = true
    self._private.text_input:focus()
    self:emit_signal("visibility", true)
end

function lock:hide()
    self._private.text_input:unfocus()
    self.widget.visible = false
    self:emit_signal("visibility", false)
end

function lock:toggle()
    if self.widget.visible then
        self:hide()
    else
        self:show()
    end
end

function lock:is_visible()
    return self.widget.visible
end

local function action_button(icon, title, on_release)
    return wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        {
            widget = widgets.button.normal,
            forced_width = dpi(75),
            forced_height = dpi(75),
            -- normal_bg = beautiful.icons.lock.color,
            on_release = function()
                on_release()
            end,
            {
                widget = widgets.text,
                color = beautiful.colors.on_background,
                size = 30,
                icon = icon,
            }
        },
        {
            widget = widgets.text,
            halign = "center",
            size = 15,
            text = title
        }
    }
end

local function widget(self)
    local picture = wibox.widget {
        widget = widgets.profile,
        forced_height = dpi(180),
        forced_width = dpi(180),
    }

    local name = wibox.widget {
        widget = widgets.text,
        halign = "center",
        color = beautiful.colors.on_background,
        text = os.getenv("USER"):upper()
    }

    local user = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        picture,
        name
    }

    local clock = wibox.widget {
        widget = wibox.widget.textclock,
        format = "%H:%M",
        halign = "center",
        size = 60
    }

    local date = wibox.widget {
        widget = wibox.widget.textclock,
        format = "%d" .. helpers.string.day_ordinal_number() .. " of %B, %A",
        halign = "center",
        size = 30
    }

    self._private.text_input = wibox.widget {
        widget = widgets.text_input,
        forced_width = dpi(450),
        unfocus_keys = { },
        unfocus_on_client_focus = false,
        unfocus_on_clicked_outside = false,
        unfocus_on_mouse_leave = false,
        unfocus_on_tag_change = false,
        unfocus_on_other_text_input_focus = false,
        reset_on_unfocus = true,
        obscure = true,
        selection_bg = beautiful.icons.lock.color,
        widget_template = wibox.widget {
            layout = wibox.layout.fixed.horizontal,
            spacing = dpi(15),
            {
                widget = widgets.text,
                icon = beautiful.icons.lock
            },
            {
                layout = wibox.layout.stack,
                {
                    widget = wibox.widget.textbox,
                    id = "placeholder_role",
                    text = "Password:"
                },
                {
                    widget = wibox.widget.textbox,
                    id = "text_role"
                },
            }
        }
    }

    self._private.text_input:connect_signal("key::press", function(self, mod, key, event)
        if key == "Return" then
            system_daemon:unlock(self:get_text())
        end
    end)

    local toggle_password_obscure_button = wibox.widget {
        widget = widgets.checkbox,
        state = true,
        handle_active_color = beautiful.icons.lock.color,
        on_turn_on = function()
            self._private.text_input:set_obscure(true)
        end,
        on_turn_off = function()
            self._private.text_input:set_obscure(false)
        end
    }

    local unlock_button = wibox.widget {
        widget = widgets.button.normal,
        normal_bg = beautiful.icons.lock.color,
        on_release = function()
            system_daemon:unlock(self._private.text_input:get_text())
        end,
        {
            widget = widgets.text,
            color = beautiful.colors.transparent,
            text = "Unlock"
        }
    }

    return wibox.widget {
        widget = wibox.container.place,
        halign = "center",
        valign = "center",
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(30),
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(15),
                clock,
                date,
                user,
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = dpi(15),
                    self._private.text_input,
                    toggle_password_obscure_button
                },
            },
            unlock_button,
            {
                widget = wibox.container.place,
                halign = "center",
                valign = "center",
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = dpi(45),
                    action_button(beautiful.icons.poweroff, "Shutdown", function()
                        system_daemon:shutdown()
                    end),
                    action_button(beautiful.icons.reboot, "Restart", function()
                        system_daemon:reboot()
                    end),
                    action_button(beautiful.icons.suspend, "Suspend", function()
                        system_daemon:suspend()
                    end),
                    action_button(beautiful.icons.exit, "Exit", function()
                        system_daemon:exit()
                    end)
                }
            }
        }
    }
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, lock, true)

    ret._private = {}
    ret._private.grabber = nil

    ret.widget = widgets.popup {
        visible = false,
        ontop = true,
        placement = awful.placement.maximize,
        bg = beautiful.colors.background,
        widget = widget(ret)
    }

    system_daemon:connect_signal("lock", function()
        ret:show()
    end)

    system_daemon:connect_signal("unlock", function()
        ret:hide()
    end)

    system_daemon:connect_signal("wrong_password", function()
        ret._private.text_input:set_text("")
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance
