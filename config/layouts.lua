-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local bling = require("external.bling")
local machi = require("external.layout-machi")
local treetile = require("external.awesome-treetile")
local capi = {
	tag = tag,
}

treetile.focusnew = true
treetile.direction = "right"

capi.tag.connect_signal("request::default_layouts", function()
	awful.layout.append_default_layouts({
		awful.layout.suit.tile.right,
		treetile,
		-- awful.layout.suit.tile.left,
		-- awful.layout.suit.tile.bottom,
		-- awful.layout.suit.tile.top,
		-- awful.layout.suit.corner.nw,.
		-- awful.layout.suit.corner.ne,
		-- awful.layout.suit.corner.sw,
		-- awful.layout.suit.corner.se,
		-- awful.layout.suit.fair,
		-- awful.layout.suit.fair.horizontal,
		-- awful.layout.suit.magnifier,
		-- awful.layout.suit.max,
		-- awful.layout.suit.max.fullscreen,
		-- awful.layout.suit.spiral.dwindle,
		-- bling.layout.mstab,
		bling.layout.centered,
		bling.layout.vertical,
		bling.layout.horizontal,
		bling.layout.equalarea,
		bling.layout.deck,
		awful.layout.suit.floating,
		machi.default_layout,
	})
end)

machi.editor.nested_layouts["4"] = bling.layout.deck
