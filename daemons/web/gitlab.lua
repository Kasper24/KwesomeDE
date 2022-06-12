-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local settings = require("services.settings")
local helpers = require("helpers")
local string = string
local ipairs = ipairs

local gitlab = { }
local instance = nil

local link = "%s/api/v4/merge_requests?private_token=%s"
local PATH = helpers.filesystem.get_cache_dir("gitlab/created_prs")
local AVATARS_PATH = PATH .. "avatars/"
local DATA_PATH = PATH .. "data.json"

local UPDATE_INTERVAL = 60 * 60 * 1 -- 1 hour

function gitlab:set_host(host)
    self._private.host = host
    settings:set_value("gitlab.host", self._private.host)
end

function gitlab:get_host()
    return self._private.host
end

function gitlab:set_access_token(access_token)
    self._private.access_token = access_token
    settings:set_value("gitlab.access_token", self._private.access_token)
end

function gitlab:get_access_token()
    return self._private.access_token
end

function gitlab:refresh()
    local old_data = nil

    helpers.filesystem.remote_watch(
        DATA_PATH,
        string.format(link, self._private.host, self._private.access_token),
        UPDATE_INTERVAL,
        function(content)
            if content == nil or content == false then
                self:emit_signal("error")
                return
            end

            local data = helpers.json.decode(content)
            if data == nil then
                self:emit_signal("error")
                return
            end

            for index, pr in ipairs(data) do
                if old_data ~= nil and old_data[pr.id] == nil then
                    self:emit_signal("new_pr", pr)
                end

                local is_downloading = false
                local path_to_avatar = AVATARS_PATH .. pr.author.id

                helpers.filesystem.is_file_readable(path_to_avatar, function(result)
                    if result == false then
                        is_downloading = true
                        helpers.filesystem.save_uri(path_to_avatar, pr.author.avatar_url, function()
                            is_downloading = false
                            if index == #data then
                                self:emit_signal("update", data, AVATARS_PATH)
                            end
                        end)
                    elseif index == #data and is_downloading == false then
                        self:emit_signal("update", data, AVATARS_PATH)
                    end
                end)
            end
        end,
        function(old_content)
            local data = helpers.json.decode(old_content)
            if data ~= nil then
                old_data = {}
                for _, pr in ipairs(data) do
                    old_data[pr.id] = pr.id
                end
            end
        end
    )
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, gitlab, true)

    ret._private = {}
    ret._private.access_token = settings:get_value("gitlab.access_token")
    ret._private.host = settings:get_value("gitlab.host") or "https://gitlab.com"


    if ret._private.access_token ~= nil then
        ret:refresh()
    else
        gtimer.delayed_call(function()
            ret:emit_signal("missing_credentials")
        end)
    end

    return ret
end

if not instance then
    instance = new()
end
return instance