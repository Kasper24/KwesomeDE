-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local helpers = require("helpers")
local string = string
local table = table
local ipairs = ipairs
local capi = {
    client = client
}

local favorites = {}
local instance = nil

local function add_favorite(self, client, exec)
    table.insert(self._private.favorites, {
        index = #self._private.favorites + 1,
        icon_name = client.desktop_app_info.icon or
                    client.icon_name or
                    client.class,
        class =     client.desktop_app_info.startup_wm_class or
                    client.desktop_app_info.id or
                    client.class,
        name =      client.desktop_app_info.name or
                    client.name,
        exec =      exec
    })
    helpers.settings:set_value("favorite-apps", self._private.favorites)
end

function favorites:add_favorite(client)
    if client.pid then
        awful.spawn.easy_async(string.format("ps -p %d -o args=", client.pid), function(stdout)
            add_favorite(self, client, stdout)
        end)
    else
        add_favorite(self, client, client.desktop_app_info.exec)
    end
end

function favorites:remove_favorite(client)
    table.remove(self._private.favorites, client.index)
    helpers.settings:set_value("favorite-apps", self._private.favorites)
    self:emit_signal(client.class .. "::removed")
end

function favorites:is_favorite(client)
    return self:get_favorite_for_client(client) ~=  nil
end

function favorites:get_favorites()
    return self._private.favorites
end

function favorites:get_favorite_for_client(client)
    for _, favorite in ipairs(self._private.favorites) do
        if  client.icon_name == favorite.icon_name or
            client.class == favorite.class or
            client.name == favorite.name
        then
            return favorite
        end
    end
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, favorites, true)

    ret._private = {}
    ret._private.favorites = {}

    local favorites = helpers.settings:get_direct("favorite-apps")
    for key, value in favorites:pairs() do
        ret._private.favorites[key] = value
        capi.client.emit_signal("manage", value)
    end

    capi.client.connect_signal("unmanage", function(client)
        if ret:is_favorite(client) and
            #helpers.client.find({class = client.class}) == 0
        then
            ret:emit_signal("favorite::added", favorites)
        end
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance
