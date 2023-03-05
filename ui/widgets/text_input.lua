-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local lgi = require('lgi')
local Gtk = lgi.require('Gtk', '3.0')
local Gdk = lgi.require('Gdk', '3.0')
local Pango = lgi.Pango
local awful = require("awful")
local gtable = require("gears.table")
local wibox = require("wibox")
local beautiful = require("beautiful")
local tonumber = tonumber
local ipairs = ipairs
local string = string
local capi = {
    awesome = awesome,
    root = root,
    tag = tag,
    client = client,
    mouse = mouse,
    mousegrabber = mousegrabber
}

local text_input = {
    mt = {}
}

local properties = {
    "only_numbers", "round", "obscure", "reset_on_stop",
    "stop_keys", "stop_on_clicked_inside", "stop_on_clicked_outside", "stop_on_focus_lost", "stop_on_tag_changed",
    "placeholder", "text",
    "cursor_size", "cursor_color"
}

local function build_properties(prototype, prop_names)
    for _, prop in ipairs(prop_names) do
        if not prototype["set_" .. prop] then
            prototype["set_" .. prop] = function(self, value)
                if self._private[prop] ~= value then
                    self._private[prop] = value
                    self:emit_signal("widget::redraw_needed")
                    self:emit_signal("property::" .. prop, value)
                end
                return self
            end
        end
        if not prototype["get_" .. prop] then
            prototype["get_" .. prop] = function(self)
                return self._private[prop]
            end
        end
    end
end

local function has_value(tab, val)
    for _, value in ipairs(tab) do
        if val:lower():find(value:lower(), 1, true) then
            return true
        end
    end
    return false
end

local function is_word_char(c)
    if string.find(c, "[{[(,.:;_-+=@/ ]") then
        return false
    else
        return true
    end
end

local function cword_start(s, pos)
    local i = pos
    if i > 1 then
        i = i - 1
    end
    while i >= 1 and not is_word_char(s:sub(i, i)) do
        i = i - 1
    end
    while i >= 1 and is_word_char(s:sub(i, i)) do
        i = i - 1
    end
    if i <= #s then
        i = i + 1
    end
    return i
end

local function cword_end(s, pos)
    local i = pos
    while i <= #s and not is_word_char(s:sub(i, i)) do
        i = i + 1
    end
    while i <= #s and is_word_char(s:sub(i, i)) do
        i = i + 1
    end
    return i
end

local function run_mousegrabber(self)
    local cursor = "left_ptr"
    if capi.mouse.current_wibox then
        cursor = capi.mouse.current_wibox.cursor
    end

    capi.mousegrabber.run(function(m)
        if m.buttons[1] then
            if capi.mouse.current_widget ~= self and self.stop_on_clicked_outside then
                self:unfocus()
                return false
            elseif capi.mouse.current_widget == self and self.stop_on_clicked_inside then
                self:unfocus()
                return false
            end
        end
        return true
    end, cursor)
end

local function run_keygrabber(self)
    local wp = self._private
    wp.keygrabber = awful.keygrabber.run(function(modifiers, key, event)
        if event ~= "press" then
            self:emit_signal("key::release", modifiers, key, event)
            return
        end
        self:emit_signal("key::press", modifiers, key, event)

        -- Convert index array to hash table
        local mod = {}
        for _, v in ipairs(modifiers) do
            mod[v] = true
        end

        if mod.Control then
            if key == "v" then
                self:paste()
            elseif key == "b" or key == "Left" then
                self:set_cursor_index_to_word_start()
            elseif key == "f" or key == "Right" then
                self:set_cursor_index_to_word_end()
            elseif key == "d" then
                self:delete_next_word()
            elseif key == "BackSpace" then
                self:delete_previous_word()
            end
        else
            if has_value(wp.stop_keys, key) then
                self:unfocus()
            end

            if mod.Shift and key == "Insert" then
                self:paste()
            elseif key == "Home" then
                self:set_cursor_index(0)
            elseif key == "End" then
                self:set_cursor_index_to_end()
            elseif key == "BackSpace" then
                self:delete_text_before_cursor()
            elseif key == "Delete" then
                self:delete_text_after_cursor()
            elseif key == "Left" then
                self:decremeant_cursor_index()
            elseif key == "Right" then
                self:increamant_cursor_index()
            else
                if (wp.round and key == ".") or (wp.only_numbers and tonumber(wp.text .. key) == nil) then
                    return
                end

                -- wlen() is UTF-8 aware but #key is not,
                -- so check that we have one UTF-8 char but advance the cursor of # position
                if key:wlen() == 1 then
                    self:insert_text(key)
                end
            end
        end
    end)
end

function text_input:set_widget_template(widget_template)
    local wp = self._private
    self._private.text_widget = widget_template:get_children_by_id("text_role")[1]

    local widget = wibox.widget {
        layout = wibox.layout.stack,
        {
            widget = wibox.widget.base.make_widget,
            id = "cursor",
            x = 0,
            y = 0,
            draw = function(self, __, cr, width, height)
                local ink_rect, logical_rect = wp.text_widget._private.layout:get_pixel_extents()
                cr:set_line_width(2)
                cr:move_to(self.x, self.y + logical_rect.y)
                cr:line_to(self.x, self.y + logical_rect.y + logical_rect.height)
                cr:stroke()
            end
        },
        {
            widget = wibox.widget.base.make_widget,
            id = "selected_text_bg",
            start_x = 0,
            end_x = 0,
            draw = function(self, __, cr, width, height)
                local ink_rect, logical_rect = wp.text_widget._private.layout:get_pixel_extents()
                cr:set_source_rgba(0.5, 0.5, 1, 0.5)
                cr:rectangle(self.start_x, logical_rect.y, self.end_x - self.start_x, logical_rect.height)
                cr:fill()
            end
        },
        widget_template
    }

    widget:connect_signal("mouse::enter", function(self, find_widgets_result)
        capi.root.cursor("xterm")
        local wibox = capi.mouse.current_wibox
        if wibox then
            wibox.cursor = "xterm"
        end
    end)

    widget:connect_signal("mouse::leave", function()
        capi.root.cursor("left_ptr")
        local wibox = capi.mouse.current_wibox
        if wibox then
            wibox.cursor = "left_ptr"
        end

        if wp.stop_on_focus_lost ~= false and wp.state == true then
            self:unfocus()
        end
    end)

    widget:connect_signal("button::press", function(_, lx, ly, button, mods, find_widgets_result)
        if button == 1 then
            self:focus()
            self:set_cursor_index_from_x_y(lx, ly)
        end
    end)

    self:set_widget(widget)
end

function text_input:set_state(state)
    if state == true then
       self:focus()
    else
        self:unfocus()
    end
end

function text_input:toggle_obscure()
    self:set_obscure(not self._private.obscure)
end

function text_input:replace_text(text)
    --TODO handle text selection and insertion
    local wp = self._private
    local text_widget = self:get_text_widget()

    text_widget:set_text(text)
    if text_widget:get_text() == "" then
        text_widget:set_text(wp.placeholder)
        self:set_cursor_index(0)
    else
        self:set_cursor_index(#text)
    end

    self:emit_signal("property::text", text_widget:get_text())
end

function text_input:insert_text(text)
    local old_text = self:get_text()
    local cursor_index = self:get_cursor_index()
    local left_text = old_text:sub(1, cursor_index) .. text
    local right_text = old_text:sub(cursor_index + 1)
    self:get_text_widget():set_text(left_text .. right_text)
    self:set_cursor_index(self:get_cursor_index() + #text)

    self:emit_signal("property::text", new_text)
end

function text_input:paste(self)
    local wp = self._private

    wp.clipboard:request_text(function(clipboard, text)
        if text then
            self:insert_text(text)
        end
    end)
end

function text_input:delete_next_word()
    local old_text = self:get_text()
    local cursor_index = self:get_cursor_index()

    local left_text = old_text:sub(1, cursor_index)
    local right_text = old_text:sub(cword_end(old_text, cursor_index + 1))
    self:get_text_widget():set_text(left_text .. right_text)
end

function text_input:delete_previous_word()
    local old_text = self:get_text()
    local cursor_index = self:get_cursor_index()
    local wstart = cword_start(old_text, cursor_index + 1) - 1
    local left_text = old_text:sub(1, wstart)
    local right_text = old_text:sub(cursor_index + 1)
    self:get_text_widget():set_text(left_text .. right_text)
    self:set_cursor_index(wstart)
end

function text_input:delete_text_before_cursor()
    local cursor_index = self:get_cursor_index()
    if cursor_index > 0 then
        local old_text = self:get_text()
        local left_text = old_text:sub(1, cursor_index - 1)
        local right_text = old_text:sub(cursor_index + 1)
        self:get_text_widget():set_text(left_text .. right_text)
        self:set_cursor_index(cursor_index - 1)
    end
end

function text_input:delete_text_after_cursor()
    local cursor_index = self:get_cursor_index()
    if cursor_index < #self:get_text() then
        local old_text = self:get_text()
        local left_text = old_text:sub(1, cursor_index)
        local right_text = old_text:sub(cursor_index + 2)
        self:get_text_widget():set_text(left_text .. right_text)
    end
end

function text_input:get_text()
    return self:get_text_widget():get_text()
end

function text_input:get_text_widget()
    return self._private.text_widget
end

function text_input:set_cursor_index(index)
    if index > #self:get_text() or index < 0 then
        return
    end

    local layout = self:get_text_widget()._private.layout
    local strong_pos, weak_pos = layout:get_cursor_pos(index)
    if strong_pos ~= nil then
        local cursor = self:get_widget():get_children_by_id("cursor")[1]
        cursor.x = strong_pos.x / Pango.SCALE
        cursor.y = strong_pos.y / Pango.SCALE
        self._private.cursor_index = index
        cursor:emit_signal("widget::redraw_needed")
    end
end

function text_input:set_cursor_index_from_x_y(x, y)
    local layout = self:get_text_widget()._private.layout
    local index, trailing = layout:xy_to_index(x * Pango.SCALE, y)
    if index ~= nil then
        index = index + 1
        self:set_cursor_index(index)
    end
end

function text_input:set_cursor_index_to_word_start()
    self:set_cursor_index(cword_start(self:get_text(), self:get_cursor_index() + 1) - 1)
end

function text_input:set_cursor_index_to_word_end()
    self:set_cursor_index(cword_end(self:get_text(), self:get_cursor_index() + 1) - 1)
end

function text_input:set_cursor_index_to_end()
    self:set_cursor_index(#self:get_text())
end

function text_input:increamant_cursor_index()
    self:set_cursor_index(self:get_cursor_index() + 1)
end

function text_input:decremeant_cursor_index()
    self:set_cursor_index(self:get_cursor_index() - 1)
end

function text_input:get_cursor_index()
    return self._private.cursor_index
end

function text_input:focus()
    local wp = self._private
    if wp.state == true then
        return
    end

    --TODO show cursor
    run_keygrabber(self)
    if wp.stop_on_clicked_outside then
        run_mousegrabber(self)
    end

    print("focus")
    wp.state = true
    self:emit_signal("focus")
    capi.awesome.emit_signal("text_input::focus", self)
end

function text_input:unfocus()
    local wp = self._private
    if wp.state == false then
        return
    end

    if self.reset_on_stop == true then
        self:set_text("")
    end
    awful.keygrabber.stop(wp.keygrabber)
    if wp.stop_on_clicked_outside then
        capi.mousegrabber.stop()
    end

    print("unfocus")
    wp.state = false
    self:emit_signal("unfocus")
    capi.awesome.emit_signal("text_input::unfocus", self)
end

function text_input:toggle()
    local wp = self._private

    if wp.state == false then
        self:focus()
    else
        self:unfocus()
    end
end

local function new()
    local widget = wibox.container.background()
    gtable.crush(widget, text_input, true)

    local wp = widget._private
    wp.placeholder = ""
    wp.text = ""
    wp.state = false
    wp.cur_pos = #wp.text + 1 or 1
    wp.clipboard = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD)
    wp.cursor_index = 0

    wp.stop_keys = { "Escape", "Return" }
    wp.stop_on_clicked_inside = false
    wp.stop_on_clicked_outside = false
    wp.stop_on_focus_lost = true
    wp.stop_on_tag_changed = true
    wp.stop_on_other_text_input_focused = true
    wp.stop_on_subject_lost_focus = nil

    wp.only_numbers = false
    wp.round = false
    wp.reset_on_stop = false
    wp.obscure = false

    wp.selected_text_bg = beautiful.colors.on_background
    wp.cursor_size = 4
    wp.cursor_color = beautiful.colors.on_background

    widget:set_widget_template(wibox.widget {
        widget = wibox.widget.textbox,
        id = "text_role"
    })

    capi.tag.connect_signal("property::selected", function()
        if wp.stop_on_tag_changed then
            self:unfocus()
        end
    end)

    capi.awesome.connect_signal("text_input::focus", function(text_input)
        if wp.stop_on_other_text_input_focused == false and text_input ~= self then
            self:unfocus()
        end
    end)

    return widget
end

function text_input.mt:__call(...)
    return new(...)
end

build_properties(text_input, properties)

return setmetatable(text_input, text_input.mt)
