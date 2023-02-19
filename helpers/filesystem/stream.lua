---------------------------------------------------------------------------
--- Utilities to handle Gio streams.
--
-- @module stream
-- @license GPL v3.0
---------------------------------------------------------------------------
local async = require("external.async")
local lgi = require("lgi")
local Gio = lgi.Gio
local GLib = lgi.GLib

local stream = {}

--- Constructors
-- @section constructors

--- Creates a dummy input stream.
--
-- Gio currently supports asynchronous splicing only between IOStreams, which combine both an input and output stream.
-- To be able to splice from just an output stream to just an input stream, dummy streams can be used to provide
-- the "ignored" side of the pipe.
--
-- See [docs.gtk.org](https://docs.gtk.org/gio/class.MemoryInputStream.html) for additional details.
--
-- @treturn Gio.MemoryInputStream
function stream.new_dummy_input()
    return Gio.MemoryInputStream.new()
end

--- Creates a dummy output stream.
--
-- Gio currently supports asynchronous splicing only between IOStreams, which combine both an input and output stream.
-- To be able to splice from just an output stream to just an input stream, dummy streams can be used to provide
-- the "ignored" side of the pipe.
--
-- See [docs.gtk.org](https://docs.gtk.org/gio/class.MemoryOutputStream.html) for additional details.
--
-- @treturn Gio.MemoryOutputStream
function stream.new_dummy_output()
    return Gio.MemoryOutputStream.new()
end

--- Combines an input and output stream into a single IOStream.
--
-- Either side may be omitted, in which case a dummy stream is used instead.
--
-- See [docs.gtk.org](https://docs.gtk.org/gio/class.SimpleIOStream.html) for additional details.
--
-- @tparam[opt] Gio.InputStream input_stream
-- @tparam[opt] Gio.OutputStream output_stream
-- @treturn Gio.SimpleIOStream
function stream.to_io_stream(input_stream, output_stream)
    input_stream = input_stream or stream.new_dummy_input()
    output_stream = output_stream or stream.new_dummy_output()
    return Gio.SimpleIOStream.new(input_stream, output_stream)
end

--- Utilities
-- @section utilities

--- Reads the entire stream into memory.
--
-- @since 0.2.0
-- @async
-- @tparam Gio.InputStream stream The stream to read from.
-- @tparam function cb
-- @treturn[opt] GLib.Error
-- @treturn nil|string
function stream.read_string(stream, cb)
    local priority = GLib.PRIORITY_DEFAULT
    local BUFFER_SIZE = 4096
    local str

    local function read_chunk(cb_chunk)
        stream:read_bytes_async(BUFFER_SIZE, priority, nil, function(_, token)
            local bytes, err = stream:read_bytes_finish(token)

            if err then
                return cb_chunk(err)
            end

            if bytes and #bytes > 0 then
                if not str then
                    str = bytes:get_data()
                else
                    str = str .. bytes:get_data()
                end
            end

            cb_chunk(nil, bytes)
        end)
    end

    local function check(bytes, cb_check)
        cb_check(nil, bytes ~= nil and #bytes == BUFFER_SIZE)
    end

    async.do_while(read_chunk, check, function(err)
        cb(err, str)
    end)
end

return stream
