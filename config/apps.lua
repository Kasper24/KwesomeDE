-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local bling = require("external.bling")
local helpers = require("helpers")
local math = math
local keys = {
    mod = "Mod4",
    ctrl = "Control",
    shift = "Shift",
    alt = "Mod1"
}

local apps = {}
local app = {}

local instance = nil

local function centered_gemotery(width, height)
    width = width or awful.screen.focused().geometry.width * 0.7
    height = height or awful.screen.focused().geometry.height * 0.9

    return {
        x = (awful.screen.focused().geometry.width / 2) - (width / 2),
        y = (awful.screen.focused().geometry.height / 2) - (height / 2),
        width = width,
        height = height
    }
end

local function terminal_gemotery(width, height)
    width = width or awful.screen.focused().geometry.width * 0.7
    height = height or awful.screen.focused().geometry.height * 0.5

    return {
        x = (awful.screen.focused().geometry.width / 2) - (width / 2),
        y = 100,
        width = width,
        height = height
    }
end

local function random_animation()
    local screen_width = awful.screen.focused().geometry.width
    local screen_height = awful.screen.focused().geometry.height

    local x = math.random(screen_width, screen_width + 1500)
    local y = math.random(screen_height, screen_height + 1500)

    x = (math.random(0, 1)) == 1 and x * 1 or x * -1;
    y = (math.random(0, 1)) == 1 and y * 1 or y * -1;

    return x, y
end

function app:toggle()
    if self.run_or_raise == true then
        helpers.client.run_or_raise({class = self.class}, false, self.command, { switchtotag = true })
    else
        awful.spawn(self.command)
    end
end

function app:scratchpad_toggle()
    if self.scratchpad.rubato.x.state == false and self.scratchpad.rubato.y.state == false then
        self.scratchpad.geometry = self.geometry
        if self.new_animation_on_toggle then
            local x, y = random_animation()
            self.scratchpad.rubato.x.pos = x
            self.scratchpad.rubato.y.pos = y
        end
    end

    self.scratchpad:toggle()
end

function apps:new(id, key, command, class, args)
    args = args or {}

    local ret = gobject {}
    gtable.crush(ret, app, true)

    ret.id = id
    ret.key = key
    ret.command = command
    ret.class = class
    ret.scratchpad_command = args.scratchpad_command or command
    ret.scratchpad_class = args.scratchpad_class or class
    ret.launch_modifiers = args.launch_modifiers or {keys.mod, keys.ctrl}
    ret.scratchpad_modifiers = args.scratchpad_modifiers or {keys.mod, keys.alt}
    ret.geometry = args.geometry or centered_gemotery()
    ret.new_animation_on_toggle = args.new_animation_on_toggle == nil and true or args.new_animation_on_toggle
    ret.run_or_raise = args.run_or_raise == nil and true or args.run_or_raise

    local x, y = random_animation()
    ret.x = args.x or x
    ret.y = args.y or y

    ret.scratchpad = bling.module.scratchpad:new{
        command = ret.scratchpad_command,
        rule = { class = ret.scratchpad_class },
        sticky = false,
        autoclose = false,
        floating = true,
        geometry = ret.geometry,
        reapply = true,
        dont_focus_before_close = true,
        rubato = {
            x = helpers.animation:new{
                easing = helpers.animation.easing.inBounce,
                pos = ret.x,
                duration = 1.5
            },
            y = helpers.animation:new{
                easing = helpers.animation.easing.inBounce,
                pos = ret.y,
                duration = 1.5
            }
        }
    }

    ret.scratchpad:connect_signal("turn_on", function()
        ret.scratchpad.rubato.x.easing = helpers.animation.easing.inBounce
        ret.scratchpad.rubato.y.easing = helpers.animation.easing.inBounce
    end)

    ret.scratchpad:connect_signal("turn_off", function()
        ret.scratchpad.rubato.x.easing = helpers.animation.easing.outBounce
        ret.scratchpad.rubato.y.easing = helpers.animation.easing.outBounce
    end)

    awful.keyboard.append_global_keybindings({awful.key {
        modifiers = ret.scratchpad_modifiers,
        key = ret.key,
        group = "apps",
        description = "toggle " .. ret.id .. " scratchpad ",
        on_press = function()
            ret:scratchpad_toggle()
        end
    }})

    awful.keyboard.append_global_keybindings({awful.key {
        modifiers = ret.launch_modifiers,
        key = ret.key,
        group = "apps",
        description = "launch " .. ret.id,
        on_press = function()
            ret:toggle()
        end
    }})
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, apps, true)

    ret:new("vivaldi", "b", "vivaldi-stable", "Vivaldi-stable")
    ret:new("vscode", "e", "code", "Code")
    ret:new("lazygit", "g", "kitty --class gitqlient lazygit", "gitqlient", {
        run_or_raise = false
    })
    ret:new("kotatogram", "t", "kotatogram-desktop", "KotatogramDesktop")
    ret:new("discord", "d", "discocss", "discord")
    ret:new("ncmpcpp", "n", "kitty --class mopidy ncmpcpp", "mopidy")
    ret:new("spotify", "s", "spotify", "Spotify")
    ret:new("openrgb", "o", "openrgb", "openrgb")
    ret:new("artemis", "a", "artemis", "artemis.ui.exe")
    ret:new("ranger", "f", "kitty --class ranger ranger", "ranger", {
        run_or_raise = false
    })
    ret:new("kitty", "Return", "kitty", "kitty", {
        launch_modifiers = {keys.mod},
        run_or_raise = false,
        geometry = terminal_gemotery(),
        scratchpad_command = "kitty --class scratchpad",
        scratchpad_class = "scratchpad"
    })
    ret:new("gnome-sysetm-monitor", "Delete", "gnome-system-monitor", "Gnome-system-monitor", {
        launch_modifiers = {keys.ctrl, keys.alt}
    })

    return ret
end

if not instance then
    instance = new(...)
end
return instance
