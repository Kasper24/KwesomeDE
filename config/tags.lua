-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")

awful.screen.connect_for_each_screen(function(s)
    for i = 1, 8, 1  do
        awful.tag.add(i, {
            layout = awful.layout.layouts[1],
            centered_layout_master_fill_policy = "master_width_factor",
            screen = s,
            selected = i == 1 and true or false,
        })
    end
end)