-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local gstring = require("gears.string")
local wibox = require("wibox")
local naughty = require("naughty")
local settings = require("services.settings")
local helpers = require("helpers")
local ipairs = ipairs
local table  = table
local os = os

local notifications = { }
local instance = nil

local PATH = helpers.filesystem.get_cache_dir("notifications")
local ICONS_PATH = PATH .. "icons/"
local DATA_PATH = PATH .. "data.json"

local function save_notification(self, notification)
    notification.time = os.date("%Y-%m-%dT%H:%M:%S")
    notification.uuid = helpers.string.random_uuid()

    local icon_path = ICONS_PATH .. notification.uuid .. ".svg"
    local app_icon_path = ICONS_PATH .. notification.uuid .. "_app.svg"

    table.insert(self.notifications, {
        uuid = notification.uuid,
        app_font_icon = notification.app_font_icon,
        app_icon = app_icon_path,
        app_name = notification.app_name,
        font_icon = notification.font_icon,
        icon = icon_path,
        title = gstring.xml_unescape(notification.title),
        message = gstring.xml_unescape(notification.message),
        time = notification.time,
    })

    wibox.widget.draw_to_svg_file(wibox.widget
    {
        widget = wibox.widget.imagebox,
        forced_width = 35,
        forced_height = 35,
        image = notification.icon,
    }, icon_path, 35, 35)

    wibox.widget.draw_to_svg_file(wibox.widget
    {
        widget = wibox.widget.imagebox,
        forced_width = 35,
        forced_height = 35,
        image = notification.app_icon,
    }, app_icon_path, 35, 35)

    self.save_timer:again()
end

local function read_notifications(self)
    helpers.filesystem.read_file(DATA_PATH, function(content)
        self.notifications = {}

        if content == nil then
            self:emit_signal("empty")
            return
        end

        local data = helpers.json.decode(content)
        if data == nil then
            self:emit_signal("empty")
            return
        end

        self.notifications = data
        if #self.notifications > 0 then
            for i, notification in ipairs(self.notifications) do
                self:emit_signal("new", notification)
            end
        else
            self:emit_signal("empty")
        end
    end)
end

function notifications:remove_all_notifications()
    self.notifications = {}
    self.save_timer:again()
    awful.spawn("rm -rf " .. ICONS_PATH)
    self:emit_signal("empty")
end

function notifications:remove_notification(notification_data)
    local index = 0
    for i, notification in ipairs(self.notifications) do
        if notification.uuid == notification_data.uuid then
            index = i
            break
        end
    end

    if index ~= 0 then
        helpers.filesystem.delete_file(self.notifications[index].icon)

        table.remove(self.notifications, index)
        self.save_timer:again()
        if #self.notifications == 0 then
            self:emit_signal("empty")
        end
    end
end

function notifications:is_suspended()
    return self.suspended
end

function notifications:turn_on()
    if self.suspended ~= true then
        self.suspended = true
        settings:set_value("naughty_suspended", true)
        self:emit_signal("state", true)
    end
end

function notifications:turn_off(save)
    if self.suspended ~= false then
        self.suspended = false
        settings:set_value("naughty_suspended", false)
        self:emit_signal("state", false)
    end
end

function notifications:block_on_locked()
    if self.suspended == false then
        self.suspended = true
        self.was_not_suspended = true
    end
end

function notifications:unblock_on_unlocked()
    if self.was_not_suspended == true then
        self.suspended = false
        self.was_not_suspended = nil
    end
end

function notifications:toggle()
    if self.suspended == true then
        self:turn_off()
    else
        self:turn_on()
    end
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, notifications, true)

    helpers.filesystem.make_directory(ICONS_PATH, function() end)

    ret.notifications = {}
    ret.save_timer = gtimer
    {
        timeout = 1,
        autostart = false,
        single_shot = true,
        callback = function()
            helpers.filesystem.save_file(
                DATA_PATH,
                helpers.json.encode(ret.notifications, { indent = true })
            )
        end
    }

    gtimer.delayed_call(function()
        if settings:get_value("naughty_suspended") == true then
            ret:turn_on()
        elseif settings:get_value("naughty_suspended") == false then
            ret:turn_off()
        end

        read_notifications(ret)
    end)

    naughty.connect_signal("request::display", function(notification)
        save_notification(ret, notification)
        ret:emit_signal("new", notification)
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance