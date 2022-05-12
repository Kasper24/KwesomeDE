local awful = require("awful")
local capi = { awesome = awesome, screen = screen }

capi.screen.connect_signal("request::desktop_decoration", function(s)
    if capi.awesome.startup == true then
        awful.tag
        (
            {"1", "2", "3", "4", "5", "6", "7", "8", "9"},
            s,
            awful.layout.layouts[1]
        )
    end
end)