local ui_daemon = require("daemons.system.ui")
if ui_daemon:get_bars_layout() == "vertical_horizontal" then
    require(... .. ".vertical")
    require(... .. ".horizontal")
elseif ui_daemon:get_bars_layout() == "vertical" then
    require(... .. ".vertical")
elseif ui_daemon:get_bars_layout() == "horizontal" then
    require(... .. ".horizontal")
end
