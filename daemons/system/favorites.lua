-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local settings = require("services.settings")
local string = string

local favorites = { }
local instance = nil

function favorites:add_favorite(client)
    self._private.favorites[client.class] = {}
    awful.spawn.easy_async(string.format("ps -p %d -o args=", client.pid), function(stdout)
        self._private.favorites[client.class] = { font_icon = client.font_icon, command = stdout }
        settings:set_value("favorites", self._private.favorites)
    end)
end

function favorites:remove_favorite(client)
    self._private.favorites[client.class] = nil
    self:emit_signal(client.class .. "::removed")
    settings:set_value("favorites", self._private.favorites)
end

function favorites:toggle_favorite(client)
    if self._private.favorites[client.class] == nil then
        self:add_favorite(client)
    else
        self:remove_favorite(client)
    end
end

function favorites:is_favorite(class)
    return self._private.favorites[class]
end

function favorites:get_favorites()
    return self._private.favorites
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, favorites, true)

    ret._private = {}
    ret._private.favorites = settings:get_value("favorites") or {}

    return ret
end

if not instance then
    instance = new()
end
return instance