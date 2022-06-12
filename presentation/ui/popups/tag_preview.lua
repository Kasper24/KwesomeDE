-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local bling = require("modules.bling")
local capi = { awesome = awesome, mouse = mouse, client = client }

capi.client.connect_signal("property::fullscreen", function(c)
    if c.fullscreen then
        capi.awesome.emit_signal("bling::tag_preview::visibility", awful.screen.focused(), false)
    end
end)

capi.client.connect_signal("focus", function(c)
    if c.fullscreen then
        capi.awesome.emit_signal("bling::tag_preview::visibility", awful.screen.focused(), false)
    end
end)

bling.widget.tag_preview.enable
{
    show_client_content = true,
    scale = 0.1,
    honor_padding = true,
    honor_workarea = true,
    placement_fn = function(c)
        awful.placement.top_left(c,
        {
            honor_workarea = true,
            honor_padding = true,
            offset =
            {
                y = capi.mouse.coords().y - 50
            },
        })
    end
}