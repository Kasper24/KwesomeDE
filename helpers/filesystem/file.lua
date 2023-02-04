---------------------------------------------------------------------------
--- High level file handling library.
--
-- A file handle can be created through one of the constructor functions. File
-- operations are performed on that handle.
--
-- Example to write and read-back a file:
--
--    local lgi = require("lgi")
--    local File = require("lgi-async-extra.file")
--    local path = "%s/foo.txt":format(lgi.GLib.get_tmp_dir())
--    local f = File.new_for_path(path)
--    async.waterfall({
--        function(cb)
--            -- By default, writing replaces any existing content
--            f:write("hello", cb)
--        end,
--        function(cb)
--            -- But we can also append to the file
--            f:write("world", "append", cb)
--        end,
--        function(cb)
--            f:read_string(cb)
--        end,
--    }, function(err, data)
--        print(err)
--        print(data)
--    end)
--
-- @module file
-- @license GPL v3.0
---------------------------------------------------------------------------
local async = require("helpers.async")
local lgi = require("lgi")
local Gio = lgi.Gio
local GLib = lgi.GLib
local GFile = Gio.File
local awful = require("awful")

local stream_utils = require("helpers.filesystem.stream")

-- Class marker
local FILE_CLASS_MARKER = setmetatable({}, {
    __newindex = function()
    end,
    __tostring = "File"
})

local File = {
    class = FILE_CLASS_MARKER
}
local file = {}

--- Constructors
-- @section constructors

--- Create a file handle for the given local path.
--
-- This is a cheap operation, that only creates an in memory representation of the resource location.
-- No I/O will take place until a corresponding method is called on the returned `File` object.
--
-- @tparam string path
-- @treturn File
function file.new_for_path(path)
    local f = GFile.new_for_path(path)
    local ret = {
        _private = {
            f = f,
            path = path
        }
    }
    return setmetatable(ret, {
        __index = File
    })
end

--- Create a file handle for the given remote URI.
--
-- This is a cheap operation, that only creates an in memory representation of the resource location.
-- No I/O will take place until a corresponding method is called on the returned `File` object.
--
-- @tparam string uri
-- @treturn File
function file.new_for_uri(uri)
    local f = GFile.new_for_uri(uri)
    local ret = {
        _private = {
            f = f,
            path = uri
        }
    }
    return setmetatable(ret, {
        __index = File
    })
end

--- Create a new file in a directory preferred for temporary storage.
--
-- If `template` is given, it must contain a sequence of six `X`s somewhere in the string, which
-- will replaced by a unique ID to ensure the new file does not overwrite existing ones. The template must not contain
-- any directory components.
-- If `template == nil`, a default value will be used.
--
-- The directory is determined by [g_get_tmp_dir](https://docs.gtk.org/glib/func.get_tmp_dir.html).
--
-- The second return value is a `Gio.FileIOStream`, which contains both an input and output stream to the created
-- file. The caller is responsible for closing these streams.
--
-- The third return value will be an instance of `GLib.Error` if the attempt to create the file failed. If this
-- is not `nil`, attempts to access the other return values will result in undefined behavior.
--
-- See [docs.gtk.org](https://docs.gtk.org/gio/type_func.File.new_tmp.html) for additional details.
--
-- @tparam[opt=".XXXXXX"] string template
-- @treturn File
-- @treturn GIO.FileIOStream
-- @treturn[opt] GLib.Error
function file.new_tmp(template)
    local f, stream, err = GFile.new_tmp(template)
    local ret = {
        _private = {
            f = f,
            template = template
        }
    }
    return setmetatable(ret, {
        __index = File
    }), stream, err
end

--- Static functions
-- @section static_functions

--- Checks if a table is an instance of @{file}.
--
-- @since 0.2.0
-- @usage local File = require("lgi-async-extra.file")
-- local f = File.new_for_path("/tmp/foo.txt")
-- assert(File.is_instance(f))
-- @tparam table f The value to check.
-- @treturn boolean
function file.is_instance(f)
    return type(f) == "table" and f.class == FILE_CLASS_MARKER
end

--- @type file

--- Creates a final callback to pass results and clean up the file stream.
--
-- This is intended to be passed as `final_callback` parameter for an `async.dag` where a Gio stream was
-- opened at index `stream`.
-- The `result_index` parameter is required to be set. If no result should be passed, provide `nil`.
--
-- @tparam nil|string result_index Index into the `async.dag` results table.
-- @tparam[opt="stream"] string stream_index Index into the `async.dag` results table.
-- @tparam function cb The callback to proxy
-- @treturn function
local function clean_up_stream(result_index, stream_index, cb)
    if type(stream_index) == "function" then
        cb = stream_index
        stream_index = "stream"
    end

    return function(err, results)
        local result
        if result_index and results[result_index] then
            result = table.unpack(results[result_index])
        end

        if not results[stream_index] then
            return cb(err, result)
        end

        -- Make sure to always close the stream, even if the read operation failed.
        local stream = table.unpack(results[stream_index])
        stream:close_async(GLib.PRIORITY_DEFAULT, nil, function(_, token)
            local _, err_inner = stream:close_finish(token)
            -- Prioritize the outer error (from the read operation), as the inner error (closing the stream) may be
            -- a result of that.
            cb(err or err_inner, result)
        end)
    end
end

--- Get the file's path name.
--
-- The path is guaranteed to be absolute, by may contain unresolved symlinks.
-- However, a path may not exist, in which case `nil` will be returned.
--
-- @since 0.2.0
-- @treturn[opt] string
function File:get_path()
    return self._private.f:get_path()
end

--- Open a read stream.
--
-- The consumer is responsible for properly closing the stream:
--
--    stream:close_async(GLib.PRIORITY_DEFAULT, nil, function(_, token)
--        local _, err = stream:close_finish(token)
--        cb(err)
--    end)
--
-- A [GDataInputStream](https://docs.gtk.org/gio/class.DataInputStream.html) adds additional reading utilities:
--
--    stream = Gio.DataInputStream.new(stream)
--
-- @async
-- @tparam function cb
-- @treturn[opt] GLib.Error
-- @treturn[opt] Gio.FileInputStream
function File:read_stream(cb)
    local f = self._private.f

    f:read_async(GLib.PRIORITY_DEFAULT, nil, function(_, token)
        local stream, err = f:read_finish(token)
        cb(err, stream)
    end)
end

--- Open a write stream.
--
-- Write operations are buffered, so the stream needs to be flushed (or closed)
-- to be sure that changes are written to disk. Especially in `replace` mode,
-- reading before flushing will yield stale content.
--
-- The consumer is responsible for properly closing the stream:
--
--    stream:close_async(GLib.PRIORITY_DEFAULT, nil, function(_, token)
--        local _, err = stream:close_finish(token)
--        cb(err)
--    end)
--
-- @async
-- @tparam[opt="replace"] string mode Either `"append"` or `"replace"`.
--  `"replace"` will truncate the file before writing, `"append"` will keep
--  any existing content and add the new data at the end.
-- @tparam function cb
-- @treturn[opt] GLib.Error
-- @treturn Gio.FileOutputStream
function File:write_stream(mode, cb)
    local f = self._private.f
    local priority = GLib.PRIORITY_DEFAULT

    if type(mode) == "function" then
        cb = mode
        mode = nil
    end

    if mode == "append" then
        f:append_to_async(Gio.FileCreateFlags.NONE, priority, nil, function(_, token)
            local stream, err = f:append_to_finish(token)
            cb(err, stream)
        end)
    else
        f:replace_async(nil, false, Gio.FileCreateFlags.NONE, priority, nil, function(_, token)
            local stream, err = f:replace_finish(token)
            cb(err, stream)
        end)
    end
end

--- Write the data to the opened file.
--
-- @async
-- @tparam string data The data to write.
-- @tparam[opt="replace"] string mode Either `"append"` or `"replace"`.
--  `"replace"` will truncate the file before writing, `"append"` will keep
--  any existing content and add the new data at the end.
-- @tparam function cb
-- @treturn[opt] GLib.Error
function File:write(data, mode, cb)
    local priority = GLib.PRIORITY_DEFAULT

    -- Make parent directories
    -- make_directory_with_parents is blocking
    -- and gio provides no other easy way to do this
    -- so shelling out
    local parent = self._private.f:get_parent():get_path()
    awful.spawn.easy_async(string.format("mkdir -p %s", parent), function()
        if type(mode) == "function" then
            cb = mode
            mode = nil
        end

        -- Stop it from complaing since I don't always need a cb
        if cb == nil then
            cb = function()
            end
        end

        async.dag({
            stream = function(_, cb_inner)
                self:write_stream(mode, cb_inner)
            end,
            write = {"stream", function(results, cb_inner)
                local stream = table.unpack(results.stream)

                stream:write_all_async(data, priority, nil, function(_, token)
                    local _, _, err = stream:write_all_finish(token)
                    cb_inner(err)
                end)
            end}
        }, clean_up_stream(nil, cb))
    end)
end

--- Read at most the specified number of bytes from the file.
--
-- If there is not enough data to read, the result may contain less than `size` bytes of data.
--
-- @since 0.2.0
-- @async
-- @tparam number size The number of bytes to read.
-- @tparam function cb The callback to call when reading finished.
--   Signature: `function(err, data)`
-- @treturn[opt] GLib.Error An instance of `GError` if there was an error,
--   `nil` otherwise.
-- @treturn GLib.Bytes
function File:read_bytes(size, cb)
    local priority = GLib.PRIORITY_DEFAULT

    async.dag({
        stream = function(_, cb_inner)
            self:read_stream(cb_inner)
        end,
        bytes = {"stream", function(results, cb_inner)
            local stream = table.unpack(results.stream)

            stream:read_bytes_async(size, priority, nil, function(_, token)
                local bytes, err = stream:read_bytes_finish(token)
                cb_inner(err, bytes)
            end)
        end}
    }, clean_up_stream("bytes", cb))
end

--- Read the entire file's content into memory.
--
-- This collects the content into a Lua @{string}, so text files an be used as-is.
-- For binary content, use @{string.byte} to access the raw values or manually wrap the result of
-- @{file:read_stream} in a [Gio.DataInputStream](https://docs.gtk.org/gio/class.DataInputStream.html) and
-- read individual values based on their binary size.
--
-- @since 0.2.0
-- @async
-- @tparam function cb The callback to call when reading finished.
--   Signature: `function(err, data)`
-- @treturn[opt] GLib.Error An instance of `GError` if there was an error,
--   `nil` otherwise.
-- @treturn[opt] string A string read from the file.
function File:read_string(cb)
    async.dag({
        stream = function(_, cb_inner)
            self:read_stream(cb_inner)
        end,
        string = {"stream", function(results, cb_inner)
            local stream = table.unpack(results.stream)
            stream_utils.read_string(stream, cb_inner)
        end}
    }, clean_up_stream("string", cb))
end

-- Read string fails to correctly read some files
function File:read(cb)
    local f = self._private.f
    f:load_contents_async(nil, function(_, task, __)
        local content = f:load_contents_finish(task)
        local err = (content == false) and true or nil
        cb(err, content)
    end)
end

--- Read a line from the file.
--
-- Like all other operations, this always reads from the beginning of the file. Calling this function
-- repeatedly on the same file will always yield the first line.
--
-- To iterate over all lines, use @{file:iterate_lines}. To read more than just one line, use @{file:read_bytes} or
-- @{file:read_string}.
--
-- @async
-- @tparam function cb
-- @treturn[opt] GLib.Error An instance of `GError` if there was an error,
--   `nil` otherwise.
-- @treturn[opt] string A string read from the file,
--   or `nil` if the end was reached.
function File:read_line(cb)
    local priority = GLib.PRIORITY_DEFAULT

    async.dag({
        stream = function(_, cb_inner)
            self:read_stream(cb_inner)
        end,
        line = {"stream", function(results, cb_inner)
            local stream = table.unpack(results.stream)
            stream = Gio.DataInputStream.new(stream)

            stream:read_line_async(priority, nil, function(_, token)
                local line, _, err = stream:read_line_finish(token)
                cb_inner(err, line)
            end)
        end}
    }, clean_up_stream("line", cb))
end

--- Asynchronously iterate over the file line by line.
--
-- This function opens a read stream and starts reading the file line-wise,
-- asynchronously. For every line read, the given `iteratee` is called with any
-- potential error, the line's content (without the trailing newline)
-- and a callback function. The callback must always be called to ensure the
-- file handle is cleaned up eventually. The expected signature for the callback
-- is `cb(err, stop)`. If `err ~= nil` or a value for `stop` is given, iteration stops
-- immediately and `cb` will be called.
--
-- Changed 0.2.0: Renamed from `read_lines`.
--
-- @since 0.2.0
-- @async
-- @tparam function iteratee Function to call per line in the file. Signature:
--   `function(err, line, cb)`
-- @tparam function cb Function to call when iteration has stopped.
--   Signature: `function(err)`.
function File:iterate_lines(iteratee, cb)
    local priority = GLib.PRIORITY_DEFAULT

    async.dag({
        stream = function(_, cb_inner)
            self:read_stream(cb_inner)
        end,
        lines = {"stream", function(results, cb_inner)
            local stream = table.unpack(results.stream)
            stream = Gio.DataInputStream.new(stream)

            local function read_line(cb_line)
                stream:read_line_async(priority, nil, function(_, token)
                    local line, _, err = stream:read_line_finish(token)

                    iteratee(err, line, function(err, stop)
                        cb_line(err, stop or false, line)
                    end)
                end)
            end

            local function check(stop, line, cb_check)
                if type(line) == "function" then
                    cb_check = line
                    line = nil
                end

                local continue = (not stop) and (line ~= nil)
                cb_check(nil, continue)
            end

            async.do_while(read_line, check, function(err)
                cb_inner(err)
            end)
        end}
    }, clean_up_stream(nil, cb))
end

--- Move the file to a new location.
--
-- Due to limitations in GObject Introspection, this can currently only be implemented as
-- "copy and delete" operation.
--
-- @since 0.3.0
-- @async
-- @tparam string|file path New path to move to.
-- @tparam function cb
-- @treturn[opt] GLib.Error
function File:move(path, cb)
    async.waterfall({function(cb)
        self:copy(path, {
            recursive = true
        }, cb)
    end, function(cb)
        self:delete(cb)
    end}, function(err)
        cb(err)
    end)
end

local function _file_copy_impl(self, dest, options, cb)
    async.dag({
        check_overwrite = function(_, cb)
            if options.overwrite then
                return cb(nil)
            end

            dest:exists(function(err, exists)
                if not err and exists then
                    err = GLib.Error(Gio.IOErrorEnum, Gio.IOErrorEnum.EXISTS, "Destination exists already")
                end

                cb(err)
            end)
        end,
        out_stream = {"check_overwrite", function(_, cb)
            dest:write_stream("replace", cb)
        end},
        in_stream = {"check_overwrite", function(_, cb)
            self:read_stream(cb)
        end},
        splice = {"out_stream", "in_stream", function(results, cb)
            local in_stream = table.unpack(results.in_stream)
            local out_stream = table.unpack(results.out_stream)
            local flags = {Gio.OutputStreamSpliceFlags.CLOSE_SOURCE, Gio.OutputStreamSpliceFlags.CLOSE_TARGET}

            out_stream:splice_async(in_stream, flags, GLib.PRIORITY_DEFAULT, nil, function(_, token)
                local _, err = out_stream:splice_finish(token)
                cb(err)
            end)
        end}
    }, function(err)
        cb(err)
    end)
end

--- Copies the file to a new location.
--
-- @since 0.3.0
-- @async
-- @tparam string|file dest_path Path to copy to.
-- @tparam table options
-- @tparam boolean recursive Copy directory contents recursively.
-- @tparam boolean overwrite Overwrite files at the destination path.
-- @tparam function cb
-- @treturn[opt] GLib.Error
function File:copy(dest_path, options, cb)
    local dest = dest_path
    if type(dest) == "string" then
        dest = file.new_for_path(dest_path)
    end

    cb = cb or function()
    end
    options = options or {}

    if not options.recursive then
        return _file_copy_impl(self, dest, options, cb)
    end

    async.dag({
        file_type = function(_, cb)
            self:type(cb)
        end,
        copy = {"file_type", function(results, cb)
            local file_type = table.unpack(results.file_type)

            if file_type ~= Gio.FileType.DIRECTORY then
                return _file_copy_impl(self, dest, options, cb)
            elseif not options.recursive then
                local err = GLib.Error(Gio.IOErrorEnum, Gio.IOErrorEnum.IS_DIRECTORY,
                    "Directories can only be copied recursively")
                return cb(err)
            end

            local filesystem = require("helpers.filesystem.filesystem")
            local path = self:get_path()

            local function iteratee(info, cb)
                local child = file.new_for_path(string.format("%s/%s", path, info:get_name()))
                local child_dest = file.new_for_path(string.format("%s/%s", dest_path, info:get_name()))
                child:copy(child_dest, options, cb)
            end

            filesystem.iterate_contents(path, iteratee, cb)
        end}
    }, function(err)
        cb(err)
    end)
end

--- Delete the file.
--
-- This has the same semantics as POSIX `unlink()`, i.e. the link at the given
-- path is removed. If it was the last link to the file, the disk space occupied
-- by that file is freed as well.
--
-- Empty directories are deleted by this as well.
--
-- @async
-- @tparam function cb
-- @treturn[opt] GLib.Error
function File:delete(cb)
    local f = self._private.f
    local priority = GLib.PRIORITY_DEFAULT

    f:delete_async(priority, nil, function(_, token)
        local _, err = f:delete_finish(token)
        cb(err)
    end)
end

--- Move the file to trash.
--
-- Support for this depends on the platform and file system. If unsupported
-- an error of type `Gio.IOErrorEnum.NOT_SUPPORTED` will be returned.
--
-- @async
-- @tparam function cb
-- @treturn[opt] GLib.Error
function File:trash(cb)
    local f = self._private.f
    local priority = GLib.PRIORITY_DEFAULT

    f:trash_async(priority, nil, function(_, token)
        local _, err = f:trash_finish(token)
        cb(err)
    end)
end

--- Query file information.
--
-- This can be used to query for any file info attribute supported by GIO.
-- The attribute parameter may either be plain string, such as `"standard::size"`, a wildcard `"standard::*"` or
-- a list of both `"standard::*,owner::user"`.
--
-- GIO also offers constants for these attribute values, which can be found by querying the GIO docs for
-- `G_FILE_ATTRIBUTE_*` constants:
-- [https://docs.gtk.org/gio/index.html?q=G_FILE_ATTRIBUTE_](https://docs.gtk.org/gio/index.html?q=G_FILE_ATTRIBUTE_)
--
-- See [docs.gtk.org](https://docs.gtk.org/gio/method.File.query_info.html) for additional details.
--
-- @todo Document the conversion from GIO's attributes to what LGI expects.
-- @async
-- @tparam string attribute The GIO file info attribute to query for.
-- @tparam function cb
-- @treturn[opt] GLib.Error
-- @treturn[opt] Gio.FileInfo
function File:query_info(attribute, cb)
    local f = self._private.f
    local priority = GLib.PRIORITY_DEFAULT

    f:query_info_async(attribute, 0, priority, nil, function(_, token)
        local info, err = f:query_info_finish(token)
        cb(err, info)
    end)
end

--- Check if the file exists.
--
-- Keep in mind that checking for existence before reading or writing a file is
-- subject to race conditions.
-- An external process may still alter a file between those two operations.
--
-- Also note that, due to limitations in GLib, this method cannot distinguish
-- between a file that is actually absent and a file that the user has no access
-- to.
--
-- @async
-- @tparam function cb
-- @treturn[opt] GLib.Error
-- @treturn boolean `true` if the file exists at its specified location.
function File:exists(cb)
    self:query_info("standard::type", function(err)
        if err then
            -- An error of "not found" is actually an expected outcome, so
            -- we hide the error.
            if err.code == Gio.IOErrorEnum[Gio.IOErrorEnum.NOT_FOUND] then
                cb(nil, false)
            else
                cb(err, false)
            end
        else
            cb(nil, true)
        end
    end)
end

--- Query the size of the file.
--
-- Note that due to limitations in GLib, this will return `0` for files
-- that the user has no access to.
--
-- @async
-- @tparam function cb
-- @treturn[opt] GLib.Error
-- @treturn[opt] number
function File:size(cb)
    self:query_info("standard::size", function(err, info)
        -- For some reason, the bindings return a float for a byte size
        cb(err, info and math.floor(info:get_size()))
    end)
end

--- Query the type of the file.
--
-- Common scenarios would be to compare this against `Gio.FileType`.
--
-- Note that due to limitations in GLib, this will return `Gio.FileType.UNKNOWN` for files
-- that the user has no access to.
--
-- @usage
--    f:type(function(err, type)
--        if err then return cb(err) end
--        local is_dir = type == Gio.FileType.DIRECTORY
--        local is_link = type == Gio.FileType.SYMBOLIC_LINK
--        local is_file = type == Gio.FileType.REGULAR
--        -- get a string representation
--        print(Gio.FileType[type])
--    end)
--
-- @async
-- @tparam function cb
-- @treturn[opt] GLib.Error
-- @treturn[opt] Gio.FileType
function File:type(cb)
    self:query_info("standard::type", function(err, info)
        cb(err, info and Gio.FileType[info:get_file_type()])
    end)
end

--- Creates an empty file.
--
-- Attempting to call this on an existing file will result in an error with type
-- `Gio.IOErrorEnum.EXISTS`.
--
-- Do not use this when you intend to write to the file immediately after creation, as it is subject
-- to race conditions.
-- Write operations, such as @{file.write} and @{file.write_stream} create files when needed.
--
-- @since 0.2.0
-- @async
-- @tparam function cb
-- @treturn[opt] GLib.Error
function File:create(cb)
    local f = self._private.f
    f:create_async(Gio.FileCreateFlags.NONE, GLib.PRIORITY_DEFAULT, nil, function(_, token)
        local _, err = f:create_finish(token)
        cb(err)
    end)
end

return file
