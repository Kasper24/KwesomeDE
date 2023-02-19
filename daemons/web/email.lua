-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local filesystem = require("external.filesystem")
local xml = require("external.xml2lua.xml2lua")
local handler = require("external.xml2lua.xmlhandler.tree")
local ipairs = ipairs
local string = string
local os = os

local email = {}
local instance = nil

local PATH = filesystem.filesystem.get_cache_dir("email")
local DATA_PATH = PATH .. "data.json"
local NET_RC_PATH = "/home/" .. os.getenv("USER") .. "/.netrc"

local UPDATE_INTERVAL = 60 * 30 -- 30 mins

function email:open(email)
    awful.spawn("xdg-open " .. email.link._attr.href, false)
end

function email:update_net_rc(machine, login, password)
    local file = filesystem.file.new_for_path(NET_RC_PATH)
    file:write(string.format("machine %s\nlogin %s\npassword %s", machine, login, password))
end

function email:get_machine()
    return self._private.machine
end

function email:get_login()
    return self._private.login
end

function email:get_password()
    return self._private.password
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, email, true)

    ret._private = {}

    local file = filesystem.file.new_for_path(NET_RC_PATH)
    file:iterate_lines(function(error, line)
        if error == nil then
            if line:match("machine") then
                ret._private.machine = line:match("machine (.*)")
            elseif line:match("login") then
                ret._private.login = line:match("login (.*)")
            elseif line:match("password") then
                ret._private.password = line:match("password (.*)")
            end
        end
    end)

    gtimer {
        timeout = UPDATE_INTERVAL,
        autostart = true,
        call_now = true,
        callback = function()
            local old_data = nil
            local file = filesystem.file.new_for_path(DATA_PATH)
            file:read(function(error, content)
                if error == nil then
                    local emails_handler = handler:new()
                    local emails_parser = xml.parser(emails_handler)
                    emails_parser:parse(content)

                    if old_data == nil and emails_handler.root.feed.entry ~= nil then
                        ret:emit_signal("emails", emails_handler.root.feed.entry)
                    end

                    old_data = {}
                    for _, email in ipairs(emails_handler.root.feed.entry) do
                        old_data[email.id] = email.id
                    end
                end

                awful.spawn.easy_async("curl -fsn https://mail.google.com/mail/feed/atom?alt=json", function(stdout)
                    local emails_handler = handler:new()
                    local emails_parser = xml.parser(emails_handler)
                    emails_parser:parse(stdout)

                    if emails_handler.root and emails_handler.root.feed then
                        for _, email in ipairs(emails_handler.root.feed.entry) do
                            if old_data == nil or old_data[email.id] == nil then
                                ret:emit_signal("new_email", email)
                            end
                        end

                        file:write(stdout)
                    else
                        ret:emit_signal("error")
                    end
                end)
            end)
        end
    }

    return ret
end

if not instance then
    instance = new()
end
return instance
