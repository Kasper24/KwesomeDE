-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local bling = require("modules.bling")
local machi = require("modules.layout-machi")
local capi = { tag = tag }

capi.tag.connect_signal("request::default_layouts", function()
    awful.layout.append_default_layouts
    ({
            awful.layout.suit.tile.right, -- The main tile algo, on the right.
            -- awful.layout.suit.tile.left, -- The main tile algo, on the left.
            -- awful.layout.suit.tile.bottom, -- The main tile algo, on the bottom.
            -- awful.layout.suit.tile.top, -- The main tile algo, on the top.
            -- awful.layout.suit.corner.nw, --Corner layout.
            -- awful.layout.suit.corner.ne, -- Corner layout.
            -- awful.layout.suit.corner.sw,	-- Corner layout.
            -- awful.layout.suit.corner.se, -- Corner layout.
            -- awful.layout.suit.fair, -- The fair layout.
            -- awful.layout.suit.fair.horizontal, -- The horizontal fair layout.
            awful.layout.suit.floating, -- The floating layout.
            -- awful.layout.suit.magnifier, -- The magnifier layout.
            -- awful.layout.suit.max, -- Maximized layout.
            -- awful.layout.suit.max.fullscreen, -- Fullscreen layout.
            -- awful.layout.suit.spiral.dwindle, -- Dwindle layout.
            -- bling.layout.mstab,
            bling.layout.centered,
            bling.layout.vertical,
            bling.layout.horizontal,
            bling.layout.equalarea,
            bling.layout.deck,
            machi.default_layout,
    })
end)

machi.editor.nested_layouts["4"] = bling.layout.deck