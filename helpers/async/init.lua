---------------------------------------------------------------------------
--- Utilities to work with asynchronous callback-style control flow.
--
-- All callbacks must adhere to the callback signature: `function(err, values...)`.
-- The first parameter is the error value. It will be `nil` if no error ocurred, otherwise
-- the error value depends on the function that the callback was passed to.
-- If no error ocurred, an arbitrary number of return values may be received as second parameter and onward.
--
-- Depending on the particular implementation of a function that a callback is passed to, it may be possible to
-- receive non-`nil` return values, even when an error ocurred. Using such return values should be considered undefined
-- behavior, unless explicitly documented by the calling function.
--
-- @module async
-- @license GPL v3.0
---------------------------------------------------------------------------
local util = require("helpers.async.internal.util")
local pack = table.pack or function(...)
    return {...}
end
local unpack = table.unpack or unpack

local async = {}

--- Wraps a function such that it can only ever be called once.
--
-- If the returned function is called multiple times, only the first call will result
-- in the wrapped function being called. Subsequent calls will be ignored.
-- If no function is given, a noop function will be used.
--
-- @tparam[opt] function fn The function to wrap.
-- @treturn function The wrapped function or a noop.
function async.once(fn)
    if not fn then
        fn = function()
        end
    end

    local ran = false
    return function(...)
        if not ran then
            ran = true
            fn(...)
        end
        -- TODO: Decide if we want to throw/log an error when `ran == true`
    end
end

--- Turns an asynchronous function into a blocking operation.
--
-- Using coroutines, this runs a callback-style asynchronous function and blocks until it completes.
-- The function to be wrapped may only accept a single parameter: a callback function.
-- Return values passed to this callback will be returned as regular values by `wrap_sync`.
--
-- Panics that happened inside the asynchronous function will be captured and re-thrown.
--
-- @tparam function fn An asynchronous function: `function(cb)`
-- @treturn any Any return values as passed by the wrapped function
function async.wrap_sync(fn)
    local co = coroutine.create(function()
        fn(function(...)
            coroutine.yield(...)
        end)
    end)

    local ret = pack(coroutine.resume(co))
    if not ret[1] then
        error(ret[2])
    else
        table.remove(ret, 1)
        return unpack(ret)
    end
end

--- Executes a list of asynchronous functions in series.
--
-- `waterfall` accepts an arbitrary list of asynchronous functions (tasks) and calls them in series.
-- Each function waits for the previous one to finish and will be given the previous function's return values.
--
-- If an error occurs in any task, execution is stopped immediately, and the final callback is called
-- with the error value.
-- If all tasks complete successfully, the final callback will be called with the return values of the last
-- task in the list.
--
-- All tasks must adhere to the callback signature: `function(err, ...)`.
--
-- @async
-- @tparam table tasks The asynchronous tasks to execute in series.
-- @tparam function final_callback Called when all tasks have finished.
-- @treturn any The error returned by a failing task.
-- @treturn any Values as returned by the last task.
function async.waterfall(tasks, final_callback)
    final_callback = async.once(final_callback)

    -- Bail early if there is nothing to do
    if not next(tasks) then
        final_callback()
        return
    end

    local i = 0
    local _run
    local _continue

    _run = function(...)
        i = i + 1
        local task = tasks[i]
        if task then
            local args = pack(...)
            table.insert(args, _continue)
            task(unpack(args))
        else
            -- We've reached the bottom of the waterfall, time to exit
            final_callback(nil, ...)
        end
    end

    _continue = function(err, ...)
        if err then
            final_callback(err)
            return
        end

        _run(...)
    end

    _continue()
end

--- Runs all tasks in parallel and collects the results.
--
-- If any task produces an error, `final_callback` will be called immediately
-- and remaining tasks will not be tracked.
--
-- @async
-- @tparam table tasks A list of asynchronous functions. They will be given a
--  callback parameter: `function(err, ...)`.
-- @tparam function final_callback
function async.all(tasks, final_callback)
    final_callback = async.once(final_callback)

    local len = #tasks
    if len == 0 then
        final_callback()
        return
    end

    local results = {}
    local done = 0
    local cancelled = false

    for i, task in ipairs(tasks) do
        task(function(err, ...)
            if cancelled then
                return
            end

            if err then
                cancelled = true
                final_callback(err)
                return
            end

            done = done + 1
            results[i] = pack(...)

            if done == len then
                final_callback(nil, results)
            end
        end)
    end
end

--- Resolves a DAG (Directed Acyclic Graph) of asynchronous dependencies.
--
-- The task list is a key-value map, where the key defines the task name and the value the is the task definition.
-- A task definition consists of a a list of dependencies (which may be empty) and an asynchronous
-- function.
-- Any task name may be used as dependency for any other task, as long as no loops are created.
-- A task's function will be called once all of its dependencies have become available and will be passed a `results`
-- table that contains the values returned by all tasks so far.
--
-- If any tasks passes an error to its callback, execution and tracking for all other tasks stops and `final_callback`
-- is called with that error value. Otherwise, `final_callback` will be called once all tasks have completed, with the
-- results of all tasks.
--
-- The `results` table uses the task name as key and provides a `table.pack`ed list of task results as value.
--
-- <%EXAMPLE_dag%>
--
-- @async
-- @tparam table tasks A map of asynchronous tasks.
-- @tparam function final_callback
-- @treturn any Any error from a failing task.
-- @treturn table Results of all resolved tasks.
function async.dag(tasks, final_callback)
    final_callback = async.once(final_callback)

    -- Short-circuit if there is nothing to do.
    -- To provide consistent API, pass a `results` table
    if not next(tasks) then
        final_callback(nil, {})
        return
    end

    local results = {}
    local queue = {}
    local queue_len = 0
    local running = 0
    local pending = {}
    local cancelled = false

    local _run_queue

    local function _enqueue(name, fn)
        if queue[name] then
            error(string.format("task with name '%s' already in queue", name))
            return
        end

        queue[name] = fn
        queue_len = queue_len + 1
        -- When queued for execution, it is no longer waiting for dependencies
        pending[name] = nil
    end

    local function _initialize(name, task)
        -- Short-circuit for tasks without dependencies
        if type(task) == "function" then
            _enqueue(name, task)
            return
        elseif #task == 1 then
            _enqueue(name, task[1])
            return
        end

        local dependencies = util.slice(task, 1, -1)
        local ready = util.all(dependencies, function(name)
            return results[name] ~= nil
        end)

        if ready then
            _enqueue(name, task[#task])
        else
            pending[name] = task
        end
    end

    local function _check_pending(tasks)
        for name, task in pairs(tasks) do
            _initialize(name, task)
        end

        -- When there are tasks waiting for dependencies, but none in the queue
        -- and none actively running, we must have reached a deadlock
        if queue_len == 0 and running == 0 and next(pending) then
            local err = "deadlock detected. the following tasks are waiting for dependencies: "
            for name in pairs(pending) do
                err = err .. string.format(" %s", name)
            end
            error(err)
            return
        end

        _run_queue()
    end

    _run_queue = function()
        -- `pairs` is not thread safe, so to avoid a race condition when this is used
        -- with multi-threaded concurrency, the queue has to be copied.
        local tasks = queue
        queue = {}

        for name, fn in pairs(tasks) do
            tasks[name] = nil
            queue_len = queue_len - 1
            running = running + 1

            fn(results, function(err, ...)
                if cancelled then
                    -- Another, concurrent task already finished with an error
                    return
                elseif err then
                    cancelled = true
                    final_callback(err, results)
                    return
                end

                results[name] = pack(...)
                running = running - 1

                -- If all lists are empty, we must have run all tasks
                if queue_len == 0 and running == 0 and not next(pending) then
                    final_callback(nil, results)
                else
                    _check_pending(pending)
                end
            end)
        end
    end

    _check_pending(tasks)
end

--- Repeatedly calls `test` and `iteratee` until stopped.
--
-- `iteratee` is called repeatedly. It is passed a callback
-- (`function(err, ...)`), which should be called with either an error or any
-- results of the iteration.
--
-- `test` is called once per iteration, after `iteratee`. It is passed a
-- callback (`function(err, stop)`) and any non-error values from `iteratee`.
-- The callback should be called with either an error or a boolean value.
-- Iteration will stop when an error is passed by either callback or when
-- `test` passes a falsy value.
--
-- In either case `final_callback` will be called with the latest results from
-- `iteratee`.
--
-- This is, in concept, analogous to a `do {} while ()` construct, where `iteratee`
-- is the `do` block and `test` is the `while` test.
--
-- @async
-- @tparam function iteratee Called repeatedly. Signature: `function(cb)`.
-- @tparam function test Called once per iteration, after `iteratee`.
--  Signature: `function(..., cb)`.
-- @tparam function final_callback Called once, when `test` indicates to stop
--  the iteration.
-- @treturn any Any error from `iteratee` or `test`.
-- @treturn any Values passed by the most recent execution of `iteratee`.
function async.do_while(iteratee, test, final_callback)
    final_callback = async.once(final_callback)
    local results = {}
    local _next

    -- Wraps `test` to break on errors and capture results, where `results` are what
    -- the `iteratee` passed to its callback.
    local function _test(err, ...)
        if err then
            return final_callback(err)
        end

        results = pack(...)
        local args = pack(...)
        table.insert(args, _next)
        test(unpack(args))
    end

    -- Calls `iteratee` for the next iteration, unless stopped
    _next = function(err, continue)
        if err then
            return final_callback(err)
        end

        if not continue then
            return final_callback(nil, unpack(results))
        end

        iteratee(_test)
    end

    iteratee(_test)
end

--- Wrap a function with arguments for use as callback.
--
-- This may be used to wrap a function or table method as a callback, providing a (partial)
-- argument list.
-- Arguments to this call are passed through to the provided function when it is called,
-- arguments from the final caller are appended after those.
--
-- If the function is actually a method (i.e. it expects a `self` parameter or is called with `:`),
-- the `self` table can be passed as the first argument. Otherwise, `nil` should be passed.
--
-- @todo Optimize the common use cases of only having a few outer arguments
-- by hardcoding those cases.
--
-- @tparam[opt] table object The object to call the method on.
-- @tparam function fn The function to wrap.
-- @tparam any ... Arbitrary arguments to pass through to the wrapped function.
-- @treturn function
function async.callback(object, fn, ...)
    local outer = pack(...)

    return function(...)
        local inner = pack(...)
        -- Merge, then unpack both argument lists to provide a single var arg.
        local args = {object}
        util.append(args, outer)
        util.append(args, inner)
        return fn(unpack(args))
    end
end

return async
