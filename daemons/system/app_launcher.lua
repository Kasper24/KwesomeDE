-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local lgi = require("lgi")
local Gio = lgi.Gio
local DesktopAppInfo = Gio.DesktopAppInfo
local AppInfo = Gio.AppInfo
local gobject = require("gears.object")
local gtable = require("gears.table")
local beautiful = require("beautiful")
local helpers = require("helpers")
local table = table
local ipairs = ipairs

local app_launcher = {}
local instance = nil

function app_launcher:get_desktop_app_info(client)
    local app_list = AppInfo.get_all()

    local client_props = {
        client.icon_name or false,
        client.class or false,
        client.name or false
    }

    for _, app in ipairs(app_list) do
        if app:should_show() then
            local id = app:get_id()
            local desktop_app_info = DesktopAppInfo.new(id)
            if desktop_app_info then
                local desktop_app_props = {
                    desktop_app_info:get_startup_wm_class() or false,
                    id:gsub(".desktop", ""), -- file name omitting .desktop
                    desktop_app_info:get_string("Name") or false, -- Declared inside the desktop file
                    desktop_app_info:get_string("Icon") or false,
                    desktop_app_info:get_string("Exec") or false,
                }

                for _, desktop_app_prop in ipairs(desktop_app_props) do
                    for _, client_prop in ipairs(client_props) do
                        if desktop_app_prop and client_prop and desktop_app_prop:lower() == client_prop:lower() then
                            return desktop_app_info, id
                        end
                    end
                end
            end
        end
    end
end

function app_launcher:get_actions(desktop_app_info)
    local actions = {}

    if desktop_app_info == nil then
        return actions
    end

    for _, action in ipairs(desktop_app_info:list_actions()) do
        table.insert(actions,
        {
            name = desktop_app_info:get_action_name(action),
            launch = function()
                desktop_app_info:launch_action(action)
            end
        })
    end

    return actions
end

function app_launcher:get_font_icon(...)
    local args = { ... }

    for _, arg in ipairs(args) do
        if arg then
            arg = arg:lower()
            arg = arg:gsub("_", "")
            arg = arg:gsub("%s+", "")
            arg = arg:gsub("-", "")
            arg = arg:gsub("%.", "")
            local icon = beautiful.app_icons[arg]
            if icon then
                return icon
            end
        end
    end

    return beautiful.icons.window
end

function app_launcher:is_app_pinned(id)
    for _, pinned_app in ipairs(self._private.pinned_apps) do
        if id == pinned_app.id then
            return true
        end
    end

    return false
end

function app_launcher:add_pinned_app(id)
    local pinned_app = {
        id = id
    }
    table.insert(self._private.pinned_apps, pinned_app)
    helpers.settings["app-launcher-pinned-apps"] = self._private.pinned_apps
    self:emit_signal("pinned_app::added", pinned_app)
end

function app_launcher:remove_pinned_app(id)
    for index, pinned_app in ipairs(self._private.pinned_apps) do
        if pinned_app.id == id then
            self:emit_signal("pinned_app::removed", self._private.pinned_apps[index])
            table.remove(self._private.pinned_apps, index)
            break
        end
    end
    helpers.settings["app-launcher-pinned-apps"] = self._private.pinned_apps
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, app_launcher, true)

    ret._private = {}
    ret._private.clients = {}
    ret._private.pinned_apps = helpers.settings["app-launcher-pinned-apps"]

    for _, pinned_app in ipairs(ret._private.pinned_apps) do
        ret:emit_signal("pinned_app::added", pinned_app)
    end

    return ret
end

if not instance then
    instance = new()
end
return instance
