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
local system_daemon = require("daemons.system.system")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local collectgarbage = collectgarbage
local math = math
local os = os
local capi = { screen = screen }

local power = { }
local instance = nil

local greeters =
{
	"See you later, alligator!",
	"After a while, crocodile.",
	"Stay out of trouble.",
	"I’m out of here.",
	"Yamete, onii-chan~. UwU",
	"Okay...bye, fry guy!",
	"Peace out!",
	"Peace out, bitch!",
	"Gotta get going.",
	"Out to the door, dinosaur.",
	"Don\"t forget to come back!",
	"Smell ya later!",
	"In a while, crocodile.",
	"Adios, amigo.",
	"Begone!",
	"Arrivederci.",
	"Never look back!",
	"So long, sucker!",
	"Au revoir!",
	"Later, skater!",
	"That\"ll do pig. That\"ll do.",
	"Happy trails!",
	"Smell ya later!",
	"See you soon, baboon!",
	"Bye Felicia!",
	"Sayonara!",
	"Ciao!",
	"Well.... bye.",
	"Delete your browser history!",
	"See you, Space Cowboy!",
	"Change da world. My final message. Goodbye.",
	"Find out on the next episode of Dragonball Z...",
	"Choose wisely!"
}

function power:show()
    for s in capi.screen do
        if s == awful.screen.focused() then
            s.power_popup = self.widget
        else
            s.power_popup = widgets.screen_mask(s)
        end
        s.power_popup.visible = true
    end

    self._private.grabber = awful.keygrabber.run(function(_, key, event)
        key = key:lower() -- Ignore case

        if event == "release" then
            return
        elseif key == "s" then
            self:hide()
            system_daemon:suspend()
        elseif key == "e" then
            system_daemon:exit()
        elseif key == "l" then
            self:hide()
            system_daemon:lock()
        elseif key == "p" then
            system_daemon:shutdown()
        elseif key == "r" then
            system_daemon:reboot()
        elseif key == "escape" or key == "q" or key == "x" then
            self:hide()
        end
    end)

    self:emit_signal("visibility", true)
end

function power:hide()
    for s in capi.screen do
        if s.power_popup and s.power_popup.visible == true then
            s.power_popup.visible = false
            s.power_popup = nil
            collectgarbage("collect")
        end
    end

    awful.keygrabber.stop(self._private.grabber)

    self:emit_signal("visibility", false)
end

function power:toggle()
    if self.widget.visible then
        self:hide()
    else
        self:show()
    end
end

local function button(image, text, on_release)
    local accent_color = beautiful.random_accent_color()

    local text = widgets.text
    {
        halign = "center",
        size = 15,
        text = text,
    }

    local button =  widgets.button.text.normal
    {
        forced_height = dpi(120),
        forced_width = dpi(120),
        normal_bg = beautiful.colors.background,
        text_normal_bg = beautiful.colors.on_background,
        text_hover_bg = accent_color,
        text_press_bg = helpers.color.lighten(accent_color, 0.2),
        normal_border_width = dpi(0),
        hover_border_width = dpi(10),
        press_border_width = dpi(10),
        normal_border_color = beautiful.colors.background,
        hover_border_color = accent_color,
        press_border_color = helpers.color.lighten(accent_color, 0.2),
        font = image.font,
        size = 40,
        text = image.icon,
        on_release = on_release
    }

    return wibox.widget
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        button,
        text
    }
end

local function widget(self)
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

    local greeter = widgets.text
    {
        halign = "center",
        size = 50,
        text = greeters[math.random(#greeters)]
    }

    local shutdown = button(beautiful.poweroff_icon, "Shutdown", function() system_daemon:shutdown() end)
    local reboot = button(beautiful.reboot_icon, "Restart", function() system_daemon:reboot() end)
    local suspend = button(beautiful.suspend_icon, "Suspend", function() system_daemon:suspend() end)
    local exit = button(beautiful.exit_icon, "Exit", function() system_daemon:exit() end)
    local lock = button(beautiful.lock_icon, "Lock", function() self:hide() system_daemon:lock() end)

    local buttons = wibox.widget
    {
        widget = wibox.container.place,
        halign = "center",
        valign = "center",
        {
            layout = wibox.layout.fixed.horizontal,
            spacing = dpi(50),
            shutdown,
            reboot,
            suspend,
            exit,
            lock
        }
    }

    return wibox.widget
    {
        widget = wibox.container.place,
        halign = "center",
        valign = "center",
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(15),
            user,
            greeter,
            buttons
        }
    }
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, power, true)

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

    return ret
end

if not instance then
    instance = new()
end
return instance