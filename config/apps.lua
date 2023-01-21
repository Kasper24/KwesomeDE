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
local keys = { mod = "Mod4", ctrl = "Control", shift = "Shift", alt = "Mod1" }

local apps = {}
local instance = nil

local function centered_gemotery(width, height)
    width = width or awful.screen.focused().geometry.width * 0.7
    height = height or awful.screen.focused().geometry.height * 0.9

    return
    {
        x = (awful.screen.focused().geometry.width / 2) - (width /  2),
        y = (awful.screen.focused().geometry.height / 2) - (height / 2),
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

function apps:scratchpad_toggle(id, new_animation)
    if self.scratchpads[id].rubato.x.state == false and
       self.scratchpads[id].rubato.y.state == false
    then
        self.scratchpads[id].geometry = centered_gemotery()
        if new_animation then
            local x, y = random_animation()
            self.scratchpads[id].rubato.x.pos = x
            self.scratchpads[id].rubato.y.pos = y
        end
    end

    self.scratchpads[id]:toggle()
end

function apps:new(id, key, command, class, args)
    args = args or {}

    args.launch_modifiers = args.launch_modifiers or { keys.mod, keys.ctrl }
    args.scratchpad_modifiers = args.scratchpad_modifiers or { keys.mod, keys.alt }
    args.geometry = args.geometry or centered_gemotery()
    args.new_animation_on_toggle = args.new_animation_on_toggle == nil and true or args.new_animation_on_toggle
    args.run_or_raise = args.run_or_raise == nil and true or args.run_or_raise

    local x, y = random_animation()
    args.x = args.x or x
    args.y = args.y or y

    self.scratchpads[id] = bling.module.scratchpad:new
    {
        command = command,
        rule = {class = class},
        sticky = false,
        autoclose = false,
        floating = true,
        geometry = args.geometry,
        reapply = true,
        dont_focus_before_close  = true,
        rubato =
        {
            x = helpers.animation:new
            {
                easing = helpers.animation.easing.inBounce,
                pos = args.x,
                duration = 1.5,
            },
            y = helpers.animation:new
            {
                easing = helpers.animation.easing.inBounce,
                pos = args.y,
                duration = 1.5,
            }
        }
    }

    self.scratchpads[id]:connect_signal("turn_on", function()
        self.scratchpads[id].rubato.x.easing = helpers.animation.easing.inBounce
        self.scratchpads[id].rubato.y.easing = helpers.animation.easing.inBounce
    end)

    self.scratchpads[id]:connect_signal("turn_off", function()
        self.scratchpads[id].rubato.x.easing = helpers.animation.easing.outBounce
        self.scratchpads[id].rubato.y.easing = helpers.animation.easing.outBounce
    end)

    awful.keyboard.append_global_keybindings
    ({
        awful.key
        {
            modifiers = args.scratchpad_modifiers,
            key = key,
            group = "apps",
            description = "toggle " .. id .. " scratchpad ",
            on_press = function()
                self:scratchpad_toggle(id, args.new_animation_on_toggle)
            end,
        }
    })

    awful.keyboard.append_global_keybindings
    ({
        awful.key
        {
            modifiers = args.launch_modifiers,
            key = key,
            group = "apps",
            description = "launch " .. id,
            on_press = function()
                if args.run_or_raise == true then
                    helpers.client.run_or_raise({class = class}, false, command, { switchtotag = true })
                else
                    awful.spawn(command)
                end
            end,
        }
    })
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, apps, true)
    ret.scratchpads = {}

    ret:new("vivaldi", "b", "vivaldi-stable", "Vivaldi-stable")
    ret:new("vscode", "e", "code", "Code")
    ret:new("lazygit", "g", "kitty --class gitqlient lazygit", "gitqlient", {run_or_raise = false})
    ret:new("kotatogram", "t", "kotatogram-desktop", "KotatogramDesktop")
    ret:new("discord", "d", "discocss", "discord")
    ret:new("ncmpcpp", "n", "kitty --class mopidy ncmpcpp", "mopidy")
    ret:new("spotify", "s", "spotify", "Spotify")
    ret:new("openrgb", "o", "openrgb", "openrgb")
    ret:new("artemis", "a", "artemis", "artemis.ui.exe")
    ret:new("ranger", "f", "kitty --class ranger ranger", "ranger", {run_or_raise = false})
    ret:new("kitty", "Return", "kitty", "kitty",
    {
        launch_modifiers = { keys.mod },
        run_or_raise = false,
    })
    ret:new("gnome-sysetm-monitor", "Delete", "gnome-system-monitor", "Gnome-system-monitor",
    {
        launch_modifiers = { keys.ctrl, keys.alt }
    })

    return ret
end

if not instance then
    instance = new(...)
end
return instance