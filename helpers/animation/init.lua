-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local GLib = require("lgi").GLib
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local gpcall = require("gears.protected_call")
local subscribable = require("helpers.animation.subscribable")
local tween = require("helpers.animation.tween")
local ipairs = ipairs
local table = table
local pairs = pairs

local animation_manager = {}
animation_manager.easing = {
    linear = "linear",
    inQuad = "inQuad",
    outQuad = "outQuad",
    inOutQuad = "inOutQuad",
    outInQuad = "outInQuad",
    inCubic = "inCubic",
    outCubic = "outCubic",
    inOutCubic = "inOutCubic",
    outInCubic = "outInCubic",
    inQuart = "inQuart",
    outQuart = "outQuart",
    inOutQuart = "inOutQuart",
    outInQuart = "outInQuart",
    inQuint = "inQuint",
    outQuint = "outQuint",
    inOutQuint = "inOutQuint",
    outInQuint = "outInQuint",
    inSine = "inSine",
    outSine = "outSine",
    inOutSine = "inOutSine",
    outInSine = "outInSine",
    inExpo = "inExpo",
    outExpo = "outExpo",
    inOutExpo = "inOutExpo",
    outInExpo = "outInExpo",
    inCirc = "inCirc",
    outCirc = "outCirc",
    inOutCirc = "inOutCirc",
    outInCirc = "outInCirc",
    inElastic = "inElastic",
    outElastic = "outElastic",
    inOutElastic = "inOutElastic",
    outInElastic = "outInElastic",
    inBack = "inBack",
    outBack = "outBack",
    inOutBack = "inOutBack",
    outInBack = "outInBack",
    inBounce = "inBounce",
    outBounce = "outBounce",
    inOutBounce = "inOutBounce",
    outInBounce = "outInBounce"
}

local animation = {}

local instance = nil

local function micro_to_milli(micro)
    return micro / 1000
end

local function second_to_micro(sec)
    return sec * 1000000
end

local function second_to_milli(sec)
    return sec * 1000
end

local function framerate_tomilli(framerate)
    return 1000 / framerate
end

local function init_animation_loop(self)
    self._private.source_id = GLib.timeout_add(
        GLib.PRIORITY_DEFAULT,
        framerate_tomilli(self._private.framerate),
        function()
            for index, animation in ipairs(self._private.animations) do
                if animation._private.state == true then
                    -- compute delta time
                    local time = GLib.get_monotonic_time()
                    local delta = time - animation.last_elapsed
                    animation.last_elapsed = time

                    -- If pos is true, the animation has ended
                    local pos = gpcall(animation.tween.update, animation.tween, delta)
                    if pos == true then
                        -- Loop the animation, don't end it.
                        -- Useful for widgets like the spinning cicle
                        if animation.loop == true then
                            animation.tween:reset()
                        else
                            animation._private.state = false

                            -- Snap to end
                            animation.pos = animation.tween.target

                            gpcall(animation.emit_signal, animation, "update", animation.pos)
                            gpcall(animation.fire, animation, animation.pos)

                            gpcall(animation.emit_signal, animation, "ended", animation.pos)
                            gpcall(animation.ended.fire, animation, animation.pos)

                            table.remove(self._private.animations, index)
                        end
                        -- Animation in process, keep updating
                    else
                        animation.pos = pos

                        gpcall(animation.emit_signal, animation, "update", animation.pos)
                        gpcall(animation.fire, animation, animation.pos)
                    end
                else
                    table.remove(self._private.animations, index)
                end
            end

            -- call again the function after cooldown
            return true
        end
    )
end

function animation:set(args)
    args = args or {}

    -- Awestoer/Rubbto compatibility
    -- I'd rather this always be a table, but Awestore/Rubbto
    -- except the :set() method to have 1 number value parameter
    -- used to set the target
    local is_table = type(args) == "table"
    local initial = is_table and (args.pos or self.pos) or self.pos
    local subject = is_table and (args.subject or self.subject) or self.subject
    local target = is_table and (args.target or self.target) or args
    local duration = is_table and (args.duration or self.duration) or self.duration
    local easing = is_table and (args.easing or self.easing) or self.easing

    if self.tween == nil or self.reset_on_stop == true then
        self.tween = tween.new {
            initial = initial,
            subject = subject,
            target = target,
            duration = second_to_micro(duration),
            easing = easing
        }
    end

    if self._private.anim_manager._private.instant then
        self.pos = self.tween.target
        self:fire(self.pos)
        self:emit_signal("update", self.pos)

        self._private.state = false
        self.ended:fire(self.pos)
        self:emit_signal("ended", self.pos)
        return
    end

    if self._private.anim_manager._private.animations[self.index] == nil then
        table.insert(self._private.anim_manager._private.animations, self)
    end

    self._private.state = true
    self.last_elapsed = GLib.get_monotonic_time()

    self.started:fire()
    self:emit_signal("started")
end

-- Rubato compatibility
function animation:abort()
    self._private.state = false
end

function animation:stop()
    self._private.state = false
end

function animation:initial()
    return self._private.initial
end

function animation:state()
    return self._private.state
end

function animation_manager:set_instant(value)
    if value == true and self._private.instant == false then
        -- Wait a bit so the already running animations can end
        gtimer.start_new(1, function()
            GLib.source_remove(self._private.source_id)
            return false
        end)
    elseif self._private.instant == true then
        init_animation_loop(self)
    end

    self._private.instant = value
end

function animation_manager:set_framerate(value)
    self._private.framerate = value
    if self._private.instant == false then
        -- Wait a bit so the already running animations can end
        gtimer.start_new(1, function()
            GLib.source_remove(self._private.source_id)
            init_animation_loop(self)
            return false
        end)
    end
end

function animation_manager:new(args)
    args = args or {}

    args.pos = args.pos or 0
    args.subject = args.subject or nil
    args.target = args.target or nil
    args.duration = args.duration or 0
    args.easing = args.easing or nil
    args.loop = args.loop or false
    args.signals = args.signals or {}
    args.update = args.update or nil
    args.reset_on_stop = args.reset_on_stop == nil and true or args.reset_on_stop

    -- Awestoer/Rubbto compatibility
    args.subscribed = args.subscribed or nil
    local ret = subscribable()
    ret.started = subscribable()
    ret.ended = subscribable()
    if args.subscribed ~= nil then
        ret:subscribe(args.subscribed)
    end

    for sig, sigfun in pairs(args.signals) do
        ret:connect_signal(sig, sigfun)
    end
    if args.update ~= nil then
        ret:connect_signal("update", args.update)
    end

    gtable.crush(ret, args, true)
    gtable.crush(ret, animation, true)

    ret._private = {}
    ret._private.anim_manager = self
    ret._private.initial = args.pos
    ret._private.state = false

    return ret
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, animation_manager, true)

    ret._private = {}
    ret._private.animations = {}
    ret._private.instant = false
    ret._private.framerate = 144

    init_animation_loop(ret)

    return ret
end

if not instance then
    instance = new()
end
return instance
