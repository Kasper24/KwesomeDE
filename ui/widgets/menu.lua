-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local wibox = require("wibox")
local ebwidget = require("ui.widgets.button.elevated")
local twidget = require("ui.widgets.text")
local cbwidget = require("ui.widgets.checkbox")
local pwidget = require("ui.widgets.popup")
local bwidget = require("ui.widgets.background")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable
local ipairs = ipairs
local capi = {
    awesome = awesome,
    tag = tag,
    client = client,
    mouse = mouse
}

local menu = {
    mt = {}
}

function menu:set_pos(args)
    args = args or {}

    local coords = args.coords
    local wibox = args.wibox
    local widget = args.widget
    local offset = args.offset or {
        x = 0,
        y = 0
    }

    if offset.x == nil then
        offset.x = 0
    end
    if offset.y == nil then
        offset.y = 0
    end

    local screen_workarea = awful.screen.focused().workarea
    local screen_w = screen_workarea.x + screen_workarea.width
    local screen_h = screen_workarea.y + screen_workarea.height

    if not coords and wibox and widget then
        coords = helpers.ui.get_widget_geometry(wibox, widget)
    else
        coords = args.coords or capi.mouse.coords()
    end

    if coords.x + self.width > screen_w then
        if self.parent_menu ~= nil then
            self.x = coords.x - (self.width * 2) - offset.x
        else
            self.x = coords.x - self.width + offset.x
        end
    else
        self.x = coords.x + offset.x
    end

    if coords.y + self.height > screen_h then
        self.y = screen_h - self.height + offset.y
    else
        self.y = coords.y + offset.y
    end
end

function menu:hide_parents_menus()
    if self.parent_menu ~= nil then
        self.parent_menu:hide(true)
    end
end

function menu:hide_children_menus()
    for _, button in ipairs(self.widget.children) do
        if button.sub_menu ~= nil then
            button.sub_menu:hide()
            button:get_children_by_id("button")[1]:turn_off()
        end
    end
end

function menu:show(args)
    if self.visible == true then
        return
    end

    -- Hide sub menus belonging to the menu of self
    if self.parent_menu ~= nil then
        for _, button in ipairs(self.parent_menu.widget.children) do
            if button.sub_menu ~= nil and button.sub_menu ~= self then
                button.sub_menu:hide()
                button:get_children_by_id("button")[1]:turn_off()
            end
        end
    end

    self:set_pos(args)
    self.animation:set(self.menu_height)
    self.visible = true
    self._private.can_hide = false

    gtimer.start_new(0.05, function()
        self._private.can_hide = true
        return false
    end)

    capi.awesome.emit_signal("menu::toggled_on", self)
end

function menu:hide(hide_parents)
    if self.visible == false then
        return
    end

    self.animation.pos = 1
    self.widget.forced_height = 1
    self.visible = false

    self:hide_children_menus()
    if hide_parents == true then
        self:hide_parents_menus()
    end
end

function menu:toggle(args)
    if self.visible == true then
        self:hide()
    else
        self:show(args)
    end
end

function menu:add(widget, index)
    if widget.sub_menu then
        widget.sub_menu.parent_menu = self
    end

    if widget:get_children_by_id("button")[1] ~= nil then
        widget:get_children_by_id("button")[1].menu = self
    end

    local height_without_dpi = widget.forced_height * 96 / beautiful.xresources.get_dpi()
    self.menu_height = self.menu_height + height_without_dpi

    if index == nil then
        self.widget:add(widget)
    else
        self.widget:insert(index, widget)
    end

    if self.animation:state() == true then
        self.animation:stop()
        self.animation:set(self.menu_height)
    elseif self.visible then
        self.widget.forced_height = dpi(self.menu_height)
    end
end

function menu:remove(index)
    self.menu_height = self.menu_height - self.widget.children[index].forced_height
    self.widget:remove(index)
end

function menu:reset()
    self.menu_height = 0
    self.widget:reset()
end

function menu.menu(widgets, width)
    local menu_container = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        forced_height = 0
    }

    local widget = pwidget {
        x = 32500,
        visible = false,
        ontop = true,
        minimum_width = width or dpi(300),
        maximum_width = width or dpi(300),
        shape = helpers.ui.rrect(),
        bg = beautiful.colors.background,
        widget = menu_container
    }
    gtable.crush(widget, menu, true)

    -- -- Setup animations
    widget.animation = helpers.animation:new{
        pos = 1,
        easing = helpers.animation.easing.outInCirc,
        duration = 0.4,
        update = function(self, pos)
            menu_container.forced_height = dpi(pos)
        end
    }

    capi.awesome.connect_signal("root::pressed", function()
        if widget._private.can_hide == true then
            widget:hide(true)
        end
    end)

    capi.client.connect_signal("button::press", function()
        if widget._private.can_hide == true then
            widget:hide(true)
        end
    end)

    capi.tag.connect_signal("property::selected", function(t)
        widget:hide(true)
    end)

    capi.awesome.connect_signal("menu::toggled_on", function(menu)
        if menu ~= widget and menu.parent_menu == nil then
            widget:hide(true)
        end
    end)

    widget.menu_height = 0
    for _, menu_widget in ipairs(widgets) do
        widget:add(menu_widget)
    end

    return widget
end

function menu.sub_menu_button(args)
    args = args or {}

    args.icon = args.icon or nil
    args.text = args.text or ""
    args.sub_menu = args.sub_menu or nil

    local icon = args.icon ~= nil and wibox.widget {
        widget = twidget,
        scale = 0.5,
        icon = args.icon
    } or nil

    local text = wibox.widget {
        widget = twidget,
        size = 12,
        text = args.text
    }

    local arrow = wibox.widget {
        widget = twidget,
        icon = beautiful.icons.chevron.right,
        color = beautiful.colors.on_background,
        size = 12
    }

    local widget = wibox.widget {
        widget = wibox.container.margin,
        forced_height = dpi(45),
        sub_menu = args.sub_menu,
        margins = dpi(5),
        {
            widget = ebwidget.state,
            id = "button",
            on_hover = function(self)
                local coords = helpers.ui.get_widget_geometry(self.menu, self)
                coords.x = coords.x + self.menu.x + self.menu.width
                coords.y = coords.y + self.menu.y
                args.sub_menu:show{
                    coords = coords,
                    offset = {
                        x = -5
                    }
                }
                self:turn_on()
            end,
            {
                layout = wibox.layout.align.horizontal,
                forced_width = dpi(270),
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = dpi(15),
                    icon,
                    text
                },
                nil,
                arrow
            }
        }
    }

    return widget
end

function menu.button(args)
    args = args or {}

    args.icon = args.icon or nil
    args.image = args.image
    args.text = args.text or ""
    args.on_release = args.on_release or nil

    local icon = nil

    if args.icon ~= nil then
        icon = wibox.widget {
            widget = twidget,
            scale = 0.5,
            icon = args.icon
        }
    elseif args.image ~= nil then
        icon = wibox.widget {
            widget = wibox.widget.imagebox,
            image = args.image
        }
    end

    local text_widget = wibox.widget {
        widget = twidget,
        size = 12,
        text = args.text
    }

    local widget = wibox.widget {
        widget = wibox.container.margin,
        forced_height = dpi(45),
        margins = dpi(5),
        {
            widget = ebwidget.normal,
            id = "button",
            on_release = function(self)
                self.menu:hide(true)
                args.on_release(self, text_widget)
            end,
            on_hover = function(self)
                self.menu:hide_children_menus()
            end,
            {
                layout = wibox.layout.fixed.horizontal,
                forced_width = dpi(270),
                spacing = dpi(15),
                icon,
                text_widget
            }
        }
    }

    function widget:set_icon(new_icon)
        icon:set_icon(new_icon)
    end

    return widget
end

function menu.checkbox_button(args)
    args = args or {}

    args.icon = args.icon or nil
    args.image = args.image
    args.text = args.text or ""
    args.handle_active_color = args.handle_active_color or nil
    args.on_by_default = args.on_by_default or nil
    args.on_release = args.on_release or nil

    local icon = nil
    if args.icon ~= nil then
        icon = wibox.widget {
            widget = twidget,
            scale = 0.5,
            icon = args.icon
        }
    elseif args.image ~= nil then
        icon = wibox.widget {
            widget = wibox.widget.imagebox,
            image = args.image
        }
    end

    local text = wibox.widget {
        widget = twidget,
        size = 12,
        text = args.text
    }

    local checkbox = cbwidget {}
    checkbox:set_handle_active_color(args.handle_active_color)
    checkbox:set_state(args.state)
    checkbox:set_handle_offset(dpi(5))

    local widget = nil
    widget = wibox.widget {
        widget = wibox.container.margin,
        forced_height = dpi(45),
        margins = dpi(5),
        {
            widget = wibox.container.place,
            halign = "left",
            {
                widget = ebwidget.normal,
                id = "button",
                on_release = function()
                    args.on_release(widget)
                end,
                on_hover = function(self)
                    self.menu:hide_children_menus()
                end,
                {
                    layout = wibox.layout.align.horizontal,
                    forced_width = dpi(270),
                    {
                        layout = wibox.layout.fixed.horizontal,
                        spacing = dpi(15),
                        icon,
                        text,
                    },
                    nil,
                    checkbox
                }
            }
        }
    }

    function widget:turn_on()
        checkbox:turn_on()
    end

    function widget:turn_off()
        checkbox:turn_off()
    end

    function widget:set_handle_active_color(handle_active_color)
        checkbox:set_handle_active_color(handle_active_color)
    end

    return widget
end

function menu.separator()
    return wibox.widget {
        widget = bwidget,
        forced_height = dpi(1),
        shape = helpers.ui.rrect(),
        bg = beautiful.colors.surface
    }
end

function menu.mt:__call(...)
    return menu.menu(...)
end

return setmetatable(menu, menu.mt)
