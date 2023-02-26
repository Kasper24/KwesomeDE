-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local beautiful = require("beautiful")
local helpers = require("helpers")
local filesystem = require("external.filesystem")
local json = require("external.json")
local string = string
local ipairs = ipairs

local github = {}
local instance = nil

local UPDATE_INTERVAL = 60 * 30 -- 30 mins
local PATH = filesystem.filesystem.get_cache_dir("github")

local PRS_PATH = PATH .. "created_prs/"
local PRS_AVATARS_PATH = PRS_PATH .. "avatars/"
local PRS_DATA_PATH = PRS_PATH .. "data.json"

local EVENTS_PATH = PATH .. "events/"
local EVENTS_AVATARS_PATH = EVENTS_PATH .. "avatars/"
local EVENTS_DATA_PATH = EVENTS_PATH .. "data.json"

function github:set_username(username)
    self._private.username = username
    helpers.settings["github-username"] = username
end

function github:get_username()
    return self._private.username
end

function github:get_event_info(event)
    local action_string = event.type
    local icon = beautiful.icons.github
    local link = "http://github.com/" .. event.repo.name

    if (event.type == "PullRequestEvent") then
        action_string = event.payload.action .. " a pull request in"
        link = event.payload.pull_request.html_url
        icon = beautiful.icons.code_pull_request
    elseif (event.type == "PullRequestReviewCommentEvent") then
        action_string = event.payload.action == "created" and "commented in pull request" or event.payload.action ..
                            " a comment in"
        link = event.payload.pull_request.html_url
        icon = beautiful.icons.message
    elseif (event.type == "IssuesEvent") then
        action_string = event.payload.action .. " an issue in"
        link = event.payload.issue.html_url
        icon = beautiful.icons.circle_exclamation
    elseif (event.type == "IssueCommentEvent") then
        action_string = event.payload.action == "created" and "commented in issue" or event.payload.action ..
                            " a comment in"
        link = event.payload.issue.html_url
        icon = beautiful.icons.message
    elseif (event.type == "CommitCommentEvent") then
        action_string =  "commented at commit"
        link = event.payload.comment.html_url
        icon = beautiful.icons.message
    elseif (event.type == "WatchEvent") then
        action_string = "starred"
        icon = beautiful.icons.star
    elseif (event.type == "PushEvent") then
        action_string = "pushed to"
        icon = beautiful.icons.commit
    elseif (event.type == "ForkEvent") then
        action_string = "forked"
        icon = beautiful.icons.code_branch
    elseif (event.type == "CreateEvent") then
        action_string = "created"
        icon = beautiful.icons.code_branch
    end

    return {
        action_string = action_string,
        link = link,
        icon = icon
    }
end

function github:get_events_avatars_path()
    return EVENTS_AVATARS_PATH
end

function github:get_prs_avatars_path()
    return PRS_AVATARS_PATH
end

local function github_events(self)
    local link = "https://api.github.com/users/%s/received_events"
    local old_data = nil

    filesystem.filesystem.remote_watch(EVENTS_DATA_PATH, string.format(link, self._private.username), UPDATE_INTERVAL,
        function(content)
            local data = json.decode(content)

            if data == nil then
                self:emit_signal("events::error")
                return
            end

            for _, event in ipairs(data) do
                if old_data[event.id] == nil then
                    local remote_file = filesystem.file.new_for_uri(event.actor.avatar_url)
                    remote_file:read(function(error, content)
                        if error == nil then
                            local file = filesystem.file.new_for_path(EVENTS_AVATARS_PATH .. event.actor.id)
                            file:write(content, function(error)
                                if error == nil then
                                    gtimer.start_new(0.5, function()
                                        self:emit_signal("new_event", event)
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
                self:emit_signal("events", data)
            end

            old_data = {}
            for _, event in ipairs(data) do
                old_data[event.id] = event.id
            end
        end
    )
end

local function github_prs(self)
    local link = "https://api.github.com/search/issues?q=author%3A" .. self._private.username .. "+type%3Apr"
    local old_data = nil

    filesystem.filesystem.remote_watch(
        PRS_DATA_PATH,
        link,
        UPDATE_INTERVAL,
        function(content)
            local data = json.decode(content)
            if data == nil then
                self:emit_signal("prs::error")
                return
            end

            for _, pr in ipairs(data.items) do
                if old_data[pr.id] == nil then
                    local remote_file = filesystem.file.new_for_uri(pr.user.avatar_url)
                    remote_file:read(function(error, content)
                        if error == nil then
                            local file = filesystem.file.new_for_path(PRS_AVATARS_PATH .. pr.user.id)
                            file:write(content, function(error)
                                if error == nil then
                                    gtimer.start_new(0.5, function()
                                        self:emit_signal("new_pr", pr)
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
                self:emit_signal("prs", data.items)
            end

            old_data = {}
            for _, pr in ipairs(data.items) do
                old_data[pr.id] = pr.id
            end
        end
    )
end

local function github_contributions(self)
    local link = "https://github-contributions.vercel.app/api/v1/%s"
    local path = PATH .. "contributions/"
    local DATA_PATH = path .. "data.json"

    filesystem.filesystem.remote_watch(DATA_PATH, string.format(link, self._private.username), UPDATE_INTERVAL,
        function(content)
            self:emit_signal("contributions", content)
        end)
end

function github:refresh()
    github_events(self)
    github_prs(self)
    -- github_contributions(self)
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, github, true)

    ret._private = {}
    ret._private.username = helpers.settings["github-username"]

    if ret._private.username ~= "" then
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
