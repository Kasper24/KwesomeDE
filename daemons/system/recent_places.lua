-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gobject = require("gears.object")
local gtable = require("gears.table")
local filesystem = require("external.filesystem")
local string = string
local table = table
local os = os

local recent_places = {}
local instance = nil

local path = os.getenv("HOME") .. "/.local/share/user-places.xbel"

local function get_places(self)
    local file = filesystem.file.new_for_path(path)
    file:read(function(error, content)
        if error == nil then
            local in_bookmark = false
            local recent_places = {}
            local place = {}

            for line in content:gmatch("[^\r\n$]+") do
                in_bookmark = (in_bookmark or string.match(line, "<bookmark ")) and
                                  not string.match(line, "</bookmark>")
                place.path = place.path or (in_bookmark and string.match(line, '<bookmark href=\"file://(.*)">'))
                place.title = place.title or (in_bookmark and string.match(line, '<title>(.*)</title>'))
                if string.match(line, "<bookmark:icon") then
                    place.icon = string.match(line, '<bookmark:icon name=\"(.*)"/>')
                end

                if string.match(line, "</bookmark") and place.title and place.path then
                    table.insert(recent_places, place)
                    place = {}
                end
            end

            self:emit_signal("update", recent_places)
        else
            self:emit_signal("empty", recent_places)
        end
    end)
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, recent_places, true)

    get_places(ret)

    return ret
end

if not instance then
    instance = new()
end
return instance
