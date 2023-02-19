-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
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

function persistent:save_tags()
    self.settings.tags = {}

    for _, tag in ipairs(capi.root.tags()) do
        self.settings.tags[tag.index] = {}
        self.settings.tags[tag.index].name = tag.name
        self.settings.tags[tag.index].selected = tag.selected
        self.settings.tags[tag.index].activated = tag.activated
        self.settings.tags[tag.index].screen = tag.screen.index
        self.settings.tags[tag.index].master_width_factor = tag.master_width_factor
        self.settings.tags[tag.index].layout = awful.layout.get_tag_layout_index(tag)
        self.settings.tags[tag.index].volatile = tag.volatile or false
        self.settings.tags[tag.index].gap = tag.gap
        self.settings.tags[tag.index].gap_single_client = tag.gap_single_client
        self.settings.tags[tag.index].master_fill_policy = tag.master_fill_policy
        self.settings.tags[tag.index].master_count = tag.master_count
        self.settings.tags[tag.index].column_count = tag.column_count
    end
end

function persistent:save_clients()
    self.settings.clients = {}

    for _, client in ipairs(capi.client.get()) do
        local pid = tostring(client.pid)
        self.settings.clients[pid] = {}

        -- Has to be blocking!
        local handle = io.popen(string.format("ps -p %d -o args=", client.pid))
        if handle ~= nil then
            self.settings.clients[pid].command = handle:read("*a"):gsub('^%s*(.-)%s*$', '%1')
            handle:close()
        end

        -- Properties
        for _, property in ipairs(client_properties) do
            self.settings.clients[pid][property] = client[property]
        end
        self.settings.clients[pid].screen = client.screen.index

        if client.titlebar_widget and not client.custom_titlebar then
            self.settings.clients[pid].titlebar = true
        end

        -- Tags
        self.settings.clients[pid].tags = {}
        for index, client_tag in ipairs(client:tags()) do
            self.settings.clients[pid].tags[index] = client_tag.index
        end

        -- Bling tabs
        if client.bling_tabbed and client.bling_tabbed.parent == client.window then
            self.settings.clients[pid].bling_tabbed = {}
            self.settings.clients[pid].bling_tabbed.focused_idx = client.bling_tabbed.focused_idx

            self.settings.clients[pid].bling_tabbed.clients = {}
            for index, bling_tabbed_client in ipairs(client.bling_tabbed.clients) do
                self.settings.clients[pid].bling_tabbed.clients[index] = bling_tabbed_client.window
            end
        end
    end
end

function persistent:reapply_selected_tags()
    if #self.restored_settings.selected_tags > 0 then
        awful.tag.viewnone()
    end

    for _, tag in ipairs(self.restored_settings.selected_tags) do
        awful.tag.viewtoggle(tag)
    end
end

function persistent:reapply_tags()
    self.restored_settings.selected_tags = {}

    for index, tag in ipairs(capi.root.tags()) do
        if self.restored_settings.tags[index] ~= nil then
            tag.name = self.restored_settings.tags[index].name
            tag.activated = self.restored_settings.tags[index].activated
            tag.screen = self.restored_settings.tags[index].screen
            tag.master_width_factor = self.restored_settings.tags[index].master_width_factor
            tag.layout = awful.layout.layouts[self.restored_settings.tags[index].layout]
            tag.volatile = self.restored_settings.tags[index].volatile
            tag.gap = self.restored_settings.tags[index].gap
            tag.gap_single_client = self.restored_settings.tags[index].gap_single_client
            tag.master_fill_policy = self.restored_settings.tags[index].master_fill_policy
            tag.master_count = self.restored_settings.tags[index].master_count
            tag.column_count = self.restored_settings.tags[index].column_count
            if self.restored_settings.tags[index].selected == true then
                table.insert(self.restored_settings.selected_tags, tag)
            end
        end
    end
end

function persistent:recreate_tags()
    awful.tag.viewnone()

    for _, tag in ipairs(self.restored_settings.tags) do
        awful.tag.add(tag.name, tag)
        if tag.selected == true then
            awful.tag.viewtoggle(tag)
        end
    end
end

function persistent:reapply_clients()
    self.restored_settings.clients = gtable.join(self.restored_settings.clients, self.restored_settings.new_clients)

    for _, client in ipairs(capi.client.get()) do
        local pid = tostring(client.pid)
        if self.restored_settings.clients[pid] ~= nil then
            for _, property in ipairs(client_properties) do
                client[property] = self.restored_settings.clients[pid][property]
            end
            client:move_to_screen(self.restored_settings.clients[pid].screen)
            if self.restored_settings.clients[pid].titlebar then
                awful.titlebar.show(client)
            end

            -- Tags
            gtimer.delayed_call(function()
                local tags = {}
                for _, tag in ipairs(self.restored_settings.clients[pid].tags) do
                    table.insert(tags, capi.screen[client.screen].tags[tag])
                end
                client.first_tag = tags[1]
                client:tags(tags)
            end)

            -- Bling tabbed
            local parent = client
            if self.restored_settings.clients[pid].bling_tabbed then
                for _, window in ipairs(self.restored_settings.clients[pid].bling_tabbed.clients) do
                    for _, client in ipairs(capi.client.get()) do
                        if client.window == window then
                            local focused_idx = self.restored_settings.clients[pid].bling_tabbed.focused_idx
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
    end
end

function persistent:recreate_clients()
    local clients_amount = helpers.table.length(self.restored_settings.clients)
    local index = 0

    self.restored_settings.new_clients = {}

    for pid, client in pairs(self.restored_settings.clients) do
        index = index + 1

        local has_class = false

        for _, c in ipairs(capi.client.get()) do
            if client.class == c.class then
                has_class = true
            end
        end

        if has_class == false then
            local new_pid = awful.spawn(client.command, false)
            self.restored_settings.new_clients[tostring(new_pid)] = self.restored_settings.clients[pid]
            self.restored_settings.clients[pid] = nil
        end

        if index == clients_amount then
            gtimer.start_new(0.6, function()
                self:reapply_clients()
                self:reapply_selected_tags()
                return false
            end)
        end
    end
end

function persistent:save()
    self:save_tags()
    self:save_clients()

    local json_settings = json.encode(self.settings)
    awful.spawn.with_shell(string.format("mkdir -p %s && echo '%s' > %s", PATH, json_settings, DATA_PATH))
end

function persistent:restore()
    local file = filesystem.file.new_for_path(DATA_PATH)
    file:read(function(error, content)
        if error == nil then
            self.restored_settings = json.decode(content)
            if self.restored_settings ~= nil then
                self:recreate_clients()
                self:reapply_tags()
            end
        end
    end)
end

function persistent:enable()
    capi.awesome.connect_signal("exit", function()
        self:save()
    end)

    capi.awesome.connect_signal("startup", function()
        self:restore()
    end)
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, persistent, true)

    ret.settings = {}

    return ret
end

if not instance then
    instance = new()
end
return instance
