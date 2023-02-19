local awful = require("awful")
local filesystem = require("external.filesystem")
local tonumber = tonumber
local string = string

local _run = {}

local AWESOME_SENSIBLE_TERMINAL_PATH = filesystem.filesystem.get_awesome_config_dir("scripts") .. "awesome-sensible-terminal"

function _run.run_once_pgrep(findme, cmd)
    awful.spawn.with_shell(string.format("pgrep -u $USER -x %s > /dev/null || (%s)", findme, cmd))
end

function _run.run_once_ps(findme, cmd)
    awful.spawn.easy_async_with_shell(string.format("ps -C %s|wc -l", findme), function(stdout)
        if tonumber(stdout) ~= 2 then
            awful.spawn(cmd, false)
        end
    end)
end

function _run.run_once_grep(command)
    awful.spawn.easy_async_with_shell(string.format("ps aux | grep '%s' | grep -v 'grep'", command), function(stdout)
        if stdout == "" or stdout == nil then
            awful.spawn(command, false)
        end
    end)
end

function _run.is_running(command, callback)
    awful.spawn.easy_async(string.format("pidof -s %s", command), function(stdout)
        callback(stdout ~= "")
    end)
end

function _run.is_pid_running(pid, callback)
    awful.spawn.easy_async_with_shell(string.format("ps -o pid= -p %s", pid), function(stdout)
        -- If empty, program is not running
        callback(stdout ~= "")
    end)
end

function _run.is_installed(program, callback)
    awful.spawn.easy_async(string.format("which %s", program), function(stdout, stderr)
        callback(stderr == "")
    end)
end

function _run.exec_terminal_app(app)
    awful.spawn.with_shell(AWESOME_SENSIBLE_TERMINAL_PATH .. " -e " .. app)
end

return _run
