-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local tag_preview = require("ui.popups.tag_preview")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local ipairs = ipairs
local capi = {
    client = client
}

local taglist = {
    mt = {}
}

local function tag_menu(tag)
    local menu = widgets.menu {
        widgets.menu.button {
            icon = tag.font_icon,
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
    if #tag:clients() == 0 then
        self.indicator_animation:set(dpi(0))
    else
        self.indicator_animation:set(dpi(40))
    end

    if tag.selected then
        self.widget.children[1]:turn_on()
    else
        self.widget.children[1]:turn_off()
    end
end

local function tag_widget(self, tag, index)
    local menu = tag_menu(tag)

    local button = wibox.widget {
        widget = widgets.button.text.state,
        id = "button",
        icon = tag.font_icon,
        on_normal_bg = tag.font_icon.color,
        text_on_normal_bg = beautiful.colors.transparent,
        on_hover = function()
            if #tag:clients() > 0 then
                tag_preview:show(tag, {
                    wibox = awful.screen.focused().left_wibar,
                    widget = self,
                    offset = {
                        x = dpi(70),
                        y = dpi(70)
                    }
                })
            end
        end,
        on_leave = function()
            tag_preview:hide()
        end,
        on_release = function()
            helpers.misc.tag_back_and_forth(tag.index)
            tag_preview:hide()
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
            tag_preview:hide()
        end,
        on_scroll_up = function()
            awful.tag.viewprev(tag.screen)
        end,
        on_scroll_down = function()
            awful.tag.viewnext(tag.screen)
        end
    }

    local indicator = wibox.widget {
        widget = widgets.background,
        id = "background",
        forced_width = dpi(5),
        shape = helpers.ui.rrect(),
        bg = tag.font_icon.color
    }

    local stack = wibox.widget {
        widget = wibox.layout.stack,
        button,
        {
            widget = wibox.container.place,
            halign = "right",
            valign = "center",
            indicator
        }
    }

    self.indicator_animation = helpers.animation:new{
        duration = 0.2,
        easing = helpers.animation.easing.linear,
        update = function(self, pos)
            indicator.forced_height = pos
        end
    }

    self:set_widget(stack)
end

local function new(s)
    return awful.widget.taglist {
        screen = s,
        filter = awful.widget.taglist.filter.all,
        layout = {
            layout = wibox.layout.fixed.vertical
        },
        widget_template = {
            widget = wibox.container.margin,
            forced_width = dpi(60),
            forced_height = dpi(60),
            create_callback = function(self, tag, index, tags)
                tag_widget(self, tag, index)
                update_taglist(self, tag)
            end,
            update_callback = function(self, tag, index, tags)
                update_taglist(self, tag)
            end
        }
    }
end

function taglist.mt:__call(...)
    return new(...)
end

return setmetatable(taglist, taglist.mt)