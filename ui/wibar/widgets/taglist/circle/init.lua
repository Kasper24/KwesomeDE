-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local awful = require("awful")
local gshape = require("gears.shape")
local wibox = require("wibox")
local widgets = require("ui.widgets")
-- local tag_preview = require("ui.popups.tag_preview")
local beautiful = require("beautiful")
local ui_daemon = require("daemons.system.ui")
local library = require("library")
local dpi = beautiful.xresources.apply_dpi
local ipairs = ipairs
local capi = {
    client = client
}

local circle = {
    mt = {}
}

local function tag_menu(tag)
    local menu = widgets.menu {
        widgets.menu.button {
            icon = tag.icon,
            text = tag.index,
            on_release = function()
                tag:view_only()
            end
        },
        widgets.menu.button {
            text = "Toggle tag",
            on_release = function()
                awful.tag.viewtoggle(tag)
            end
        },
        widgets.menu.button {
            text = "Move focused client",
            on_release = function()
                local focused_client = capi.client.focus
                if focused_client then
                    focused_client:move_to_tag(tag)
                end
            end
        },
        widgets.menu.button {
            text = "Toggle focused client",
            on_release = function()
                local focused_client = capi.client.focus
                if focused_client then
                    focused_client:toggle_tag(tag)
                end
            end
        },
        widgets.menu.button {
            text = "Move all clients",
            on_release = function()
                for _, client in ipairs(capi.client.get()) do
                    client:move_to_tag(tag)
                end
            end
        },
        widgets.menu.button {
            text = "Toggle all clients",
            on_release = function()
                for _, client in ipairs(capi.client.get()) do
                    client:toggle_tag(tag)
                end
            end
        },
    }

    return menu
end

local function update_taglist(self, tag)
    local clients = tag:clients()

    if #clients > 0 then
        local tag_has_non_skip_taskbar_client = false
        for _, client in ipairs(clients) do
            if not client.skip_taskbar then
                tag_has_non_skip_taskbar_client = true
                break
            end
        end
        if tag_has_non_skip_taskbar_client then
            self.widget:turn_on()
        else
            self.widget:turn_off()
        end
    else
        self.widget:turn_off()
    end

    if tag.selected then
        self.size_animation:set(dpi(40))
    else
        self.size_animation:set(dpi(15))
    end
end

local function tag_widget(self, tag, direction)
    local menu = tag_menu(tag)

    local widget = wibox.widget {
        widget = widgets.button.state,
        forced_width = dpi(20),
        forced_height = dpi(40),
        normal_shape = gshape.rounded_rect,
        color = beautiful.colors.on_surface,
        on_color = beautiful.colors.accent,
        -- on_hover = function()
        --     if #tag:clients() > 0 then
        --         tag_preview:show(tag, {
        --             wibox = awful.screen.focused().vertical_wibar,
        --             widget = self,
        --             offset = {
        --                 x = dpi(70),
        --                 y = dpi(70)
        --             }
        --         })
        --     end
        -- end,
        on_leave = function()
            -- tag_preview:hide()
        end,
        on_release = function()
            library.misc.tag_back_and_forth(tag.index)
            -- tag_preview:hide()
        end,
        on_secondary_release = function(self)
            local coords = nil
            if ui_daemon:get_bars_layout() == "horizontal" then
                coords = library.ui.get_widget_geometry_in_device_space({wibox = awful.screen.focused().horizontal_wibar}, self)
                coords.y = coords.y + awful.screen.focused().horizontal_wibar.y
                if ui_daemon:get_horizontal_bar_position() == "top" then
                    coords.y = coords.y + dpi(65)
                else
                    coords.y = coords.y + -dpi(190)
                end
            else
                coords = library.ui.get_widget_geometry_in_device_space({wibox = awful.screen.focused().vertical_wibar}, self)
                coords.x = coords.x + dpi(50)
            end

            menu:toggle{coords = coords}
            -- tag_preview:hide()
        end,
        on_scroll_up = function()
            awful.tag.viewprev(tag.screen)
        end,
        on_scroll_down = function()
            awful.tag.viewnext(tag.screen)
        end,
    }

    local prop = direction == "horizontal" and "forced_width" or "forced_height"

    self.size_animation = library.animation:new {
        duration = 0.2,
        easing = library.animation.easing.linear,
        update = function(self, pos)
            widget[prop] = pos
        end
    }

    self:set_widget(widget)
end

local function new(screen)
    local direction = ui_daemon:get_bars_layout()

    local tag_margins = direction == "horizontal" and
        { top = dpi(25), bottom = dpi(25)} or
        { left = dpi(25), right = dpi(25)}

    return wibox.widget {
        widget = wibox.container.rotate,
        direction = (ui_daemon:get_horizontal_bar_position() == "bottom" and
            ui_daemon:get_bars_layout() == "vertical_horizontal") and "south" or "north",
        {
            widget = wibox.container.margin,
            -- margins = tags_margins,
            {
                widget = awful.widget.taglist {
                    screen = screen,
                    filter = awful.widget.taglist.filter.all,
                    layout = {
                        layout = direction == "horizontal" and wibox.layout.fixed.horizontal or wibox.layout.fixed.vertical,
                        spacing = dpi(15)
                    },
                    widget_template = {
                        widget = wibox.container.margin,
                        margins = tag_margins,
                        create_callback = function(self, tag, index, tags)
                            tag_widget(self, tag, direction)
                            update_taglist(self, tag)
                        end,
                        update_callback = function(self, tag, index, tags)
                            update_taglist(self, tag)
                        end
                    }
                }
            }
        }
    }
end

function circle.mt:__call(...)
    return new(...)
end

return setmetatable(circle, circle.mt)
