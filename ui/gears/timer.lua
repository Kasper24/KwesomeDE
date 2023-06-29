---------------------------------------------------------------------------
--- Timer objects and functions.
--
-- @usage
--    -- Create a widget and update its content using the output of a shell
--    -- command every 10 seconds:
--    local mybatterybar = wibox.widget {
--        {
--            min_value    = 0,
--            max_value    = 100,
--            value        = 0,
--            paddings     = 1,
--            border_width = 1,
--            forced_width = 50,
--            border_color = "#0000ff",
--            id           = "mypb",
--            widget       = wibox.widget.progressbar,
--        },
--        {
--            id           = "mytb",
--            text         = "100%",
--            widget       = wibox.widget.textbox,
--        },
--        layout      = wibox.layout.stack,
--        set_battery = function(self, val)
--            self.mytb.text  = tonumber(val).."%"
--            self.mypb.value = tonumber(val)
--        end,
--    }
--
--    gears.timer {
--        timeout   = 10,
--        call_now  = true,
--        autostart = true,
--        callback  = function()
--            -- You should read it from `/sys/class/power_supply/` (on Linux)
--            -- instead of spawning a shell. This is only an example.
--            awful.spawn.easy_async(
--                {"sh", "-c", "acpi | sed -n 's/^.*, \([0-9]*\)%/\1/p'"},
--                function(out)
--                    mybatterybar.battery = out
--                end
--            )
--        end
--    }
--
-- @author Uli Schlachter
-- @copyright 2014 Uli Schlachter
-- @coreclassmod gears.timer
---------------------------------------------------------------------------

local capi = { awesome = awesome }
local ipairs = ipairs
local pairs = pairs
local setmetatable = setmetatable
local table = table
local tonumber = tonumber
local traceback = debug.traceback
local unpack = unpack or table.unpack -- luacheck: globals unpack (compatibility with Lua 5.1)
local glib = require("lgi").GLib
local object = require("gears.object")
local gtable = require("gears.table")
local protected_call = require("gears.protected_call")
local gdebug = require("gears.debug")

--- When the timer is started.
-- @signal start

--- When the timer is stopped.
-- @signal stop

--- When the timer had a timeout event.
-- @signal timeout

--- When the number of timeout reaches the value of `iterations`.
-- @signal finished
-- @see single_shot
-- @see iterations

local timer, all_timers = { mt = {} }, setmetatable({}, {__mode = "v"})

-- Get how many millisecond the timer should wait upon for the next
-- iteration. It also detect when the timer needs to be re-aligned.
local function get_next_interval(self, now, skip)
    if type(self._private.timeout) == "number" then
        return self._private.timeout * 1000
    else
        now = now or capi.awesome.mainloop_timestamp

        local next = timer._get_schedule_ts_offset(
            now,
            self._private.timeout
        )

        local next_plus_one = (not skip) and get_next_interval(self, now + next + 0.001, true)
        local multiplier = self._private.timeout.multiplier or 1

        -- Make sure it settle down on an alignment "eventualy".
        -- The timers are never very accurate, let leave a 500ms "room". Otherwise,
        -- the timer will be recomputed every single time for no reason.
        if (not skip) and math.abs(next * 1000 - next_plus_one) > 500 then
            self._private.pending_reset = next_plus_one * multiplier
        end

        -- The 1 is because we added a millisecond after the next timeout
        -- and need to substrct it here.
        local ret = math.floor(next * 1000 + (skip and 1 or 0))

        -- Apply the multiplier.
        if next_plus_one and multiplier ~= 1 and ret > next_plus_one * multiplier then
            ret = math.floor(ret % (next_plus_one * multiplier))
        end

        return ret
    end
end

local function update_stop_ts(self)
    self._private.stop_ts = timer._get_schedule_ts_offset(
        capi.awesome.mainloop_timestamp,
        self._private.stop_at
    ) * 1000

    if self._private.stop_source_id then
        glib.source_remove(self._private.stop_source_id)
    end

    if not self._private.stop_cb then
        function self._private.stop_cb()
            if self._private.stop_source_id then
                glib.source_remove(self._private.stop_source_id)
            end

            self._private.stop_source_id = nil

            self:emit_signal("finished")
            self:stop()
        end
    end

    self._private.stop_source_id = glib.timeout_add(
        glib.PRIORITY_DEFAULT,
        self._private.stop_ts,
        self._private.stop_cb
    )

end

--- Update AwesomeWM internal event loop stalling detection.
--
-- If the system goes to sleep or misses extensive time, this
-- private API ensures the next time an event loop is executed,
-- the `resumed` signal will be sent from `capi.awesome`.
local function update_wakeup()
    local least = math.huge

    for _, t in ipairs(all_timers) do
        if t._private.wake_up then
            least = math.min(least, get_next_interval(t) * 1.5)
        end
    end

    capi.awesome._suspend_threshold = least == math.huge and 0 or least
end

local function quiet_stop(self)
    glib.source_remove(self._private.source_id)
    self._private.source_id = nil
    self._private.last_wakeup = capi.awesome.mainloop_timestamp
    self._private.pending_reset = false
end

local function quiet_start(self, next)
    self._private.last_wakeup = capi.awesome.mainloop_timestamp

    next = next or get_next_interval(self)

    self._private.source_id = glib.timeout_add(
        glib.PRIORITY_DEFAULT,
        next,
        self._private.timeout_function
    )
end

local function timeout_common(self)
    self._private.last_wakeup = capi.awesome.mainloop_timestamp

    if self._private.started == false then
        self:emit_signal("start")
        self._private.started = true
    end

    self._private.count = self._private.count + 1

    protected_call(self.emit_signal, self, "timeout")

    local pending = self._private.pending_reset

    if self._private.stop_at and (pending or not self._private.stop_ts) then
        update_stop_ts(self)
    end

    if pending then
        self._private.pending_reset = false
        quiet_stop(self)
        quiet_start(self, type(pending) == "number" and pending or nil)
    end

    local it = self._private.iterations or math.huge

    if self._private.count >= it or self._private.single_shot then
        self:emit_signal("finished")
        return false
    end

    return true
end

local function resume_timers()
    for _, t in ipairs(all_timers) do
        local prev_wakeup = t._private.last_wakeup or -1

        local past_due = prev_wakeup + get_next_interval(t) < awesome.mainloop_timestamp

        if t._private.stop_ts < awesome.mainloop_timestamp then
            t:emit_signal("finished")
            t:stop()
            return
        end

        if past_due and t._private.wake_up then
            t._private.pending_reset = true
            timeout_common(t)
        end
    end
end

function timer._get_schedule_ts_offset(now, desc)
    -- GTimeVal is a struct, it has no constructor.
    local tv = glib.TimeVal()
    tv.tv_sec  = math.floor(now)
    tv.tv_usec = math.ceil(now % 1*1000)

    --local date_now = glib.DateTime.new_from_unix_local(math.ceil(now))
    local date_now = glib.DateTime.new_from_timeval_local(tv)

    -- Turn all the optional fields into a proper date.
    local date_next = glib.DateTime.new(
        date_now:get_timezone(),
        desc.year   or date_now:get_year(),
        desc.month  or date_now:get_month(),
        desc.day    or date_now:get_day_of_month(),
        desc.hour   or date_now:get_hour(),
        desc.minute or date_now:get_minute(),
        desc.second or date_now:get_second()
    )

    -- Attemot to find the next iteration if the ts is past due.
    local delta =  date_next:to_unix() - now

    if delta < 0 then
        if delta >= -60 and not desc.minute then
            date_next = date_next:add_minutes(1)
        elseif delta >= -3600 and not desc.hour then
            date_next = date_next:add_hours(1)
        elseif delta >= -3600*24 and not desc.day then
            date_next = date_next:add_days(1)
        elseif delta >= -3600*24*30 and not desc.day then
            date_next = date_next:add_months(1)
        end
    end

    -- Get the offset from now
    return date_next:to_unix() - now
end


--- Start the timer.
--
-- If there is an `initial_delay` or `start_at`, the `start` signal will
-- be emitted later.
--
-- @method start
-- @emits start
function timer:start()
    -- There is ~5 ways to start a timer. Rather than complain,
    -- just be nice and handle it internally.
    if self._private.source_id ~= nil then
        quiet_stop(self)
    end

    self._private.count = 0

    -- If there is an initial delay, honor it.
    if self._private.initial_delay then
        self._private.started = false
        self._private.pending_reset = true
        quiet_start(self, self._private.initial_delay * 1000)

        return
    elseif self._private.start_at then
        local delay = self._get_schedule_ts_offset(
            capi.awesome.mainloop_timestamp,
            self._private.start_at
        ) * 1000

        self._private.started = false
        self._private.pending_reset = true
        quiet_start(self, delay)

        return
    end

    if self._private.randomized then
        local next = get_next_interval(self) * math.random()
        self._private.pending_reset = true
        quiet_start(self, next)
    else
        quiet_start(self)
    end

    self._private.started_ts = capi.awesome.mainloop_timestamp

    self._private.started = true
    self:emit_signal("start")

    if self._private.single_shot then
        self:connect_signal("timeout", self.stop)
    end

    if self._private.wake_up then
        update_wakeup()
    end
end

--- Stop the timer.
--
-- Does nothing if the timer isn't running.
--
-- @method stop
-- @emits stop
function timer:stop()
    if self._private.source_id == nil then
        gdebug.print_error(traceback("timer not started"))
        return
    end

    quiet_stop(self)

    self:emit_signal("stop")
    self:disconnect_signal("timeout", self.stop)

    if self._private.wake_up then
        update_wakeup()
    end
end

--- Restart the timer.
-- This is equivalent to stopping the timer if it is running and then starting
-- it.
-- @method again
-- @emits start
-- @emits stop
function timer:again()
    if self._private.source_id ~= nil then
        self:stop()
    end
    self:start()
end

--- Re-align the timer.
--
-- When the `timeout` property is a date/time rather than a number
-- of milliseconds, it is possible the time will shift. This method
-- will reset the timer delay.
--
-- @method realign
function timer:realign()
    quiet_stop(self)
    quiet_start(self, get_next_interval(self))
end

--- Snooze (mute) the timer for a number of seconds.
--
-- This will not emit `timeout` before the delay.
--
-- @method snooze
-- @tparam number delay The delay (in seconds).
-- @see delay
function timer:snoonze(delay)
    if not self.started then return end

    quiet_stop(self)
    quiet_start(self, delay * 1000)
end

--- Add a delay before the next timeout.
--
-- This adds a delay to the remaining number of seconds.
--
-- @method delay
-- @tparam number delay The delay (in seconds).
-- @see snooze
function timer:delay(delay)
    if not self.started then return end

    local rem = self.remaining

    quiet_stop(self)
    quiet_start(self, (rem * 1000) + (delay * 1000))
end

--- The timer is started.
-- @property started
-- @param boolean

--- Emit "timeout" if the timer is past due when resuming.
--
-- If the computer goes to sleep, temporarely freezes or hibernates, it
-- is possible one or many `timeout` signals wont be sent. If this is
-- detected and this property is set to `true`, the `timeout` signal
-- will be emitted. Please note that AwesomeWM down not actively track
-- when the system goes to sleep for portability and resource usage
-- reasons. This property is implemented in a best-effort way.
--
-- @property wake_up
-- @tparam[opt=false] boolean wake_up
-- @propemits true false

function timer:set_wake_up(value)
    if value == self._private.wake_up then return end

    self._private.wake_up = value

    update_wakeup()

    self:emit_signal("property::wake_up", value)
end

--- The timer timeout value.
--
-- The value can be a number (in seconds). It can also be a table with
-- the following:
--
--  * **second**: Number from 0 to 59.
--  * **minute**: Number from 0 to 59.
--  * **hour**: Number from 0 to 23.
--  * **day**: Number from 1 to 31.
--  * **month**: Number between 1 and 12.
--  * **year**: Full year number (eg. 2021) starting with the current year.
--  * **multiplier**: Floating point number to divide/multiply the number of
--    seconds between 2 timeouts.
--
-- If the multiplier is lesser than one, then it will make the timeout happen
-- more often. For example, for `{second = 0, multiplier = 1/3}`, the timeout
-- will occur at `:00`, `:20`, `:40` of every minute.
--
-- If the multiplier of greater than 1, then it will happen *less* often. For
-- example, for `{ minute = 0, multiplier = 2}`, the timeout will happen every
-- 2 hours.
--
-- @property timeout
-- @param number
-- @propemits true false

function timer:get_timeout()
    return self._private.timeout
end

function timer:get_started()
    return self._private.source_id ~= nil
end

function timer:set_started(value)
    if value == self:get_started() then return end

    if value then
        self:start()
    else
        self:stop()
    end
end

function timer:set_timeout(value)
    if type(value) == "table" then
        self._private.timeout = value
    else
        self._private.timeout = tonumber(value)
    end
    self:emit_signal("property::timeout", value)
end

--- Randomize the length of the first iteration.
--
-- The delay will be between zero and `timeout`.
--
-- This option is useful to distribute the events across
-- time. For example, if there is 2 timers at 5 seconds and
-- one at 10 seconds, then 3 timeout will occur virtually at
-- the same time. If they trigger a lot of code, then it might
-- create visible latency.
--
-- Please also note that the opposite can also be resirable.
-- Bundling multiple events at the same time can improve
-- energy usage on laptops by letting them be idle for longer.
--
-- Using `randomized = true` is thus desirable for low latency
-- and `randomized = false` is better for energy efficiency.
--
-- @property randomized
-- @param boolean
-- @propemits true false

function timer:set_randomized(value)
    self._private.randomized = value
    self:emit_signal("property::randomized", value)
end

--- When the timer starts.
--
-- Note that using this property still requires something to either call
-- `:start()` or set `autostart` in the constructor. This tells when timer
-- *when* to start, not *if* it is started.
--
-- Note that setting this property will reset `initial_delay` as they are
-- both mutually exclusive.
--
-- @property start_at
-- @tparam[opt=nil] table start_at
-- @propemits true false
-- @see stop_at
-- @see initial_delay

function timer:set_start_at(value)
    if self._private.initial_delay then
        self.initial_delay = nil
    end

    self._private.start_at = value

    self:emit_signal("property::start_at", value)
end

--- When the timer stops.
--
-- @property stop_at
-- @tparam[opt=nil] table start_at
-- @propemits true false
-- @emits finished When the timer stops.
-- @see start_at
-- @see iterations

function timer:set_stop_at(value)
    self._private.stop_at = value

    self:emit_signal("property::stop_at", value)
end

--- Nunber of seconds since the timer started.
--
-- This property is read-only.
--
-- @property elapsed
-- @tparam number elapsed

function timer:get_elapsed()
    if not self.started then return 0 end

    return capi.awesome.mainloop_timestamp - self._private.started_ts
end

--- Number of seconds until the next timeout.
--
-- @property remaining
-- @tparam number remaining

function timer:get_remaining()
    if not self.started then return 0 end

    local next = get_next_interval(self)

    return next - capi.awesome.mainloop_timestamp
end

--- Number of seconds before the normal timeout cycle begins.
--
-- The value is in seconds.
--
-- Please note that setting this value does **not** start the timer.
-- `:start()` still needs to be called. Also note that setting this
-- property will reset the `start_at` property as they are mutually
-- exclusive.
--
-- @property initial_delay
-- @tparam number initial_delay
-- @propemits true false

function timer:set_initial_delay(value)
    if self._private.start_at then
        self.start_at = nil
    end

    self._private.initial_delay = value
    self:emit_signal("property::initial_delay", value)
end

--- The number of timeouts since the timer started.
--
-- Note that this property is reset each timer the timer
-- is (re)started.
--
-- @property count
-- @tparam number count

function timer:get_count()
    return self._private.count
end

--- Number of timeouts before auto-stopping.
--
-- @property iterations
-- @tparam number iterations
-- @propemits true false
-- @emits finished After the timer timeouts the `iterations` time.
-- @see single_shot
-- @see finished

function timer:set_iterations(value)
    self._private.iterations = value
    self:emit_signal("property::iterations", value)
end

--- Create a new timer object.
-- @tparam table args Arguments.
-- @tparam number args.timeout Timeout in seconds (e.g. 1.5).
-- @tparam[opt=false] boolean args.autostart Automatically start the timer.
-- @tparam[opt=false] boolean args.call_now Call the callback at timer creation.
-- @tparam[opt=false] boolean args.wake_up Track system sleep.
-- @tparam[opt=nil] function args.callback Callback function to connect to the
--  "timeout" signal.
-- @tparam[opt=false] boolean args.single_shot Run only once then stop.
-- @tparam[opt=0] number args.initial_delay The number of seconds before auto-starting
--   the timer. Note that `autostart` also needs to be set for the timer to
--   actually start.
-- @tparam[opt=false] boolean args.randomized Randomize the length of the first
--  iteration (from zero to the value of `timeout`).
--@tparam[opt=nil] number args.iterations The number of timeout before stopping
--  the timer.
-- @tparam[opt=nil] table args.start_at Wait until this time to "really" start.
-- @tparam[opt=nil] table args.stop_at Stop the timer at this time.
-- @treturn timer
-- @constructorfct gears.timer
function timer.new(args)
    args = args or {}
    local ret = object {
        enable_properties   = true,
        enable_auto_signals = true,
    }

    if args.initial_delay and args.randomized then
        gdebug.print_error(traceback(
            "`randomized` and `initial_delay` are mutually exclusive"
        ))
    end

    gtable.crush(ret, timer, true)

    rawset(ret, "_private", {
        timeout       = 0,
        single_shot   = args.single_shot or false,
        last_wakeup   = capi.awesome.mainloop_timestamp,
        wake_up       = args.wake_up or false,
        initial_delay = args.initial_delay,
        count         = 0,
        iterations    = args.iterations,
        start_at      = args.start_at,
        stop_at       = args.stop_at,
    })

    ret._private.timeout_function = function()
        return timeout_common(ret)
    end

    -- Preserve backward compatibility with Awesome 4.0-4.3 use of "data"
    -- rather then "_private".
    rawset(ret, "data", setmetatable({}, {
        __index = function(_, key)
            gdebug.deprecate(
                "gears.timer.data is deprecated, use normal properties",
                {deprecated_in=5}
            )
            return ret._private[key]
        end,
        __newindex = function(_, key, value)
            gdebug.deprecate(
                "gears.timer.data is deprecated, use normal properties",
                {deprecated_in=5}
            )
            ret._private[key] = value
        end
    }))

    table.insert(all_timers, ret)

    for k, v in pairs(args) do
        ret[k] = v
    end

    if args.autostart then
        ret:start()
    end

    if args.callback then
        if args.call_now then
            args.callback(ret)
            ret._private.count = 1
        end
        ret:connect_signal("timeout", args.callback)
    end

    return ret
end

function timer.poller(args)
    args = args or {}

    local _timer = timer.new {
        timeout = args.timeout,
        callback = args.callback,
        wake_up = true,
        autostart = true,
        single_shot = false,
        call_now = true,
        randomized = true
    }

    return _timer
end

--- Create a simple timer for calling the `callback` function continuously.
--
-- This is a small wrapper around `gears.timer`, that creates a timer based on
-- `callback`.
-- The timer will run continuously and call `callback` every `timeout` seconds.
-- It is stopped when `callback` returns `false`, when `callback` throws an
-- error or when the `:stop()` method is called on the return value.
--
-- @tparam number timeout Timeout in seconds (e.g. 1.5).
-- @tparam function callback Function to run.
-- @treturn timer The new timer object.
-- @staticfct gears.timer.start_new
-- @see gears.timer.weak_start_new
function timer.start_new(timeout, callback)
    local t = timer.new({ timeout = timeout })
    t:connect_signal("timeout", function()
        local cont = protected_call(callback)
        if not cont then
            t:stop()
        end
    end)
    t:start()
    return t
end

--- Create a simple timer for calling the `callback` function continuously.
--
-- This function is almost identical to `gears.timer.start_new`. The only
-- difference is that this does not prevent the callback function from being
-- garbage collected.
-- In addition to the conditions in `gears.timer.start_new`,
-- this timer will also stop if `callback` was garbage collected since the
-- previous run.
--
-- @tparam number timeout Timeout in seconds (e.g. 1.5).
-- @tparam function callback Function to start.
-- @treturn timer The new timer object.
-- @staticfct gears.timer.weak_start_new
-- @see gears.timer.start_new
function timer.weak_start_new(timeout, callback)
    local indirection = setmetatable({}, { __mode = "v" })
    indirection.callback = callback
    return timer.start_new(timeout, function()
        local cb = indirection.callback
        if cb then
            return cb()
        end
    end)
end

--- Trigger this timer a single time then stop.
--
-- @property single_shot
-- @tparam[opt=false] boolean single_shot
-- @propemits true false
-- @emits finished After the timer timeout once.
-- @see iterations
-- @see finished

function timer:set_single_shot(value)
    if self._private.single_shot == value then return end

    self._private.single_shot = value

    if self._private.single_shot then
        self:connect_signal("timeout", self.stop)
    else
        self:disconnect_signal("timeout", self.stop)
    end

    self:emit_signal("property::single_shot", value)
end

local delayed_calls = {}

--- Run all pending delayed calls now. This function should best not be used at
-- all, because it means that less batching happens and the delayed calls run
-- prematurely.
-- @staticfct gears.timer.run_delayed_calls_now
function timer.run_delayed_calls_now()
    for _, callback in ipairs(delayed_calls) do
        protected_call(unpack(callback))
    end
    delayed_calls = {}
end

--- Call the given function at the end of the current GLib event loop iteration.
-- @tparam function callback The function that should be called
-- @param ... Arguments to the callback function
-- @staticfct gears.timer.delayed_call
function timer.delayed_call(callback, ...)
    assert(type(callback) == "function", "callback must be a function, got: " .. type(callback))
    table.insert(delayed_calls, { callback, ... })
end

capi.awesome.connect_signal("refresh", timer.run_delayed_calls_now)
capi.awesome.connect_signal("_resumed", resume_timers)

function timer.mt.__call(_, ...)
    return timer.new(...)
end

--@DOC_object_COMMON@

return setmetatable(timer, timer.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
