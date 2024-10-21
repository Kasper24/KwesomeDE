local awful = require("awful")
local ruled = require("ruled")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local capi = {
    client = client,
    mouse = mouse
}

local _client = {}

function _client.find(rule)
    local function matcher(c)
        return ruled.client.match(c, rule)
    end
    local matches = {}
    for c in awful.client.iterate(matcher) do
        matches[#matches + 1] = c
    end

    return matches
end

function _client.move_to_edge(c, direction)
    local screen = awful.screen.focused()
    local workarea = screen.workarea
    local useless_gap = screen.selected_tag.gap

    if direction == "up" then
        c:geometry({
            nil,
            y = workarea.y + useless_gap * 2,
            nil,
            nil
        })
    elseif direction == "down" then
        c:geometry({
            nil,
            y = workarea.height + workarea.y - c:geometry().height - useless_gap * 2 - (beautiful.border_width or 0) *
                2,
            nil,
            nil
        })
    elseif direction == "left" then
        c:geometry({
            x = workarea.x + useless_gap * 2,
            nil,
            nil,
            nil
        })
    elseif direction == "right" then
        c:geometry({
            x = workarea.width + workarea.x - c:geometry().width - useless_gap * 2 - (beautiful.border_width or 0) *
                2,
            nil,
            nil,
            nil
        })
    end
end

function _client.move(c, direction)
    -- Move client DWIM (Do What I Mean)
    -- Move to edge if the client / layout is floating
    -- Swap by index if maximized
    -- Else swap client by direction

    if c.floating or (awful.layout.get(capi.mouse.screen) == awful.layout.suit.floating) then
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

function _client.resize(c, direction)
    local floating_resize_amount = dpi(20)
    local tiling_resize_factor = 0.05

    if awful.layout.get(capi.mouse.screen) == awful.layout.suit.floating or (c and c.floating) then
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

function _client.run_or_raise(match, move, spawn_cmd, spawn_args)
    local matcher = function(c)
        return awful.rules.match(c, match)
    end

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
    if not found then
        if spawn_args.shell then
            awful.spawn.with_shell(spawn_cmd)
        else
            awful.spawn(spawn_cmd, spawn_args)
        end
    end
end

function _client.float_and_resize(c, width, height)
    c.width = width
    c.height = height
    awful.placement.centered(c, {
        honor_workarea = true,
        honor_padding = true
    })
    awful.client.property.set(c, "floating_geometry", c:geometry())
    c.floating = true
    c:raise()
end

return _client
