-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local helpers = require("helpers")
local capi = { awesome = awesome }

local picom = { }
local instance = nil

local UPDATE_INTERVAL = 1
local CONFIG_PATH = helpers.filesystem.get_awesome_config_dir("config") .. "picom.conf"

local properties =
{
	"active-opacity", "inactive-opacity",
	"corner-radius", "blur-strength"
}

function picom:turn_on(save)
    local p = self._private

    local cmd = string.format("picom --experimental-backends --config %s ", CONFIG_PATH)
    for _, prop in ipairs(properties) do
        cmd = cmd .. string.format("--%s %s ", prop, p[prop])
    end
    awful.spawn(cmd)

    if save == true then
        helpers.settings:set_value("picom", true)
    end
end

function picom:turn_off(save)
    awful.spawn("pkill -f 'picom --experimental-backends'", false)
    if save == true then
        helpers.settings:set_value("picom", false)
    end
end

function picom:toggle(save)
    helpers.run.is_running("picom", function(is_running)
        if is_running == true then
            self:turn_off(save, true)
        else
            self:turn_on(save, true)
        end
    end)
end

local function build_properties(prototype)
    for _, prop in ipairs(properties) do
        if not prototype["set_" .. prop] then
            prototype["set_" .. prop] = function(self, value)
                if self._private[prop] ~= value then
                    self._private[prop] = value
                    helpers.settings:set_value("picom-" .. prop, value)

                    awful.spawn.easy_async("pkill -f 'picom --experimental-backends'", function()
                        gtimer {
                            timeout = 0.3,
                            call_now = false,
                            autostart = true,
                            single_shot = true,
                            callback = function()
                                self:turn_on(false)
                            end
                        }
                    end)
                end
                return self
            end
        end
        if not prototype["get_" .. prop] then
            prototype["get_" .. prop] = function(self)
                return self._private[prop]
            end
        end
    end
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, picom, true)

    ret._private = {}
    ret._private.state = -1

    for _, prop in ipairs(properties) do
        ret._private[prop] = helpers.settings:get_value("picom-" .. prop)
    end

    gtimer.delayed_call(function()
        if helpers.settings:get_value("picom") == true then
            ret:turn_on()
        elseif helpers.settings:get_value("picom") == false then
            ret:turn_off()
        end

        gtimer { timeout = UPDATE_INTERVAL, autostart = true, call_now = true, callback = function()
            if ret._private.state ~= capi.awesome.composite_manager_running then
                ret:emit_signal("state", capi.awesome.composite_manager_running)
                ret._private.state = capi.awesome.composite_manager_running
            end
        end}
    end)

    return ret
end

build_properties(picom, properties)

if not instance then
    instance = new()
end
return instance