local ui_daemon = require("daemons.system.ui")
if ui_daemon:get_double_bars() then
    require(... .. ".left")
end

require(... .. ".top")
