-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local gdebug = require("gears.debug")
local bling = require("external.bling")
local tabbed = bling.module.tabbed
local helpers = require("helpers")
local filesystem = require("external.filesystem")
local json = require("external.json")
local tostring = tostring
local string = string
local ipairs = ipairs
local pairs = pairs
local table = table
local capi = {
    awesome = awesome,
    root = root,
    screen = screen,
    client = client
}

local persistent = {}
local instance = nil

local PATH = filesystem.filesystem.get_cache_dir("persistent")
local DATA_PATH = PATH .. "data.json"

local client_properties = {"hidden", "minimized", "above", "ontop", "below", "fullscreen", "maximized",
    "maximized_horizontal", "maximized_vertical", "sticky", "floating", "x", "y", "width",
    "height", "class"}

local function restore_clients(self, screen)
    local function apply_client(client, saved_client)
        for _, property in ipairs(client_properties) do
            client[property] = saved_client[property]
        end
        --TODO
        -- client:move_to_screen(saved_client.screen)
        if saved_client.titlebar then
            awful.titlebar.show(client)
        end

        -- Tags
        gtimer.delayed_call(function()
            local tags = {}
            for _, tag in ipairs(saved_client.tags) do
                table.insert(tags, capi.screen[client.screen].tags[tag])
            end
            client.first_tag = tags[1]
            client:tags(tags)
        end)

        -- Bling tabbed
        local parent = client
        if saved_client.bling_tabbed then
            for _, window in ipairs(saved_client.bling_tabbed.clients) do
                for _, client in ipairs(capi.client.get()) do
                    if client.window == window then
                        local focused_idx = saved_client.bling_tabbed.focused_idx
                        if not parent.bling_tabbed and not client.bling_tabbed then
                            tabbed.init(parent)
                            tabbed.add(client, parent.bling_tabbed)
                            gtimer.delayed_call(function()
                                tabbed.switch_to(parent.bling_tabbed, focused_idx)
                            end)
                        end
                        if not parent.bling_tabbed and client.bling_tabbed then
                            tabbed.add(parent, client.bling_tabbed)
                            gtimer.delayed_call(function()
                                tabbed.switch_to(client.bling_tabbed, focused_idx)
                            end)
                        end
                        if parent.bling_tabbed and not client.bling_tabbed then
                            tabbed.add(client, parent.bling_tabbed)
                            gtimer.delayed_call(function()
                                tabbed.switch_to(parent.bling_tabbed, focused_idx)
                            end)
                        end
                        client:tags({})
                    end
                end
            end
        end
    end

    local new_pid = 0
    local function wait_on_client(client)
        if client.pid == new_pid then
            apply_client(client, saved_client)
        end
    end

    local saved_clients = self.restored_settings[screen.name].clients
    for _, saved_client in ipairs(saved_clients) do
        for index, client in ipairs(screen.all_clients) do
            if client.pid == saved_client.pid then
                apply_client(client, saved_client)
            elseif index == #screen.clients then
                new_pid = awful.spawn(client.command, false)
                capi.client.connect_signal("request::manage", wait_on_client)
                gtimer.start_new(1, function()
                    capi.client.disconnect_signal("request::manage", wait_on_client)
                    return false
                end)
            end
        end
    end
end

local function restore_tags(self, screen)
    awful.tag.viewnone()
    local saved_tags = self.restored_settings[screen.name].tags
    for _, saved_tag in ipairs(saved_tags) do
        for index, tag in ipairs(screen.tags) do
            if tag.name == saved_tag.name then
                tag.activated = saved_tag.activated
                tag.master_width_factor = saved_tag.master_width_factor
                tag.layout = awful.layout.layouts[saved_tag.layout]
                tag.volatile = saved_tag.volatile
                tag.gap = saved_tag.gap
                tag.gap_single_client = saved_tag.gap_single_client
                tag.master_fill_policy = saved_tag.master_fill_policy
                tag.master_count = saved_tag.master_count
                tag.column_count = saved_tag.column_count
                if saved_tag.selected then
                    awful.tag.viewtoggle(tag)
                end
            end
        end
    end
end

local function restore(self)
    local file = filesystem.file.new_for_path(DATA_PATH)
    file:read(function(error, content)
        if error == nil then
            self.restored_settings = json.decode(content)
            if self.restored_settings ~= nil then
                for s in screen do
                    for key, output in pairs(s.outputs) do
                        s.name = key
                    end

                    restore_tags(self, s)
                    restore_clients(self, s)
                end
            end
        end
    end)
end

local function save_clients(self, screen)
    self.settings[screen.name].clients = {}

    for _, client in ipairs(screen.all_clients) do
        local pid = tostring(client.pid)
        local saved_client = {}

        -- Has to be blocking!
        local handle = io.popen(string.format("ps -p %d -o args=", client.pid))
        if handle ~= nil then
            saved_client.command = handle:read("*a"):gsub('^%s*(.-)%s*$', '%1')
            handle:close()
        end

        -- Properties
        for _, property in ipairs(client_properties) do
            saved_client[property] = client[property]
        end

        if client.titlebar_widget and not client.custom_titlebar then
            saved_client.titlebar = true
        end

        -- Tags
        saved_client.tags = {}
        for index, client_tag in ipairs(client:tags()) do
            saved_client.tags[index] = client_tag.index
        end

        -- Bling tabs
        if client.bling_tabbed and client.bling_tabbed.parent == client.window then
            saved_client.bling_tabbed = {}
            saved_client.bling_tabbed.focused_idx = client.bling_tabbed.focused_idx

            saved_client.bling_tabbed.clients = {}
            for index, bling_tabbed_client in ipairs(client.bling_tabbed.clients) do
                saved_client.bling_tabbed.clients[index] = bling_tabbed_client.window
            end
        end

        self.settings[screen.name].clients[pid] = saved_client
    end
end

local function save_tags(self, screen)
    self.settings[screen.name].tags = {}

    for _, tag in ipairs(screen.tags) do
        local saved_tag = {}
        saved_tag.name = tag.name
        saved_tag.selected = tag.selected
        saved_tag.activated = tag.activated
        saved_tag.master_width_factor = tag.master_width_factor
        saved_tag.layout = awful.layout.get_tag_layout_index(tag)
        saved_tag.volatile = tag.volatile or false
        saved_tag.gap = tag.gap
        saved_tag.gap_single_client = tag.gap_single_client
        saved_tag.master_fill_policy = tag.master_fill_policy
        saved_tag.master_count = tag.master_count
        saved_tag.column_count = tag.column_count
        self.settings[screen.name].tags[tag.index] = saved_tag
    end
end

local function save(self)
    self.settings = {}

    for s in screen do
        for key, output in pairs(s.outputs) do
            s.name = key
        end
        self.settings[s.name] = {}
        save_tags(self, s)
        save_clients(self, s)
    end

    local _settings_status, settings = pcall(function()
        return json.encode(self.settings)
    end)
    if not _settings_status or not settings then
        gdebug.print_warning(
            "Failed to encode settings! " ..
            "Settings will not be saved. "
        )
    else
        awful.spawn.with_shell(string.format("mkdir -p %s && echo '%s' > %s", PATH, settings, DATA_PATH))
    end
end

function persistent:enable()
    -- Saving only once awesome exits won't work if it crashed
    gtimer.start_new(30, function()
        save(self)
        return true
    end)

    capi.awesome.connect_signal("exit", function()
        save(self)
    end)

    capi.client.connect_signal("scanned", function()
        restore(self)
    end)
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, persistent, true)

    return ret
end

if not instance then
    instance = new()
end
return instance
