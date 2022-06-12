-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local wibox = require("wibox")
local widgets = require("presentation.ui.widgets")
local beautiful = require("beautiful")
local theme_daemon = require("daemons.system.theme")
local system_daemon = require("daemons.system.system")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local collectgarbage = collectgarbage
local os = os
local capi = { screen = screen }

local lock = { }
local instance = nil

function lock:show()
    self._private.prompt:start()

    for s in capi.screen do
        if s == awful.screen.focused() then
            s.power_popup = self.widget
        else
            s.power_popup = widgets.screen_mask.background(s)
        end
        s.power_popup.visible = true
    end

    self:emit_signal("visibility", true)
end

function lock:hide()
    self._private.prompt:stop()

    for s in capi.screen do
        if s.power_popup and s.power_popup.visible == true then
            s.power_popup.visible = false
            s.power_popup = nil
            collectgarbage("collect")
        end
    end

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
    local background = wibox.widget
    {
        widget = wibox.widget.imagebox,
        resize = true,
        horizontal_fit_policy = "fit",
        vertical_fit_policy = "fit",
        image = theme_daemon:get_wallpaper()
    }

    local picture = wibox.widget
    {
        widget = wibox.widget.imagebox,
        halign = "center",
        clip_shape = helpers.ui.rrect(beautiful.border_radius),
        forced_height = dpi(180),
        forced_width = dpi(180),
        image = beautiful.profile_icon,
    }

    local name = widgets.text
    {
        halign = "center",
        text = os.getenv("USER"):upper()
    }

    local user = wibox.widget
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        picture,
        name
    }

    local clock = wibox.widget
    {
        widget = wibox.widget.textclock,
        align = "center",
        valign = "center",
        format = "%H:%M",
        font = beautiful.font_name .. 60,
    }

    local date = wibox.widget
    {
        widget = wibox.widget.textclock,
        align = "center",
        valign = "center",
        format = "%d" .. helpers.string.day_ordinal_number() .. " of %B, %A",
        font = beautiful.font_name .. 30,
    }

    self._private.prompt = widgets.prompt
    {
        forced_width = dpi(450),
        forced_height = dpi(50),
        reset_on_stop = true,
        always_on = true,
        obscure = true,
        icon_font = beautiful.lock_icon.font,
        icon = beautiful.lock_icon.icon,
        paddings = dpi(15),
        keyreleased_callback = function(mod, key, text)
            if key == "Return" then
                system_daemon:unlock(text)
            end
        end
    }

    local toggle_password_button = widgets.checkbox
    {
        on_by_default = true,
        on_turn_on = function()
            self._private.prompt:set_obscure(true)
        end,
        on_turn_off = function()
            self._private.prompt:set_obscure(false)
        end
    }

    local unlock_button = widgets.button.text.normal
    {
        animate_size = false,
        text = "Unlock",
        on_release = function()
            system_daemon:unlock(self._private.prompt:get_text())
        end,
    }

    local accent_color = beautiful.random_accent_color()

    local shutdown_button = widgets.button.text.normal
    {
        normal_bg = beautiful.colors.transparent,
        text_normal_bg = accent_color,
        size = 30,
        font = beautiful.poweroff_icon.font,
        text = beautiful.poweroff_icon.icon,
        on_release = function()
            system_daemon:shutdown()
        end
    }

    local restart_button = widgets.button.text.normal
    {
        normal_bg = beautiful.colors.transparent,
        text_normal_bg = accent_color,
        size = 30,
        font = beautiful.reboot_icon.font,
        text = beautiful.reboot_icon.icon,
        on_release = function()
            system_daemon:restart()
        end
    }

    local suspend_button = widgets.button.text.normal
    {
        normal_bg = beautiful.colors.transparent,
        text_normal_bg = accent_color,
        size = 30,
        font = beautiful.suspend_icon.font,
        text = beautiful.suspend_icon.icon,
        on_release = function()
            system_daemon:suspend()
        end
    }

    local exit_button = widgets.button.text.normal
    {
        normal_bg = beautiful.colors.transparent,
        text_normal_bg = accent_color,
        size = 30,
        font = beautiful.exit_icon.font,
        text = beautiful.exit_icon.icon,
        on_release = function()
            system_daemon:exit()
        end
    }

    return wibox.widget
    {
        widget = wibox.layout.stack,
        background,
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
                    spacing = dpi(5),
                    {
                        layout = wibox.layout.stack,
                        self._private.prompt.widget,
                        {
                            widget = wibox.container.place,
                            halign = "right",
                            valign = "center",
                            toggle_password_button
                        }
                    }
                },
                unlock_button
            }
        },
        {
            widget = wibox.container.margin,
            margins = { bottom = dpi(30), right = dpi(30) },
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
    local ret = gobject{}
    gtable.crush(ret, lock, true)

    ret._private = {}
    ret._private.grabber = nil

    ret.widget = awful.popup
    {
        type = "splash",
        visible = false,
        ontop = true,
        placement = awful.placement.maximize,
        bg = beautiful.colors.background .. "28",
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