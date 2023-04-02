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
local math = math
local os = os

local power = {}
local instance = nil

local greeters = {"See you later, alligator!", "After a while, crocodile.", "Stay out of trouble.",
                  "I’m out of here.", "Yamete, onii-chan~. UwU", "Okay...bye, fry guy!", "Peace out!",
                  "Peace out, bitch!", "Gotta get going.", "Out to the door, dinosaur.", "Don\"t forget to come back!",
                  "Smell ya later!", "In a while, crocodile.", "Adios, amigo.", "Begone!", "Arrivederci.",
                  "Never look back!", "So long, sucker!", "Au revoir!", "Later, skater!",
                  "That\"ll do pig. That\"ll do.", "Happy trails!", "Smell ya later!", "See you soon, baboon!",
                  "Bye Felicia!", "Sayonara!", "Ciao!", "Well.... bye.", "Delete your browser history!",
                  "See you, Space Cowboy!", "Change da world. My final message. Goodbye.",
                  "Find out on the next episode of Dragonball Z...", "Choose wisely!"}

function power:show()
    self.widget.screen = awful.screen.focused()
    self.widget.visible = true
    self:emit_signal("visibility", true)
end

function power:hide(emit_signal)
    self.widget.visible = false

    if emit_signal ~= false then
        self:emit_signal("visibility", false)
    end
end

function power:toggle()
    if self.widget.visible then
        self:hide()
    else
        self:show()
    end
end

function power:is_visible()
    return self.widget.visible
end

local function button(icon, text, on_release)
    local button = wibox.widget {
        widget = widgets.button.text.normal,
        forced_width = dpi(120),
        forced_height = dpi(120),
        text_normal_bg = icon.color,
        normal_border_width = dpi(0),
        hover_border_width = dpi(10),
        press_border_width = dpi(10),
        normal_border_color = icon.color,
        icon = icon,
        size = 40,
        on_release = on_release
    }

    local text = wibox.widget {
        widget = widgets.text,
        halign = "center",
        size = 15,
        text = text
    }

    return wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        button,
        text
    }
end

local function widget(self)
    local picture = wibox.widget {
        widget = widgets.profile,
        halign = "center",
        clip_shape = helpers.ui.rrect(),
        forced_height = dpi(180),
        forced_width = dpi(180),
    }

    local name = wibox.widget {
        widget = widgets.text,
        halign = "center",
        text = os.getenv("USER"):upper()
    }

    local user = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(15),
        picture,
        name
    }

    local greeter = wibox.widget {
        widget = widgets.text,
        halign = "center",
        size = 50,
        text = greeters[math.random(#greeters)]
    }

    local shutdown = button(beautiful.icons.poweroff, "Shutdown", function()
        system_daemon:shutdown()
    end)
    local reboot = button(beautiful.icons.reboot, "Restart", function()
        system_daemon:reboot()
    end)
    local suspend = button(beautiful.icons.suspend, "Suspend", function()
        system_daemon:suspend()
    end)
    local exit = button(beautiful.icons.exit, "Exit", function()
        system_daemon:exit()
    end)
    local lock = button(beautiful.icons.lock, "Lock", function()
        self.widget.visible = false
        self:hide(false)
        system_daemon:lock()
    end)

    local buttons = wibox.widget {
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

    return wibox.widget {
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
    local ret = gobject {}
    gtable.crush(ret, power, true)

    ret._private = {}

    ret.widget = widgets.popup {
        visible = false,
        ontop = true,
        placement = awful.placement.maximize,
        bg = beautiful.colors.background,
        widget = widget(ret)
    }

    return ret
end

if not instance then
    instance = new()
end
return instance
