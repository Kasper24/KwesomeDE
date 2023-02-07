-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local helpers = require("helpers")
local string = string

local favorites = {}
local instance = nil

function favorites:add_favorite(client)
    awful.spawn.easy_async(string.format("ps -p %d -o args=", client.pid), function(stdout)
        self._private.favorites[client.class] = stdout
        helpers.settings:set_value("favorite-apps", self._private.favorites)
    end)
end

function favorites:remove_favorite(client)
    self._private.favorites[client.class] = nil
    self:emit_signal(client.class .. "::removed")
    helpers.settings:set_value("favorite-apps", self._private.favorites)
end

function favorites:is_favorite(client)
    return self._private.favorites[client.class]
end

function favorites:get_favorites()
    return self._private.favorites
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, favorites, true)

    ret._private = {}
    ret._private.favorites = {}
    local favorites = helpers.settings:get_direct("favorite-apps")
    for key, value in favorites:pairs() do
        ret._private.favorites[key] = value
    end

    return ret
end

if not instance then
    instance = new()
end
return instance
