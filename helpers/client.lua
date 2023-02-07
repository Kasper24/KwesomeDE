local lgi = require("lgi")
local Gdk = lgi.require("Gdk", "3.0")
local awful = require("awful")
local gtable = require("gears.table")
local gmath = require("gears.math")
local gsurface = require("gears.surface")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local pairs = pairs
local table = table
local math = math
local capi = {
    root = root,
    client = client,
    mouse = mouse
}

local _client = {}

function _client.find(rule)
    local function matcher(c)
        return awful.rules.match(c, rule)
    end
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
    local win = function(c)
        return awful.rules.match(c, {
            window = window
        })
    end

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

-- Move client to screen edge, respecting the screen workarea
function _client.move_to_edge(c, direction)
    local workarea = awful.screen.focused().workarea
    if direction == "up" then
        c:geometry({
            nil,
            y = workarea.y + beautiful.useless_gap * 2,
            nil,
            nil
        })
    elseif direction == "down" then
        c:geometry({
            nil,
            y = workarea.height + workarea.y - c:geometry().height - beautiful.useless_gap * 2 - beautiful.border_width *
                2,
            nil,
            nil
        })
    elseif direction == "left" then
        c:geometry({
            x = workarea.x + beautiful.useless_gap * 2,
            nil,
            nil,
            nil
        })
    elseif direction == "right" then
        c:geometry({
            x = workarea.width + workarea.x - c:geometry().width - beautiful.useless_gap * 2 - beautiful.border_width *
                2,
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

function _client.float_and_edge_snap(c, direction)
    -- if not c.floating then
    --     c.floating = true
    -- end
    c.floating = true
    local workarea = awful.screen.focused().workarea
    if direction == "up" then
        local axis = "horizontally"
        local f = awful.placement.scale + awful.placement.top + (axis and awful.placement["maximize_" .. axis] or nil)
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
        local f = awful.placement.scale + awful.placement.left + (axis and awful.placement["maximize_" .. axis] or nil)
        local geo = f(client.focus, {
            honor_padding = true,
            honor_workarea = true,
            to_percent = 0.5
        })
    elseif direction == "right" then
        local axis = "vertically"
        local f = awful.placement.scale + awful.placement.right + (axis and awful.placement["maximize_" .. axis] or nil)
        local geo = f(capi.client.focus, {
            honor_padding = true,
            honor_workarea = true,
            to_percent = 0.5
        })
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
        awful.spawn(spawn_cmd, spawn_args)
    end
end

function _client.run_or_raise_with_shell(match, move, spawn_cmd)
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
        awful.spawn.with_shell(spawn_cmd)
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

function _client.floating_client_placement(c)
    -- If the layout is floating or there are no other visible
    -- clients, center client
    if awful.layout.get(capi.mouse.screen) ~= awful.layout.suit.floating or #capi.mouse.screen.clients == 1 then
        return awful.placement.centered(c, {
            honor_padding = true,
            honor_workarea = true
        })
    end

    -- Else use this placement
    local p = awful.placement.no_overlap + awful.placement.no_offscreen
    return p(c, {
        honor_padding = true,
        honor_workarea = true,
        margins = beautiful.useless_gap * 2
    })
end

function _client.get_dominant_color(client)
    local color
    -- gsurface(client.content):write_to_png(
    --     "/home/mutex/nice/" .. client.class .. "_" .. client.instance .. ".png")
    local pb
    local bytes
    local tally = {}
    local screenshot = awful.screenshot {
        client = client
    }
    screenshot:refresh()
    local content = screenshot.surface
    local cgeo = client:geometry()
    local x_offset = 2
    local y_offset = 2
    local x_lim = math.floor(cgeo.width / 2)
    for x_pos = 0, x_lim, 2 do
        for y_pos = 0, 8, 1 do
            pb = Gdk.pixbuf_get_from_surface(content, x_offset + x_pos, y_offset + y_pos, 1, 1)
            bytes = pb:get_pixels()
            color = "#" .. bytes:gsub(".", function(c)
                return ("%02x"):format(c:byte())
            end)
            if not tally[color] then
                tally[color] = 1
            else
                tally[color] = tally[color] + 1
            end
        end
    end
    local mode
    local mode_c = 0
    for kolor, kount in pairs(tally) do
        if kount > mode_c then
            mode_c = kount
            mode = kolor
        end
    end
    color = mode
    return color
end

function _client.get_sorted_clients()
    local clients = capi.client.get()

    table.sort(clients, function(a, b)
        if a.first_tag == b.first_tag then
            local a_data = _client.idx(a)
            local b_data = _client.idx(b)
            return a_data.col + a_data.idx < b_data.col + b_data.idx
        end
        return a.first_tag.index < b.first_tag.index
    end)

    return clients
end

function _client.idx(c)
    c = c or capi.client.focus
    if not c then return end

    local clients = capi.client.get()
    local idx = nil
    for k, cl in ipairs(clients) do
        if cl == c then
            idx = k
            break
        end
    end

    local t = c.screen.selected_tag
    local nmaster = t.master_count

    -- This will happen for floating or maximized clients
    if not idx then return nil end

    if idx <= nmaster then
        return {idx = idx, col=0, num=nmaster}
    end
    local nother = #clients - nmaster
    idx = idx - nmaster

    -- rather than regenerate the column number we can calculate it
    -- based on the how the tiling algorithm places clients we calculate
    -- the column, we could easily use the for loop in the program but we can
    -- calculate it.
    local ncol = t.column_count
    -- minimum number of clients per column
    local percol = math.floor(nother / ncol)
    -- number of columns with an extra client
    local overcol = math.fmod(nother, ncol)
    -- number of columns filled with [percol] clients
    local regcol = ncol - overcol

    local col = math.floor( (idx - 1) / percol) + 1
    if  col > regcol then
        -- col = math.floor( (idx - (percol*regcol) - 1) / (percol + 1) ) + regcol + 1
        -- simplified
        col = math.floor( (idx + regcol + percol) / (percol+1) )
        -- calculate the index in the column
        idx = idx - percol*regcol - (col - regcol - 1) * (percol+1)
        percol = percol+1
    else
        idx = idx - percol*(col-1)
    end

    return {idx = idx, col=col, num=percol}
end

function _client.get_client_index(client)
    -- local clients = _client.get_sorted_clients()

    for index, client1 in ipairs(_client.get_sorted_clients()) do
        if client == client1 then
            print(index)
            return index
        end
    end

    -- local data = _client.idx(client)
    -- local t = client.first_tag.index + data.col + data.idx
    -- local s= string.format("%s: tag: %s col: %s idx: %s", client.class, client.first_tag.index, data.col, data.idx)
    -- require("naughty").notification {
    --     app_font_icon = beautiful.icons.bluetooth.on,
    --     app_name = "Bluetooth",
    --     title = "Bluetooth",
    --     text = s,
    -- }
    -- print(s)
    -- print(data.col)
    -- print(data.idx)
    return t
    -- for index, c in ipairs(_client.get_sorted_clients()) do
    --     if client == c then
    --         return index
    --     end
    -- end
end

return _client
