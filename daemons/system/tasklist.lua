-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local lgi = require("lgi")
local Gio = lgi.Gio
local Gdk = lgi.require("Gdk", "3.0")
local DesktopAppInfo = Gio.DesktopAppInfo
local AppInfo = Gio.AppInfo
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local beautiful = require("beautiful")
local helpers = require("helpers")
local floor = math.floor
local string = string
local table = table
local ipairs = ipairs
local pairs = pairs
local math = math
local capi = {
    awesome = awesome,
    root = root,
    client = client,
}

local tasklist = {}
local instance = nil

local function update_positions(self)
    local pos = 0
    for _, pinned_app in ipairs(self._private.pinned_apps) do
        if #helpers.client.find({class = pinned_app.class}) == 0 then
            self:emit_signal("pinned_app::pos", pinned_app, pos)
            pos = pos + 1
        else
            self:emit_signal("pinned_app::removed", pinned_app)
        end
    end
    for _, client in ipairs(self._private.clients) do
        self:emit_signal("client::pos", client, pos)
        pos = pos + 1
    end
end

local function sort_clients(self)
    table.sort(self._private.clients, function(a, b)
        if a.first_tag == b.first_tag then
            if a.floating ~= b.floating then
                return not a.floating
            elseif a.maximized ~= b.maximized then
                return a.maximized
            elseif a.fullscreen ~= b.fullscreen then
                return a.maximized
            else
                local a_data = self:idx(a)
                local b_data = self:idx(b)
                return a_data.col + a_data.idx < b_data.col + b_data.idx
            end
        else
            return a.first_tag.index < b.first_tag.index
        end
    end)
end

local function on_pinned_app_added(self, pinned_app)
    pinned_app.desktop_app_info = self:get_desktop_app_info(pinned_app)
    pinned_app.actions = self:get_actions(pinned_app)
    pinned_app.icon = self:get_icon(pinned_app) -- not used
    pinned_app.font_icon = self:get_font_icon(pinned_app.class, pinned_app.name)
    pinned_app.widget = nil
    update_positions(self)
end

local function on_client_updated(self)
    sort_clients(self)
    update_positions(self)
end

local function on_client_added(self, client)
    client.managed = true
    client.favorite = false
    client.desktop_app_info = self:get_desktop_app_info(client)
    client.actions = self:get_actions(client)
    client.icon = self:get_icon(client) -- not used
    client.font_icon = self:get_font_icon(client.class, client.name)
    client.domiant_color = self:get_dominant_color(client)

    for _, favorite in ipairs(self._private.pinned_apps) do
        if client.class == favorite.class then
            client.favorite = true
        end
    end

    table.insert(self._private.clients, client)
    on_client_updated(self)
end

local function on_client_removed(self, client)
    for index, client2 in ipairs(self._private.clients) do
        if client2.pid == client.pid then
            table.remove(self._private.clients, index)
        end
    end
    on_client_updated(self)
    self:emit_signal("client::removed", client)
end

function tasklist:get_dominant_color(client)
    local color
    -- gsurface(client.content):write_to_png(
    --     "/home/mutex/nice/" .. client.class .. "_" .. client.instance .. ".png")
    local pb
    local bytes
    local tally = {}
    local screenshot = awful.screenshot {
        client = client
    }
    screenshot:refresh()
    local content = screenshot.surface
    local cgeo = client:geometry()
    local x_offset = 2
    local y_offset = 2
    local x_lim = math.floor(cgeo.width / 2)
    for x_pos = 0, x_lim, 2 do
        for y_pos = 0, 8, 1 do
            pb = Gdk.pixbuf_get_from_surface(content, x_offset + x_pos, y_offset + y_pos, 1, 1)
            bytes = pb:get_pixels()
            color = "#" .. bytes:gsub(".", function(c)
                return ("%02x"):format(c:byte())
            end)
            if not tally[color] then
                tally[color] = 1
            else
                tally[color] = tally[color] + 1
            end
        end
    end
    local mode
    local mode_c = 0
    for kolor, kount in pairs(tally) do
        if kount > mode_c then
            mode_c = kount
            mode = kolor
        end
    end
    color = mode
    return color
end

function tasklist:idx(client)
    client = client or capi.client.focus
    if not client then return end

    local clients = capi.client.get()
    local idx = nil
    for k, cl in ipairs(clients) do
        if cl == client then
            idx = k
            break
        end
    end

    local t = client.screen.selected_tag
    local nmaster = t.master_count

    -- This will happen for floating or maximized clients
    if not idx then return nil end

    if idx <= nmaster then
        return {idx = idx, col=0, num=nmaster}
    end
    local nother = #clients - nmaster
    idx = idx - nmaster

    -- rather than regenerate the column number we can calculate it
    -- based on the how the tiling algorithm places clients we calculate
    -- the column, we could easily use the for loop in the program but we can
    -- calculate it.
    local ncol = t.column_count
    -- minimum number of clients per column
    local percol = floor(nother / ncol)
    -- number of columns with an extra client
    local overcol = math.fmod(nother, ncol)
    -- number of columns filled with [percol] clients
    local regcol = ncol - overcol

    local col = floor( (idx - 1) / percol) + 1
    if  col > regcol then
        -- col = floor( (idx - (percol*regcol) - 1) / (percol + 1) ) + regcol + 1
        -- simplified
        col = floor( (idx + regcol + percol) / (percol+1) )
        -- calculate the index in the column
        idx = idx - percol*regcol - (col - regcol - 1) * (percol+1)
        percol = percol+1
    else
        idx = idx - percol*(col-1)
    end

    return {idx = idx, col=col, num=percol}
end

function tasklist:get_desktop_app_info(client)
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
                    id:gsub(".desktop", "") or false, -- file name omitting .desktop
                    desktop_app_info:get_string("Name") or false, -- Declared inside the desktop file
                    desktop_app_info:get_string("Icon") or false,
                    desktop_app_info:get_string("Exec") or false,
                }

                for _, desktop_app_prop in ipairs(desktop_app_props) do
                    for _, client_prop in ipairs(client_props) do
                        if desktop_app_prop and client_prop and desktop_app_prop:lower() == client_prop:lower() then
                            return {
                                startup_wm_class = desktop_app_props[1],
                                id = desktop_app_props[2],
                                name = desktop_app_props[3],
                                icon = desktop_app_props[4],
                                exec = desktop_app_props[5],
                                desktop_app_info = desktop_app_info,
                                actions = desktop_app_info:list_actions()
                            }
                        end
                    end
                end
            end
        end
    end
end

function tasklist:get_actions(client)
    local actions = {}

    if client.desktop_app_info == nil then
        return actions
    end

    for _, action in ipairs(client.desktop_app_info.actions) do
        table.insert(actions,
        {
            name = client.desktop_app_info.desktop_app_info:get_action_name(action),
            launch = function()
                client.desktop_app_info.desktop_app_info:launch_action(action)
            end
        })
    end

    return actions
end

function tasklist:get_icon(client)
    if client.desktop_app_info then
        local icon = client.desktop_app_info.icon
        if icon ~= nil then
            return helpers.icon_theme.get_icon_path(icon)
        end
    end

    return helpers.icon_theme.choose_icon({"window", "window-manager", "xfwm4-default", "window_list"})
end

function tasklist:get_font_icon(...)
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

local function add_pinned_app(self, client, exec)
    local pinned_app = {
        icon_name = --client.desktop_app_info.icon or
                    -- client.icon_name or
                    client.class,
        class =     --client.desktop_app_info.startup_wm_class or
                    --client.desktop_app_info.id or
                    client.class,
        name =      --client.desktop_app_info.name or
                    client.name,
        exec =      exec
    }
    table.insert(self._private.pinned_apps, pinned_app)
    helpers.settings["favorite-apps"] = self._private.pinned_apps
    on_pinned_app_added(self, pinned_app)
end

function tasklist:add_pinned_app(app)
    if app.pid then
        app.favorite = true
        awful.spawn.easy_async(string.format("ps -p %d -o args=", app.pid), function(stdout)
            add_pinned_app(self, app, stdout)
        end)
    else
        add_pinned_app(self, app, app.desktop_app_info.exec)
    end
end

function tasklist:remove_pinned_app(pinned_app)
    for i, pinned_app2 in ipairs(self._private.pinned_apps) do
        if pinned_app2.class == pinned_app.class then
            table.remove(self._private.pinned_apps, i)
            self:emit_signal("pinned_app::removed", pinned_app)
            break
        end
    end

    helpers.settings["favorite-apps"] = self._private.pinned_apps
    update_positions(self)
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, tasklist, true)

    ret._private = {}
    ret._private.clients = {}
    ret._private.pinned_apps = helpers.settings["favorite-apps"]

    capi.client.connect_signal("unmanage", function(client)
        on_client_removed(ret, client)
    end)

    capi.client.connect_signal("tagged", function(client)
        if client.managed then
            on_client_updated(ret)
        end
    end)

    capi.client.connect_signal("property::floating", function(client)
        if client.managed then
            on_client_updated(ret)
        end
    end)

    capi.client.connect_signal("property::maximized", function(client)
        if client.managed then
            on_client_updated(ret)
        end
    end)

    capi.client.connect_signal("property::fullscreen", function(client)
        if client.managed then
            on_client_updated(ret)
        end
    end)

    capi.client.connect_signal("swapped", function(client, other_client, is_source)
        if client.managed then
            on_client_updated(ret)
        end
    end)

    capi.client.connect_signal("scanned", function()
        capi.client.connect_signal("manage", function(client)
            on_client_added(ret, client)
        end)

        for _, client in ipairs(capi.client.get()) do
            on_client_added(ret, client)
        end

        for _, pinned_app in ipairs(ret._private.pinned_apps) do
            on_pinned_app_added(ret, pinned_app)
        end
    end)

    capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
        for _, client in ipairs(capi.client.get()) do
            client.font_icon = helpers.client.get_font_icon(client.class, client.name)
            client.domiant_color = ret:get_dominant_color(client)
        end
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance
