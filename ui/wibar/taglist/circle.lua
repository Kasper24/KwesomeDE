-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gshape = require("gears.shape")
local wibox = require("wibox")
local widgets = require("ui.widgets")
-- local tag_preview = require("ui.popups.tag_preview")
local beautiful = require("beautiful")
local ui_daemon = require("daemons.system.ui")
local helpers = require("helpers")
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

    local has_clients = (#clients == 1 and clients[1].skip_taskbar ~= true) or #clients > 1

    if has_clients then
        self.widget:turn_on()
    else
        self.widget:turn_off()
    end

    if tag.selected then
        self.size_animation:set(dpi(40))
        self.widget:turn_on()
    else
        self.size_animation:set(dpi(20))
        if not has_clients then
            self.widget:turn_off()
        end
    end
end

local function tag_widget(self, tag, accent_color, direction)
    local menu = tag_menu(tag)

    local widget = wibox.widget {
        widget = widgets.button.state,
        forced_width = dpi(30),
        forced_height = dpi(30),
        normal_shape = gshape.circle,
        color = beautiful.colors.on_surface,
        on_color = accent_color,
        -- on_hover = function()
        --     if #tag:clients() > 0 then
        --         tag_preview:show(tag, {
        --             wibox = awful.screen.focused().left_wibar,
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
            helpers.misc.tag_back_and_forth(tag.index)
            -- tag_preview:hide()
        end,
        on_secondary_release = function(self)
            menu:toggle{
                wibox = awful.screen.focused().left_wibar,
                widget = self,
                offset = {
                    x = dpi(70),
                    y = dpi(70),
                }
            }
            -- tag_preview:hide()
        end,
        on_scroll_up = function()
            awful.tag.viewprev(tag.screen)
        end,
        on_scroll_down = function()
            awful.tag.viewnext(tag.screen)
        end,
        {
            widget = wibox.container.margin,
            margins = dpi(15),

            {
                widget = widgets.background,
                bg = "#FF0000",
            }
        }
    }

    local prop = direction == "horizontal" and "forced_width" or "forced_height"
    self.size_animation = helpers.animation:new {
        duration = 0.2,
        easing = helpers.animation.easing.linear,
        update = function(self, pos)
            widget[prop] = pos
        end
    }

    self:set_widget(widget)
end

local function new(screen, direction)
    local accent_color = beautiful.colors.random_accent_color()

    return wibox.widget {
        widget = wibox.container.margin,
        margins = { top = ui_daemon:get_double_bars() and dpi(15) or 0},
        {
            widget = awful.widget.taglist {
                screen = screen,
                filter = awful.widget.taglist.filter.all,
                layout = {
                    layout = direction == "horizontal" and wibox.layout.fixed.horizontal or wibox.layout.fixed.vertical,
                    spacing = dpi(15)
                },
                widget_template = {
                    widget = widgets.background,
                    create_callback = function(self, tag, index, tags)
                        tag_widget(self, tag, accent_color, direction)
                        update_taglist(self, tag)
                    end,
                    update_callback = function(self, tag, index, tags)
                        update_taglist(self, tag)
                    end
                }
            }
        }
    }
end

function circle.mt:__call(...)
    return new(...)
end

return setmetatable(circle, circle.mt)
