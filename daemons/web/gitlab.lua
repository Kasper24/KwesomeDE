-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local helpers = require("helpers")
local filesystem = require("external.filesystem")
local json = require("external.json")
local string = string
local ipairs = ipairs

local gitlab = {}
local instance = nil

local LINK = "%s/api/v4/merge_requests?private_token=%s"
local PATH = filesystem.filesystem.get_cache_dir("gitlab/created_prs")
local AVATARS_PATH = PATH .. "avatars/"
local DATA_PATH = PATH .. "data.json"

local UPDATE_INTERVAL = 60 * 30 -- 30 mins

function gitlab:set_host(host)
    self._private.host = host
    helpers.settings["gitlab-host"] = host
end

function gitlab:get_host()
    return self._private.host
end

function gitlab:set_access_token(access_token)
    self._private.access_token = access_token
    helpers.settings["gitlab-access-token"] = access_token
end

function gitlab:get_access_token()
    return self._private.access_token
end

function gitlab:get_avatars_path()
    return AVATARS_PATH
end

function gitlab:refresh()
    local old_data = nil

    filesystem.filesystem.remote_watch(
        DATA_PATH,
        string.format(LINK, self._private.host, self._private.access_token),
        UPDATE_INTERVAL,
        function(content)
            local data = json.decode(content)
            if data == nil then
                self:emit_signal("error")
                return
            end

            for _, mr in ipairs(data) do
                if old_data[mr.id] == nil then
                    local remote_file = filesystem.file.new_for_uri(mr.author.avatar_url)
                    remote_file:read(function(error, content)
                        if error == nil then
                            local file = filesystem.file.new_for_path(AVATARS_PATH .. mr.author.id)
                            file:write(content, function(error)
                                if error == nil then
                                    gtimer.start_new(0.5, function()
                                        self:emit_signal("new_mr", mr)
                                        return false
                                    end)
                                end
                            end)
                        end
                    end)
                end
            end
        end,
        function(old_content)
            local data = json.decode(old_content) or {}
            if old_data == nil and data ~= nil then
                self:emit_signal("mrs", data)
            end

            old_data = {}
            for _, pr in ipairs(data) do
                old_data[pr.id] = pr.id
            end
        end
    )
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, gitlab, true)

    ret._private = {}
    ret._private.access_token = helpers.settings["gitlab-access-token"]
    ret._private.host = helpers.settings["gitlab-host"]

    if ret._private.access_token ~= "" then
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
