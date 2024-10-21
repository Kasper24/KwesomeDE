local gshape = require("gears.shape")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local system_daemon = require("daemons.system.system")
local library = require("library")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local breaking_changes = {
    mt = {}
}

local function separator()
    return wibox.widget {
        widget = widgets.background,
        forced_height = dpi(1),
        shape = library.ui.rrect(),
        bg = beautiful.colors.surface
    }
end

local function change_widget(message)
    return wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(15),
        {
            widget = widgets.background,
            forced_width = dpi(20),
            forced_height = dpi(20),
            shape = gshape.circle,
            bg = beautiful.colors.on_background
        },
        {
            widget = widgets.text,
            size = 15,
            text = message
        }
    }
end

local function version_widget(version)
    local layout = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        forced_width = dpi(200),
        forced_height = dpi(80),
        spacing = dpi(15),
        {
            widget = widgets.text,
            bold = true,
            size = 20,
            text = version.version .. ":"
        }
    }

    for _, change in ipairs(version.changes) do
        layout:add(change_widget(change))
    end

    return layout
end

local function new()
    local layout = wibox.widget {
        layout = wibox.layout.overflow.vertical,
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(10),
        step = 50,
        spacing = dpi(15),
    }

    local versions = system_daemon:get_versions()
    for index, version in ipairs(versions) do
        layout:add(version_widget(version))

        if index ~= #versions then
            layout:add(separator())
        end
    end

    return layout
end

function breaking_changes.mt:__call()
    return new()
end

return setmetatable(breaking_changes, breaking_changes.mt)
