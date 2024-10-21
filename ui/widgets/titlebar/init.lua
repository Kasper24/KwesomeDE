-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local setmetatable = setmetatable

local titlebar = {
    mt = {}
}

local function new(c, args)
    local widget = awful.titlebar(c, args)

    c.titlebar_widget = widget
    c.titlebar_size = args.size

    return widget
end

local function get_titlebar_function(c, position)
    if position == "left" then
        return c.titlebar_left
    elseif position == "right" then
        return c.titlebar_right
    elseif position == "top" then
        return c.titlebar_top
    elseif position == "bottom" then
        return c.titlebar_bottom
    else
        error("Invalid titlebar position '" .. position .. "'")
    end
end

local function load_titlebars(c, hide_all, keep, context)
    if c._request_titlebars_called then return false end

    c:emit_signal("request::titlebars", context, {})

    if hide_all then
        -- Don't bother checking if it has been created, `.hide` don't works
        -- anyway.
        for _, tb in ipairs {"top", "bottom", "left", "right"} do
            if tb ~= keep then
                awful.titlebar.hide(c, tb)
            end
        end
    end

    c._request_titlebars_called = true

    return true
end

function awful.titlebar.toggle(c, position)
    position = position or "top"
    if load_titlebars(c, true, position, "toggle") then
        c.titlebar_enabled = true
        return
    end
    local _, size = get_titlebar_function(c, position)(c)
    if size == 0 then
        awful.titlebar.show(c, position)
        c.titlebar_enabled = true
    else
        awful.titlebar.hide(c, position)
        c.titlebar_enabled = false
    end
end

function titlebar.mt:__call(...)
    return new(...)
end

return setmetatable(titlebar, titlebar.mt)