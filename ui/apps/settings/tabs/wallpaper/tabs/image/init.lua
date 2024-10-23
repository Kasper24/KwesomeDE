local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local wallpaper_tab = require("ui.apps.settings.tabs.wallpaper.tabs")
local theme_daemon = require("daemons.system.theme")
local library = require("library")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local image = {
    mt = {}
}

local function new()
    return wallpaper_tab("image", function(entry)
        local widget = nil
        local button = wibox.widget {
            widget = widgets.button.state,
            id = "button",
            on_color = beautiful.icons.computer.color,
            halign = "center",
            on_release = function()
                widget:select()
            end,
            {
                widget = wibox.widget.imagebox,
                clip_shape = library.ui.rrect(),
                horizontal_fit_policy = "fit",
                vertical_fit_policy = "fit",
                image = entry.thumbnail
            }
        }

        local name = wibox.widget {
            widget = widgets.text,
            halign = "center",
            size = 12,
            text = entry.name
        }

        widget = wibox.widget {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(5),
            button,
            name
        }

        widget:connect_signal("select", function()
            button:turn_on()
            theme_daemon:set_selected_colorscheme(entry.path, "image")
        end)

        widget:connect_signal("unselect", function()
            button:turn_off()
        end)

        return widget
    end)
end

function image.mt:__call()
    return new()
end

return setmetatable(image, image.mt)
