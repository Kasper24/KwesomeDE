-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gtable = require("gears.table")
local gcolor = require("gears.color")
local gstring = require("gears.string")
local gtimer = require("gears.timer")
local wibox = require("wibox")
local ebwidget = require("ui.widgets.button.elevated")
local beautiful = require("beautiful")
local tostring = tostring
local ipairs = ipairs
local string = string
local capi = {
    awesome = awesome,
    tag = tag,
    client = client
}

local prompt = {
    mt = {}
}

local properties = {"icon_font", "icon", "font", "prompt", "text", "icon_color", "prompt_color", "text_color",
                    "cursor_color", "always_on", "reset_on_stop", "obscure", "keypressed_callback", "changed_callback",
                    "done_callback"}

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

local function have_multibyte_char_at(text, position)
    return text:sub(position, position):wlen() == -1
end

local function update_markup(self, show_cursor)
    local wp = self._private

    local icon_color = gcolor.ensure_pango_color(wp.icon_color)
    local prompt_color = gcolor.ensure_pango_color(wp.prompt_color)
    local text_color = gcolor.ensure_pango_color(wp.text_color)
    local cursor_color = gcolor.ensure_pango_color(wp.cursor_color)

    local text = tostring(wp.text) or ""
    if wp.obscure == true then
        text = text:gsub(".", "*")
    end

    if show_cursor == true then
        local char, spacer, text_start, text_end

        if #text < wp.cur_pos then
            char = " "
            spacer = ""
            text_start = gstring.xml_escape(text)
            text_end = ""
        else
            local offset = 0
            if have_multibyte_char_at(text, wp.cur_pos) then
                offset = 1
            end
            char = gstring.xml_escape(text:sub(wp.cur_pos, wp.cur_pos + offset))
            spacer = " "
            text_start = gstring.xml_escape(text:sub(1, wp.cur_pos - 1))
            text_end = gstring.xml_escape(text:sub(wp.cur_pos + 1 + offset))
        end

        if wp.icon ~= nil then
            self._private.child:set_markup(string.format('<span font_desc="%s" foreground="%s">%s  </span>' ..
                                                             '<span foreground="%s">%s</span>' ..
                                                             '<span foreground="%s">%s</span>' ..
                                                             '<span background="%s">%s</span>' ..
                                                             '<span foreground="%s">%s%s</span>', wp.icon_font,
                icon_color, wp.icon, prompt_color, wp.prompt, text_color, text_start, cursor_color, char, text_color,
                text_end, spacer))
        else
            self._private.child:set_markup(string.format('<span foreground="%s">%s</span>' ..
                                                             '<span foreground="%s">%s</span>' ..
                                                             '<span background="%s">%s</span>' ..
                                                             '<span foreground="%s">%s%s</span>', prompt_color,
                wp.prompt, text_color, text_start, cursor_color, char, text_color, text_end, spacer))
        end
    else
        if wp.icon ~= nil then
            self._private.child:set_markup(string.format('<span font_desc="%s" foreground="%s">%s  </span>' ..
                                                             '<span foreground="%s">%s</span>' ..
                                                             '<span foreground="%s">%s</span>', wp.icon_font,
                icon_color, wp.icon, prompt_color, wp.prompt, text_color, gstring.xml_escape(text)))
        else
            self._private.child:set_markup(string.format('<span foreground="%s">%s</span>' ..
                                                             '<span foreground="%s">%s</span>', prompt_color, wp.prompt,
                text_color, gstring.xml_escape(text)))
        end
    end
end

local function paste(self)
    local wp = self._private

    awful.spawn.easy_async_with_shell("xclip -selection clipboard -o", function(stdout)
        if stdout ~= nil then
            local n = stdout:find("\n")
            if n then
                stdout = stdout:sub(1, n - 1)
            end

            wp.text = wp.text:sub(1, wp.cur_pos - 1) .. stdout .. self.text:sub(wp.cur_pos)
            wp.cur_pos = wp.cur_pos + #stdout
            update_markup(self, true)
        end
    end)
end

local function build_properties(prototype, prop_names)
    for _, prop in ipairs(prop_names) do
        if not prototype["set_" .. prop] then
            prototype["set_" .. prop] = function(self, value)
                if self._private[prop] ~= value then
                    self._private[prop] = value
                    self:emit_signal("widget::redraw_needed")
                    self:emit_signal("property::" .. prop, value)
                    update_markup(self, false)
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

function prompt:toggle_obscure()
    self:set_obscure(not self._private.obscure)
end

function prompt:set_obscure(value)
    self._private.obscure = value
    update_markup(self, false)
end

function prompt:get_text()
    return self._private.text
end

function prompt:set_text(text)
    self._private.text = text
    self._private.cur_pos = #text + 1
    update_markup(self, false)
end

function prompt:set_prompt(prompt)
    self._private.prompt = prompt
    update_markup(self, false)
end

function prompt:set_only_numbers(only_numbers)
    self._private.only_numbers = only_numbers
end

function prompt:start()
    local wp = self._private

    wp.is_running = true
    capi.awesome.emit_signal("prompt::toggled_on", self)
    self:turn_on()
    update_markup(self, true)

    wp.grabber = awful.keygrabber.run(function(modifiers, key, event)
        -- Convert index array to hash table
        local mod = {}
        for _, v in ipairs(modifiers) do
            mod[v] = true
        end

        if event ~= "press" then
            if wp.keyreleased_callback then
                wp.keyreleased_callback(mod, key, wp.text)
            end
            return
        end

        -- Call the user specified callback. If it returns true as
        -- the first result then return from the function. Treat the
        -- second and third results as a new command and new prompt
        -- to be set (if provided)
        if wp.keypressed_callback then
            local user_catched, new_command, new_prompt = wp.keypressed_callback(mod, key, wp.text)
            if new_command or new_prompt then
                if new_command then
                    wp.text = new_command
                end
                if new_prompt then
                    wp.prompt = new_prompt
                end
            end
            if user_catched then
                self:emit_signal("text::changed", wp.text)
                if wp.changed_callback then
                    wp.changed_callback(wp.text)
                end
                return
            end
        end

        -- Control cases
        if mod.Control then
            if key == "v" then
                paste(self)
            elseif key == "a" then
                wp.cur_pos = 1
            elseif key == "b" then
                if wp.cur_pos > 1 then
                    wp.cur_pos = wp.cur_pos - 1
                    if have_multibyte_char_at(wp.text, wp.cur_pos) then
                        wp.cur_pos = wp.cur_pos - 1
                    end
                end
            elseif key == "d" then
                if wp.cur_pos <= #wp.text then
                    wp.text = wp.text:sub(1, wp.cur_pos - 1) .. wp.text:sub(wp.cur_pos + 1)
                end
            elseif key == "e" then
                wp.cur_pos = #wp.text + 1
            elseif key == "f" then
                if wp.cur_pos <= #wp.text then
                    if have_multibyte_char_at(wp.text, wp.cur_pos) then
                        wp.cur_pos = wp.cur_pos + 2
                    else
                        wp.cur_pos = wp.cur_pos + 1
                    end
                end
            elseif key == "h" then
                if wp.cur_pos > 1 then
                    local offset = 0
                    if have_multibyte_char_at(wp.text, wp.cur_pos - 1) then
                        offset = 1
                    end
                    wp.text = wp.text:sub(1, wp.cur_pos - 2 - offset) .. wp.text:sub(wp.cur_pos)
                    wp.cur_pos = wp.cur_pos - 1 - offset
                end
            elseif key == "k" then
                wp.text = wp.text:sub(1, wp.cur_pos - 1)
            elseif key == "u" then
                wp.text = wp.text:sub(wp.cur_pos, #wp.text)
                wp.cur_pos = 1
            elseif key == "w" or key == "BackSpace" then
                local wstart = 1
                local wend = 1
                local cword_start_pos = 1
                local cword_end_pos = 1
                while wend < wp.cur_pos do
                    wend = wp.text:find("[{[(,.:;_-+=@/ ]", wstart)
                    if not wend then
                        wend = #wp.text + 1
                    end
                    if wp.cur_pos >= wstart and wp.cur_pos <= wend + 1 then
                        cword_start_pos = wstart
                        cword_end_pos = wp.cur_pos - 1
                        break
                    end
                    wstart = wend + 1
                end
                wp.text = wp.text:sub(1, cword_start_pos - 1) .. wp.text:sub(cword_end_pos + 1)
                wp.cur_pos = cword_start_pos
            end
        elseif mod.Mod1 or mod.Mod3 then
            if key == "b" then
                wp.cur_pos = cword_start(wp.text, wp.cur_pos)
            elseif key == "f" then
                wp.cur_pos = cword_end(wp.text, wp.cur_pos)
            elseif key == "d" then
                wp.text = wp.text:sub(1, wp.cur_pos - 1) .. wp.text:sub(cword_end(wp.text, wp.cur_pos))
            elseif key == "BackSpace" then
                local wstart = cword_start(wp.text, wp.cur_pos)
                wp.text = wp.text:sub(1, wstart - 1) .. wp.text:sub(wp.cur_pos)
                wp.cur_pos = wstart
            end
        else
            if key == "Escape" or key == "Return" then
                if self.always_on == false then
                    self:stop()
                    return
                end
                -- Typin cases
            elseif mod.Shift and key == "Insert" then
                paste(self)
            elseif key == "Home" then
                wp.cur_pos = 1
            elseif key == "End" then
                wp.cur_pos = #wp.text + 1
            elseif key == "BackSpace" then
                if wp.cur_pos > 1 then
                    local offset = 0
                    if have_multibyte_char_at(wp.text, wp.cur_pos - 1) then
                        offset = 1
                    end
                    wp.text = wp.text:sub(1, wp.cur_pos - 2 - offset) .. wp.text:sub(wp.cur_pos)
                    wp.cur_pos = wp.cur_pos - 1 - offset
                end
            elseif key == "Delete" then
                wp.text = wp.text:sub(1, wp.cur_pos - 1) .. wp.text:sub(wp.cur_pos + 1)
            elseif key == "Left" then
                wp.cur_pos = wp.cur_pos - 1
            elseif key == "Right" then
                wp.cur_pos = wp.cur_pos + 1
            else
                if wp.only_numbers and tonumber(key) == nil then
                    return
                end

                -- wlen() is UTF-8 aware but #key is not,
                -- so check that we have one UTF-8 char but advance the cursor of # position
                if key:wlen() == 1 then
                    wp.text = wp.text:sub(1, wp.cur_pos - 1) .. key .. wp.text:sub(wp.cur_pos)
                    wp.cur_pos = wp.cur_pos + #key
                end
            end
            if wp.cur_pos < 1 then
                wp.cur_pos = 1
            elseif wp.cur_pos > #wp.text + 1 then
                wp.cur_pos = #wp.text + 1
            end
        end

        if wp.only_numbers and wp.text == "" then
            wp.text = "0"
            wp.cur_pos = #wp.text + 1
        end

        update_markup(self, true)
        self:emit_signal("text::changed", wp.text)

        if wp.changed_callback then
            wp.changed_callback(wp.text)
        end
    end)
end

function prompt:stop()
    local wp = self._private

    wp.is_running = false

    if self.reset_on_stop == true or wp.cur_pos == nil then
        wp.cur_pos = wp.text:wlen() + 1
    end
    if self.reset_on_stop == true then
        wp.text = ""
        wp.text = ""
    end

    self:turn_off()
    awful.keygrabber.stop(wp.grabber)
    update_markup(self, false)

    if self.done_callback then
        self.done_callback()
    end
end

function prompt:toggle()
    if self._private.is_running == true then
        self:stop()
    else
        self:start()
    end
end

local function new()
    local widget = ebwidget.state()
    gtable.crush(widget, prompt, true)

    widget:set_child(wibox.widget.textbox())
    widget:set_hover_cursor("xterm")
    widget:set_halign("left")

    local wp = widget._private

    wp.icon_font = beautiful.font
    wp.icon = nil
    wp.font = beautiful.font
    wp.prompt = ""
    wp.text = ""

    wp.icon_color = beautiful.colors.on_background
    wp.prompt_color = beautiful.colors.on_background
    wp.text_color = beautiful.colors.on_background
    wp.cursor_color = beautiful.colors.on_background

    wp.always_on = false
    wp.reset_on_stop = false
    wp.obscure = false
    wp.keypressed_callback = nil
    wp.changed_callback = nil
    wp.done_callback = nil
    wp.only_numbers = false

    wp.cur_pos = #wp.text + 1 or 1

    if widget._private.always_on == false then
        widget:set_on_press(function()
            widget:toggle()
        end)
    end

    update_markup(widget, false)

    widget:connect_signal("mouse::leave", function()
        if wp.always_on == false then
            widget:stop()
        end
    end)

    capi.awesome.connect_signal("root::pressed", function()
        if wp.always_on == false then
            widget:stop()
        end
    end)

    capi.client.connect_signal("button::press", function()
        if wp.always_on == false then
            widget:stop()
        end
    end)

    capi.tag.connect_signal("property::selected", function()
        if wp.always_on == false then
            widget:stop()
        end
    end)

    capi.awesome.connect_signal("prompt::toggled_on", function(prompt)
        if wp.always_on == false and prompt ~= widget then
            widget:stop()
        end
    end)

    capi.awesome.connect_signal("colorscheme::changed", function(old_colorscheme_to_new_map)
        wp.icon_color = old_colorscheme_to_new_map[wp.icon_color]
        wp.prompt_color = old_colorscheme_to_new_map[wp.prompt_color]
        wp.text_color = old_colorscheme_to_new_map[wp.text_color]
        wp.cursor_color = old_colorscheme_to_new_map[wp.cursor_color]
        update_markup(widget, false)
    end)

    return widget
end

function prompt.mt:__call(...)
    return new(...)
end

build_properties(prompt, properties)

return setmetatable(prompt, prompt.mt)
