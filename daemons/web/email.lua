local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local helpers = require("helpers")
local xml = require("helpers.xml")
local handler = require("helpers.xml.tree")
local ipairs = ipairs

local email = { }
local instance = nil

local PATH = helpers.filesystem.get_cache_dir("email")
local DATA_PATH = PATH .. "data.json"

local UPDATE_INTERVAL = 60 * 60 * 1 -- 1 hour

function email:open(email)
    awful.spawn("xdg-open " .. email.link._attr.href, false)
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, email, true)

    gtimer { timeout = UPDATE_INTERVAL, autostart = true, call_now = true, callback = function()
        local old_data = nil
        helpers.filesystem.read_file(DATA_PATH, function(content)
            if content ~= nil and content ~= false then
                local data = helpers.json.decode(content)
                if data ~= nil then
                    old_data = {}
                    for _, email in ipairs(data) do
                        old_data[email.id] = email.id
                    end
                end
            end

            awful.spawn.easy_async("curl -fsn https://mail.google.com/mail/feed/atom?alt=json", function(stdout)
                local parser = xml.parser(handler)
                parser:parse(stdout)

                if handler.root and handler.root.feed then
                    if old_data ~= nil then
                        for _, email in ipairs(handler.root.feed.entry) do
                            if old_data[email.id] == nil then
                                ret:emit_signal("new_email", email)
                            end
                        end
                    end

                    helpers.filesystem.save_file(
                        DATA_PATH,
                        helpers.json.encode(handler.root.feed.entry, { indent = true })
                    )

                    ret:emit_signal("emails", handler.root.feed.entry, handler.root.feed.fullcount)
                else
                    ret:emit_signal("error")
                end
            end)
        end)
    end}

    return ret
end

if not instance then
    instance = new()
end
return instance