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

local taglist = {
    mt = {}
}

local TAGLIST_ICONS = {beautiful.icons.firefox, beautiful.icons.vscode, beautiful.icons.git,
beautiful.icons.discord, beautiful.icons.spotify, beautiful.icons.steam,
beautiful.icons.gamepad_alt, beautiful.icons.lights_holiday}

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
    local button = wibox.widget {
        widget = widgets.button.text.state,
        id = "button",
        icon = TAGLIST_ICONS[index],
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
        on_release = function(self, lx, ly, button, mods, find_widgets_result)
            if button == 1 then
                helpers.misc.tag_back_and_forth(tag.index)
                tag_preview:hide()
            elseif button == 3 then
                awful.tag.viewtoggle(tag)
            elseif button == 4 then
                awful.tag.viewnext(tag.screen)
            elseif button == 5 then
                awful.tag.viewprev(tag.screen)
            end
        end
    }

    local indicator = wibox.widget {
        widget = wibox.container.place,
        halign = "right",
        valign = "center",
        {
            widget = wibox.container.background,
            forced_width = dpi(5),
            shape = helpers.ui.rrect(beautiful.border_radius),
            bg = TAGLIST_ICONS[index].color
        }
    }

    local stack = wibox.widget {
        widget = wibox.layout.stack,
        button,
        indicator
    }

    self.indicator_animation = helpers.animation:new{
        duration = 0.2,
        easing = helpers.animation.easing.linear,
        update = function(self, pos)
            indicator.children[1].forced_height = pos
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