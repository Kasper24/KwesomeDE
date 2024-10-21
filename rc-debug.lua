-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
if os.getenv "LOCAL_LUA_DEBUGGER_VSCODE" == "1" then
    require("lldebugger").start()
end
DEBUG = true
require("rc")
