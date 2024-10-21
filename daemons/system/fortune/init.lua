-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gstring = require("gears.string")

local fortune = {}
local instance = nil

function fortune:new()
    awful.spawn.easy_async("fortune -n 140 -s", function(out)
        if out ~= "" then
            out = out:gsub('^%s*(.-)%s*$', '%1') -- Remove trailing whitespaces
            out = gstring.xml_escape(out)
            self:emit_signal("update", out)
        end
    end)
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, fortune, true)

    ret:new()

    return ret
end

if not instance then
    instance = new()
end
return instance
