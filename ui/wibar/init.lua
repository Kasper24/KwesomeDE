local ui_daemon = require("daemons.system.ui")
if ui_daemon:get_bars_layout() == "vertical_horizontal" then
    require(... .. ".left")
    require(... .. ".top")
elseif ui_daemon:get_bars_layout() == "vertical" then
    require(... .. ".left")
elseif ui_daemon:get_bars_layout() == "horizontal" then
    require(... .. ".top")
end
