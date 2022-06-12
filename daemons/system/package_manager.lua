-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local helpers = require("helpers")

local package_manager = { }
local instance = nil

local function apt()
    awful.spawn.easy_async_with_shell("apt-cache stats", function(stdout)
        local packages_count = stdout:gsub("Total package names: (.*) ")
        self:emit_signal("update", packages_count)
    end)
end

local function pacman(self)
    awful.spawn.easy_async_with_shell("sudo pacman -Qq | wc -l", function(packages_count)
        packages_count = packages_count:gsub('^%s*(.-)%s*$', '%1')
        awful.spawn.easy_async_with_shell("sudo pacman -Qu | wc -l", function(outdated_package_count)
            outdated_package_count = outdated_package_count:gsub('^%s*(.-)%s*$', '%1')
            self:emit_signal("update", packages_count, outdated_package_count)
        end)
    end)
end

local function new()
    local ret = gobject{}
    gtable.crush(ret, package_manager, true)

    awful.spawn.easy_async_with_shell('lsb_release -a | grep "Distributor ID:"', function(stdout)
        local distro = helpers.string.trim(stdout:match("Distributor ID:(.*)"))
        if distro == "Arch" then
            pacman(ret)
        elseif distro == "Ubuntu" or distro == "Debian" or distro == "PopOS" then
            apt(ret)
        end
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance