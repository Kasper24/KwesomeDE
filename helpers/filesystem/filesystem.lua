---------------------------------------------------------------------------
--- File system and directory operation utilities.
--
-- @module filesystem
-- @license GPL v3.0
---------------------------------------------------------------------------
local lgi = require("lgi")
local GLib = lgi.GLib
local Gio = lgi.Gio
local gtimer = require("gears.timer")
local File = require("helpers.filesystem.file")
local async = require("helpers.async")
local debug = debug
local os = os
local capi = {
    awesome = awesome
}

local filesystem = {}

local function file_arg(arg)
    if type(arg) == "string" then
        return Gio.File.new_for_path(arg)
    elseif File.is_instance(arg) then
        return arg._private.f
    else
        return arg
    end
end

--- Creates a directory at the given path.
--
-- This only creates the child directory of the immediate parent of `path`. If the parent
-- directory doesn't exist, this operation will fail.
--
-- @since 0.2.0
-- @async
-- @tparam string|File|Gio.File path
-- @tparam function cb
-- @treturn[opt] GLib.Error
function filesystem.make_directory(path, cb)
    local f = file_arg(path)

    if cb == nil then
        cb = function()
        end
    end

    f:make_directory_async(GLib.PRIORITY_DEFAULT, nil, function(_, token)
        local _, err = f:make_directory_finish(token)
        cb(err)
    end)
end

--- Iterates the contents of a directory.
--
-- The `iteratee` callback is called once for every entry in the given directory, passing a
-- [Gio.FileInfo](https://docs.gtk.org/gio/class.FileInfo.html) as argument.
-- It's callback argument only expects a single error parameter.
--
-- If `options.recursive == true`, iteration will recurse into subdirectories.
-- `options.list_directories` can be used to have `iteratee` not be called on directory entries.
--
-- On error, either within the iteration or passed by `iteratee`, iteration is aborted and
-- the final callback is called.
--
-- See @{file:query_info} and [g_file_query_info](https://docs.gtk.org/gio/method.File.query_info.html) for
-- information on the `attributes` parameter.
--
-- @since 0.2.0
-- @async
-- @tparam string|File|Gio.File dir The directory to query contents for.
-- @tparam function iteratee The iterator function that will be called for each entry.
-- The function will be called with a `Gio.FileInfo` and a callback: `function(info, cb)`.
-- @tparam table options
-- @tparam[opt="standard::type"] string options.attributes The attributes to query.
-- @tparam[opt=false] boolean options.recursive Recurse into directories.
-- @tparam[opt=true] boolean options.list_directories If `false`, directories will not trigger `iteratee`.
-- @tparam function cb
-- @treturn[opt] GLib.Error
function filesystem.iterate_contents(dir, iteratee, options, cb)
    if type(options) == "function" then
        cb = options
        options = {}
    end

    options = options or {}

    local attributes = options.attributes or "standard::type"

    local priority = GLib.PRIORITY_DEFAULT
    local BUFFER_SIZE = 50
    local f = file_arg(dir)

    local outer_cb = cb or function()
    end

    async.dag({
        enumerator = function(_, cb)
            f:enumerate_children_async(attributes, Gio.FileQueryInfoFlags.NONE, priority, nil, function(_, token)
                local enumerator, err = f:enumerate_children_finish(token)
                cb(err, enumerator)
            end)
        end,
        iterate = {"enumerator", function(results, cb)
            local enumerator = table.unpack(results.enumerator)

            -- `next_files_async` reports errors in a two-step system. In the event of an error,
            -- the ongoing call will still succeed and report all files that had been queried
            -- successfully. The function then expects to be called again, to return the error.

            local function iterate(cb_iterate)
                enumerator:next_files_async(BUFFER_SIZE, priority, nil, function(_, token)
                    local infos, err = enumerator:next_files_finish(token)

                    if err or #infos == 0 then
                        return cb_iterate(err, infos)
                    end

                    local tasks = {}

                    for index, info in ipairs(infos) do
                        local path = string.format("%s/%s", f:get_path(), info:get_name())
                        local f = File.new_for_path(path)

                        if Gio.FileType[info:get_file_type()] == Gio.FileType.DIRECTORY then
                            if options.list_directories ~= false then
                                table.insert(tasks, async.callback(nil, iteratee, info))
                            end

                            table.insert(tasks, async.callback(f, filesystem.iterate_contents, iteratee, options))
                        else
                            table.insert(tasks, async.callback(nil, iteratee, info))
                        end

                        if index == #infos then
                            outer_cb()
                        end
                    end

                    async.all(tasks, function(err)
                        cb_iterate(err, infos)
                    end)
                end)
            end

            local function check(infos, cb_check)
                cb_check(nil, #infos > 0)
            end

            async.do_while(iterate, check, function(err)
                cb(err)
            end)
        end}
    }, function(err, results)
        local enumerator = table.unpack(results.enumerator)

        enumerator:close_async(priority, nil, function(_, token)
            local _, err_inner = enumerator:close_finish(token)

            -- If the enumerator was already closed, we can ignore the error.
            if err and err.code == Gio.IOErrorEnum[Gio.IOErrorEnum.CLOSED] then
                err_inner = nil
            end

            cb(err or err_inner)
        end)
    end)
end

--- Lists the contents of a directory.
--
-- See @{file:query_info} and [g_file_query_info](https://docs.gtk.org/gio/method.File.query_info.html) for
-- information on the `attributes` parameter.
--
-- @since 0.2.0
-- @async
-- @tparam string|File|Gio.File dir The directory to query contents for.
-- @tparam string attributes The attributes to query.
-- @tparam function cb
-- @treturn[opt] GLib.Error
-- @treturn table A list of `Gio.FileInfo`s
function filesystem.list_contents(dir, attributes, cb)
    if type(attributes) == "function" then
        cb = attributes
        attributes = "standard::type"
    end

    local priority = GLib.PRIORITY_DEFAULT
    -- TODO: Benchmark for an efficient size
    local BUFFER_SIZE = 50
    local f = file_arg(dir)

    async.dag({
        enumerator = function(_, cb)
            f:enumerate_children_async(attributes, Gio.FileQueryInfoFlags.NONE, priority, nil, function(_, token)
                local enumerator, err = f:enumerate_children_finish(token)
                cb(err, enumerator)
            end)
        end,
        list = {"enumerator", function(results, cb)
            local enumerator = table.unpack(results.enumerator)
            local list = {}

            -- `next_files_async` reports errors in a two-step system. In the event of an error,
            -- the ongoing call will still succeed and report all files that had been queried
            -- successfully. The function then expects to be called again, to return the error.

            local function iterate(cb_iterate)
                enumerator:next_files_async(BUFFER_SIZE, priority, nil, function(_, token)
                    local infos, err = enumerator:next_files_finish(token)

                    if infos and #infos > 0 then
                        for _, info in ipairs(infos) do
                            table.insert(list, info)
                        end
                    end

                    cb_iterate(err, infos)
                end)
            end

            local function check(infos, cb_check)
                cb_check(nil, #infos > 0)
            end

            async.do_while(iterate, check, function(err)
                cb(err, list)
            end)
        end}
    }, function(err, results)
        local enumerator = table.unpack(results.enumerator)
        local list = results.list and table.unpack(results.list)

        enumerator:close_async(priority, nil, function(_, token)
            local _, err_inner = enumerator:close_finish(token)

            -- If the enumerator was already closed, we can ignore the error.
            if err and err.code == Gio.IOErrorEnum[Gio.IOErrorEnum.CLOSED] then
                err_inner = nil
            end

            cb(err or err_inner, list)
        end)
    end)
end

--- Recursively removes a directory and its contents.
--
-- @since 0.2.0
-- @async
-- @tparam string|File|Gio.File dir The directory to remove.
-- @tparam function cb
-- @treturn[opt] GLib.Error
function filesystem.remove_directory(dir, cb)
    local priority = GLib.PRIORITY_DEFAULT
    local f = file_arg(dir)
    local BUFFER_SIZE = 50

    if cb == nil then
        cb = function()
        end
    end

    async.dag({
        enumerator = function(_, cb)
            f:enumerate_children_async("standard::type", Gio.FileQueryInfoFlags.NONE, priority, nil, function(_, token)
                local enumerator, err = f:enumerate_children_finish(token)
                cb(err, enumerator)
            end)
        end,
        iterate = {"enumerator", function(results, cb)
            local enumerator = table.unpack(results.enumerator)

            local function iterate(cb_iterate)
                enumerator:next_files_async(BUFFER_SIZE, priority, nil, function(_, token)
                    local infos, err = enumerator:next_files_finish(token)

                    if err or #infos == 0 then
                        return cb(err, infos)
                    end

                    local tasks = {}

                    for _, info in ipairs(infos) do
                        local path = string.format("%s/%s", f:get_path(), info:get_name())
                        local f = File.new_for_path(path)

                        if Gio.FileType[info:get_file_type()] == Gio.FileType.DIRECTORY then
                            table.insert(tasks, async.callback(f, filesystem.remove_directory))
                        else
                            table.insert(tasks, async.callback(f, f.delete))
                        end
                    end

                    async.all(tasks, cb_iterate)
                end)
            end

            local function check(infos, cb_check)
                cb_check(nil, #infos > 0)
            end

            async.do_while(iterate, check, cb)
        end},
        delete = {"iterate", function(_, cb)
            f:delete_async(priority, nil, function(_, token)
                local _, err = f:delete_finish(token)
                cb(err)
            end)
        end}
    }, function(err, results)
        local enumerator = table.unpack(results.enumerator)

        enumerator:close_async(priority, nil, function(_, token)
            local _, err_inner = enumerator:close_finish(token)

            -- If the enumerator was already closed, we can ignore the error.
            if err and err.code == Gio.IOErrorEnum[Gio.IOErrorEnum.CLOSED] then
                err_inner = nil
            end

            cb(err or err_inner)
        end)
    end)
end


local function download(file, uri, callback)
    local remote_file = File.new_for_uri(uri)

    remote_file:read(function(error, content)
        if error == nil then
            file:write(content)
            callback(content)
        end
    end)
end


function filesystem.remote_watch(path, uri, interval, callback, old_content_callback)
    local file = File.new_for_path(path)

    local timer = gtimer.poller {
        timeout = interval
    }

    timer:connect_signal("timeout", function()
        file:read_string(function(error, old_content)
            if error == nil then
                if old_content_callback ~= nil then
                    old_content_callback(old_content)
                end

                file:query_info("time::modified", function(error, info)
                    if error == nil then
                        local time = info:get_modification_date_time()
                        local diff = math.ceil(GLib.DateTime.new_now_local():difference(time) / 1000000)
                        -- print("diff: " .. diff .. " interval: " .. interval)

                        if diff >= interval then
                            print("Enough time had passed, redownloading " .. path)
                            download(file, uri, callback)
                        else
                            callback(old_content)

                            -- Schedule an update for when the remaining time to complete the interval passes
                            timer.timeout = interval - diff
                        end
                    end
                end)
            else
                print(path .. " doesn't exist, downloading " .. uri)
                download(file, uri, callback)
            end
        end)
    end)

    timer:emit_signal("timeout")
end

function filesystem.get_xdg_cache_home(sub_folder)
    return (os.getenv("XDG_CACHE_HOME") or os.getenv("HOME") .. "/.cache") .. "/" .. sub_folder .. "/"
end

function filesystem.get_cache_dir(sub_folder)
    return (os.getenv("XDG_CACHE_HOME") or os.getenv("HOME") .. "/.cache") .. "/awesome/" .. sub_folder .. "/"
end

function filesystem.get_awesome_config_dir(sub_folder)
    return (capi.awesome.conffile:match(".*/") or "./") .. sub_folder .. "/"
end
function filesystem.get_script_path(sub_folder)
    return debug.getinfo(1).source:match("@?(.*/)") .. sub_folder
end

return filesystem
