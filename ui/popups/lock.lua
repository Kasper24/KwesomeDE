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
local theme_daemon = require("daemons.system.theme")
local system_daemon = require("daemons.system.system")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local collectgarbage = collectgarbage
local os = os
local capi = {
    screen = screen
}

local lock = {}
local instance = nil

function lock:show()
    self.widget.screen = awful.screen.focused()
    self.widget.visible = true

    self._private.prompt:start()

    self:emit_signal("visibility", true)
end

function lock:hide()
    self._private.prompt:stop()

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

local function widget(self)
    local blur = wibox.widget {
        widget = widgets.background,
        bg = beautiful.colors.background
    }

    local picture = wibox.widget {
        widget = wibox.widget.imagebox,
        halign = "center",
        clip_shape = helpers.ui.rrect(),
        forced_height = dpi(180),
        forced_width = dpi(180),
        image = beautiful.profile_icon
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
        align = "center",
        valign = "center",
        format = "%H:%M",
        font = beautiful.font_name .. 60
    }

    local date = wibox.widget {
        widget = wibox.widget.textclock,
        align = "center",
        valign = "center",
        format = "%d" .. helpers.string.day_ordinal_number() .. " of %B, %A",
        font = beautiful.font_name .. 30
    }

    self._private.prompt = wibox.widget {
        widget = widgets.prompt,
        forced_width = dpi(450),
        forced_height = dpi(50),
        on_normal_bg = beautiful.colors.background,
        on_hover_bg = beautiful.colors.background,
        on_press_bg = beautiful.colors.background,
        reset_on_stop = true,
        always_on = true,
        obscure = true,
        icon_font = beautiful.icons.lock.font,
        icon = beautiful.icons.lock.icon,
        keyreleased_callback = function(mod, key, text)
            if key == "Return" then
                system_daemon:unlock(text)
            end
        end
    }

    local toggle_password_obscure_button = wibox.widget {
        widget = widgets.checkbox,
        state = true,
        handle_active_color = beautiful.colors.on_background,
        on_turn_on = function()
            self._private.prompt:set_obscure(true)
        end,
        on_turn_off = function()
            self._private.prompt:set_obscure(false)
        end
    }

    local unlock_button = wibox.widget {
        widget = widgets.button.text.normal,
        text_normal_bg = beautiful.colors.on_background,
        text = "Unlock",
        on_release = function()
            system_daemon:unlock(self._private.prompt:get_text())
        end
    }

    local shutdown_button = wibox.widget {
        widget = widgets.button.text.normal,
        icon = beautiful.icons.poweroff,
        size = 40,
        on_release = function()
            system_daemon:shutdown()
        end
    }

    local restart_button = wibox.widget {
        widget = widgets.button.text.normal,
        icon = beautiful.icons.reboot,
        size = 40,
        on_release = function()
            system_daemon:restart()
        end
    }

    local suspend_button = wibox.widget {
        widget = widgets.button.text.normal,
        icon = beautiful.icons.suspend,
        size = 40,
        on_release = function()
            system_daemon:suspend()
        end
    }

    local exit_button = wibox.widget {
        widget = widgets.button.text.normal,
        icon = beautiful.icons.exit,
        size = 40,
        on_release = function()
            system_daemon:exit()
        end
    }

    return wibox.widget {
        widget = wibox.layout.stack,
        widgets.wallpaper,
        blur,
        {
            widget = wibox.container.place,
            halign = "center",
            valign = "center",
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(15),
                clock,
                date,
                user,
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = dpi(15),
                    self._private.prompt,
                    toggle_password_obscure_button
                },
                unlock_button
            }
        },
        {
            widget = wibox.container.margin,
            margins = {
                bottom = dpi(30),
                right = dpi(30)
            },
            {
                widget = wibox.container.place,
                halign = "right",
                valign = "bottom",
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = dpi(15),
                    shutdown_button,
                    restart_button,
                    suspend_button,
                    exit_button
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
        type = "splash",
        visible = false,
        ontop = true,
        placement = awful.placement.maximize,
        widget = widget(ret)
    }

    system_daemon:connect_signal("lock", function()
        ret:show()
    end)

    system_daemon:connect_signal("unlock", function()
        ret:hide()
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance
