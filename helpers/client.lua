local awful = require("awful")
local gtable = require("gears.table")
local gmath = require("gears.math")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local capi = { client = client, mouse = mouse }

local _client = {}

function _client.find(rule)
    local function matcher(c) return awful.rules.match(c, rule) end
    local clients = client.get()
    local findex = gtable.hasitem(clients, client.focus) or 1
    local start = gmath.cycle(#clients, findex + 1)

    local matches = {}
    for c in awful.client.iterate(matcher, start) do
        matches[#matches + 1] = c
    end

    return matches
end

-- Maximizes client and also respects gaps
function _client.maximize(c)
    c.maximized = not c.maximized
    if c.maximized then
        awful.placement.maximize(c, {
            honor_padding = true,
            honor_workarea = true,
            margins = beautiful.useless_gap * 2
        })

    end
    c:raise()
end

function _client.move_to_edge(c, direction)
    -- local workarea = awful.screen.focused().workarea
    -- local client_geometry = c:geometry()
    if direction == "up" then
        local old_x = c:geometry().x
        awful.placement.top(c, {
            honor_padding = true,
            honor_workarea = true,
            honor_padding = true
        })
        c.x = old_x
        -- c:geometry({ nil, y = workarea.y + beautiful.screen_margin * 2, nil, nil })
    elseif direction == "down" then
        local old_x = c:geometry().x
        awful.placement.bottom(c, {
            honor_padding = true,
            honor_workarea = true,
            honor_padding = true
        })
        c.x = old_x
        -- c:geometry({ nil, y = workarea.height + workarea.y - client_geometry.height - beautiful.screen_margin * 2 - beautiful.border_width * 2, nil, nil })
    elseif direction == "left" then
        local old_y = c:geometry().y
        awful.placement.left(c, {
            honor_padding = true,
            honor_workarea = true,
            honor_padding = true
        })
        c.y = old_y
        -- c:geometry({ x = workarea.x + beautiful.screen_margin * 2, nil, nil, nil })
    elseif direction == "right" then
        local old_y = c:geometry().y
        awful.placement.right(c, {
            honor_padding = true,
            honor_workarea = true,
            honor_padding = true
        })
        c.y = old_y
        -- c:geometry({ x = workarea.width + workarea.x - client_geometry.width - beautiful.screen_margin * 2 - beautiful.border_width * 2, nil, nil, nil })
    end
end

-- Used as a custom command in rofi to move a window into the current tag
-- instead of following it.
-- Rofi has access to the X window id of the client.
function _client.rofi_move_client_here(window)
    local win = function(c) return awful.rules.match(c, {window = window}) end

    for c in awful.client.iterate(win) do
        c.minimized = false
        c:move_to_tag(capi.mouse.screen.selected_tag)
        capi.client.focus = c
        c:raise()
    end
end

-- Resize DWIM (Do What I Mean)
-- Resize client or factor
function _client.resize_dwim(c, direction)
    local floating_resize_amount = dpi(20)
    local tiling_resize_factor = 0.05

    if awful.layout.get(capi.mouse.screen) == awful.layout.suit.floating or
        (c and c.floating) then
        if direction == "up" then
            c:relative_move(0, 0, 0, -floating_resize_amount)
        elseif direction == "down" then
            c:relative_move(0, 0, 0, floating_resize_amount)
        elseif direction == "left" then
            c:relative_move(0, 0, -floating_resize_amount, 0)
        elseif direction == "right" then
            c:relative_move(0, 0, floating_resize_amount, 0)
        end
    else
        if direction == "up" then
            awful.client.incwfact(-tiling_resize_factor)
        elseif direction == "down" then
            awful.client.incwfact(tiling_resize_factor)
        elseif direction == "left" then
            awful.tag.incmwfact(-tiling_resize_factor)
        elseif direction == "right" then
            awful.tag.incmwfact(tiling_resize_factor)
        end
    end
end

-- Move client to screen edge, respecting the screen workarea
function _client.move_to_edge(c, direction)
    local workarea = awful.screen.focused().workarea
    if direction == "up" then
        c:geometry({nil, y = workarea.y + beautiful.useless_gap * 2, nil, nil})
    elseif direction == "down" then
        c:geometry({
            nil,
            y = workarea.height + workarea.y - c:geometry().height -
                beautiful.useless_gap * 2 - beautiful.border_width * 2,
            nil,
            nil
        })
    elseif direction == "left" then
        c:geometry({x = workarea.x + beautiful.useless_gap * 2, nil, nil, nil})
    elseif direction == "right" then
        c:geometry({
            x = workarea.width + workarea.x - c:geometry().width -
                beautiful.useless_gap * 2 - beautiful.border_width * 2,
            nil,
            nil,
            nil
        })
    end
end

-- Move client DWIM (Do What I Mean)
-- Move to edge if the client / layout is floating
-- Swap by index if maximized
-- Else swap client by direction
function _client.move_client_dwim(c, direction)
    if c.floating or
        (awful.layout.get(capi.mouse.screen) == awful.layout.suit.floating) then
        _client.move_to_edge(c, direction)
    elseif awful.layout.get(capi.mouse.screen) == awful.layout.suit.max then
        if direction == "up" or direction == "left" then
            awful.client.swap.byidx(-1, c)
        elseif direction == "down" or direction == "right" then
            awful.client.swap.byidx(1, c)
        end
    else
        awful.client.swap.bydirection(direction, c, nil)
    end
end

function _client.float_and_edge_snap(c, direction)
    -- if not c.floating then
    --     c.floating = true
    -- end
    c.floating = true
    local workarea = awful.screen.focused().workarea
    if direction == "up" then
        local axis = "horizontally"
        local f = awful.placement.scale + awful.placement.top +
                      (axis and awful.placement["maximize_" .. axis] or nil)
        local geo = f(capi.client.focus, {
            honor_padding = true,
            honor_workarea = true,
            to_percent = 0.5
        })
    elseif direction == "down" then
        local axis = "horizontally"
        local f = awful.placement.scale + awful.placement.bottom +
                      (axis and awful.placement["maximize_" .. axis] or nil)
        local geo = f(capi.client.focus, {
            honor_padding = true,
            honor_workarea = true,
            to_percent = 0.5
        })
    elseif direction == "left" then
        local axis = "vertically"
        local f = awful.placement.scale + awful.placement.left +
                      (axis and awful.placement["maximize_" .. axis] or nil)
        local geo = f(client.focus, {
            honor_padding = true,
            honor_workarea = true,
            to_percent = 0.5
        })
    elseif direction == "right" then
        local axis = "vertically"
        local f = awful.placement.scale + awful.placement.right +
                      (axis and awful.placement["maximize_" .. axis] or nil)
        local geo = f(capi.client.focus, {
            honor_padding = true,
            honor_workarea = true,
            to_percent = 0.5
        })
    end
end

function _client.run_or_raise(match, move, spawn_cmd, spawn_args)
    local matcher = function(c) return awful.rules.match(c, match) end

    -- Find and raise
    local found = false
    for c in awful.client.iterate(matcher) do
        found = true
        c.minimized = false
        if #c:tags() == 0 then
            c:move_to_tag(capi.mouse.screen.selected_tag)
        end

        if move then
            c:move_to_tag(capi.mouse.screen.selected_tag)
            capi.client.focus = c
            c:raise()
        else
            c:jump_to()
        end
        break
    end

    -- Spawn if not found
    if not found then awful.spawn.with_shell(spawn_cmd, spawn_args) end
end

function _client.float_and_resize(c, width, height)
    c.width = width
    c.height = height
    awful.placement.centered(c, {honor_workarea = true, honor_padding = true})
    awful.client.property.set(c, "floating_geometry", c:geometry())
    c.floating = true
    c:raise()
end

function _client.floating_client_placement(c)
    -- If the layout is floating or there are no other visible
    -- clients, center client
    if awful.layout.get(capi.mouse.screen) ~= awful.layout.suit.floating or #capi.mouse.screen.clients == 1 then
        return awful.placement.centered(c,{honor_padding = true, honor_workarea=true})
    end

    -- Else use this placement
    local p = awful.placement.no_overlap + awful.placement.no_offscreen
    return p(c, {honor_padding = true, honor_workarea=true, margins = beautiful.useless_gap * 2})
end

return _client