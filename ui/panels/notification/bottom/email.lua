-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local email_daemon = require("daemons.web.email")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local collectgarbage = collectgarbage
local setmetatable = setmetatable
local tostring = tostring
local ipairs = ipairs

local email = {
    mt = {}
}

local function email_widget(email)
    local halign = helpers.string.contain_right_to_left_characters(email.title) and "right" or "left"

    local name_halign = "left"
    if not helpers.string.contain_right_to_left_characters(email.author.name) then
        name_halign = halign
    end

    local title_halign = "left"
    if not helpers.string.contain_right_to_left_characters(email.title) then
        title_halign = halign
    end

    local author = wibox.widget {
        widget = widgets.text,
        halign = name_halign,
        size = 15,
        bold = true,
        text = email.author.name
    }

    local time = wibox.widget {
        widget = widgets.text,
        halign = halign,
        size = 12,
        italic = true,
        text = helpers.string.to_time_ago(email.modified)
    }

    local title = wibox.widget {
        widget = widgets.text,
        halign = title_halign,
        size = 12,
        bold = true,
        text = tostring(email.title)
    }

    local summary = wibox.widget {
        widget = widgets.text,
        halign = "left",
        size = 12,
        text = tostring(email.summary)
    }

    return wibox.widget {
        widget = widgets.button.elevated.normal,
        forced_height = dpi(150),
        on_release = function()
            email_daemon:open(email)
        end,
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(5),
            author,
            time,
            title,
            summary
        }
    }
end

local function new()
    local spinning_circle = widgets.spinning_circle {
        forced_width = dpi(150),
        forced_height = dpi(600)
    }

    local error_icon = wibox.widget {
        widget = wibox.container.place,
        halign = "center",
        valign = "center",
        {
            widget = widgets.text,
            halign = "center",
            icon = beautiful.icons.circle_exclamation,
            size = 120
        }
    }

    local scrollbox = wibox.widget {
        layout = widgets.overflow.vertical,
        spacing = dpi(10),
        scrollbar_widget = widgets.scrollbar,
        scrollbar_width = dpi(10),
        step = 50
    }

    local widget = wibox.widget {
        layout = wibox.layout.stack,
        top_only = true,
        spinning_circle,
        error_icon,
        scrollbox
    }

    email_daemon:connect_signal("error", function()
        spinning_circle:stop()
        widget:raise_widget(error_icon)
    end)

    email_daemon:connect_signal("emails", function(self, emails)
        spinning_circle:stop()
        for _, email in ipairs(emails) do
            scrollbox:add(email_widget(email))
        end
        widget:raise_widget(scrollbox)
    end)

    email_daemon:connect_signal("new_email", function(self, email)
        scrollbox:insert(1, email_widget(email))
        widget:raise_widget(scrollbox)
        spinning_circle:stop()
    end)


    return widget
end

function email.mt:__call()
    return new()
end

return setmetatable(email, email.mt)
