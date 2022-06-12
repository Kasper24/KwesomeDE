-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local Gio = require("lgi").Gio
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local helpers = require("helpers")
local inotify = require("services.inotify")
local ipairs = ipairs
local pairs = pairs
local os = os
local capi = { screen = screen }

local desktop = { }
local instance = nil

local grid = {}
local desktop_icons = {}

local DATA_PATH = helpers.filesystem.get_cache_dir("desktop") .. "data.json"
local DESKTOP_PATH = "/home/" .. os.getenv("USER") .. "/Desktop"

local function get_grid_pos_from_real_pos(self, pos)
    return
    {
        x = pos.x / self._private.cell_size,
        y = pos.y / self._private.cell_size
    }
end

function desktop:ask_for_new_position(widget, path)
    local new_x = helpers.misc.round_by_factor(widget.x, self._private.cell_size)
    local new_y = helpers.misc.round_by_factor(widget.y, self._private.cell_size)

    local new_grid_pos = get_grid_pos_from_real_pos(self, {x = new_x, y = new_y})

    if  (new_x >= awful.screen.focused().left_wibar.maximum_width) and
        (new_y >= awful.screen.focused().top_wibar.maximum_height) and
        (grid[new_grid_pos.x][new_grid_pos.y].empty == true)
    then
        local old_grid_pos = get_grid_pos_from_real_pos(self, widget.pos_before_move)
        grid[old_grid_pos.x][old_grid_pos.y].empty = true
        grid[new_grid_pos.x][new_grid_pos.y].empty = false

        desktop_icons[path].x = new_grid_pos.x
        desktop_icons[path].y = new_grid_pos.y
        helpers.filesystem.save_file(
            DATA_PATH,
            helpers.json.encode(desktop_icons, { indent = true })
        )

        return
        {
            x = new_x,
            y = new_y
        }
    else
        return
        {
            x = widget.pos_before_move.x,
            y = widget.pos_before_move.y
        }
    end
end

local function get_position_for_new_desktop_file()
    for row, _ in ipairs(grid) do
        for column, _ in ipairs(grid[row]) do
            if grid[row][column].empty == true then
                return grid[row][column]
            end
        end
    end
end

local function on_desktop_icon_added(self, pos, path, name, mimetype)
    grid[pos.x][pos.y].empty = false
    desktop_icons[path] = { x = pos.x, y = pos.y }
    self:emit_signal(
        "new",
        {
            x = pos.x * self._private.cell_size,
            y = pos.y * self._private.cell_size
        },
        path,
        name,
        mimetype
    )
    helpers.filesystem.save_file(
        DATA_PATH,
        helpers.json.encode(desktop_icons, { indent = true })
    )
end


local function on_desktop_icon_removed(self, path)
    self:emit_signal(path .. "_removed")

    grid[desktop_icons[path].x][desktop_icons[path].y].empty = true

    desktop_icons[path] = nil
    helpers.filesystem.save_file(
        DATA_PATH,
        helpers.json.encode(desktop_icons, { indent = true })
    )
end

local function watch_desktop_directory(self)
    local watcher = inotify:watch(DESKTOP_PATH,
    {
        inotify.Events.create,
        inotify.Events.delete,
        inotify.Events.moved_from,
        inotify.Events.moved_to,
    })

    watcher:connect_signal("event", function(_, event, path, file)
        if  event == inotify.Events.create or event == inotify.Events.moved_to then
            local mimetype = Gio.content_type_guess(path)
            on_desktop_icon_added(self, get_position_for_new_desktop_file(), path, file, mimetype)
        elseif event == inotify.Events.create .. ",isdir" or event == inotify.Events.moved_to .. ",isdir" then
            on_desktop_icon_added(self, get_position_for_new_desktop_file(), path, file, "folder")
        elseif  event == inotify.Events.delete or event == inotify.Events.moved_from  or
                event == inotify.Events.delete ..",isdir" or event == inotify.Events.moved_from ..",isdir"
        then
            on_desktop_icon_removed(self, path)
        end
    end)
end

local function scan_for_desktop_files_on_init(self)
    local content = helpers.filesystem.read_file_block(DATA_PATH)
    local old_desktop_icons = {}
    if content ~= nil then
        local data = helpers.json.decode(content)
        if data ~= nil then
            old_desktop_icons = data
        end
    end

    helpers.filesystem.scan_with_folders(DESKTOP_PATH, function(files, folders)
        for _, path in pairs(files) do
            if path:find("/home/" .. os.getenv("USER") .. "/Desktop/.", 1, true) == nil then
                local name = path:sub(helpers.string.find_last(path, "/") + 1, #path)
                local mimetype = Gio.content_type_guess(path)
                local pos = nil
                if old_desktop_icons[path] ~= nil then
                    pos = old_desktop_icons[path]
                else
                    pos = get_position_for_new_desktop_file()
                end
                on_desktop_icon_added(self, pos, path, name, mimetype)
            end
        end

        for _, path in pairs(folders) do
            if path:find("/home/" .. os.getenv("USER") .. "/Desktop/.", 1, true) == nil then
                local name = path:sub(helpers.string.find_last(path, "/") + 1, #path)
                local pos = nil
                if old_desktop_icons[path] ~= nil then
                    pos = old_desktop_icons[path]
                else
                    pos = get_position_for_new_desktop_file()
                end
                on_desktop_icon_added(self, pos, path, name, "folder")
            end
        end
    end, false)
end

local function generate_grid()
    local rows = (capi.screen.primary.geometry.width - 100) / 100
    local columns = (capi.screen.primary.geometry.height - 100) / 100
    for i = 1, rows  do
        grid[i] = {}
        for j = 1, columns do
            grid[i][j] = { x = i, y = j, empty = true }
        end
    end
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, desktop, true)

    ret._private = {}
    ret._private.cell_size = 100

    generate_grid()
    scan_for_desktop_files_on_init(ret)
    watch_desktop_directory(ret)

    return ret
end

if not instance then
    instance = new()
end
return instance