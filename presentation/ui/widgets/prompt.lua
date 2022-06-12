-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gcolor = require("gears.color")
local gstring = require("gears.string")
local gtimer = require("gears.timer")
local wibox = require("wibox")
local ebutton = require("presentation.ui.widgets.button.elevated")
local beautiful = require("beautiful")
local tostring = tostring
local ipairs = ipairs
local string = string
local capi = { awesome = awesome, tag = tag }

local prompt  = { mt = {} }

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
    while i <= #s and  is_word_char(s:sub(i, i)) do
        i = i + 1
    end
    return i
end

local function have_multibyte_char_at(text, position)
    return text:sub(position, position):wlen() == -1
end

local function update_markup(self, show_cursor)
    local icon_color = gcolor.ensure_pango_color(self.icon_color)
    local prompt_color = gcolor.ensure_pango_color(self.prompt_color)
    local text_color = gcolor.ensure_pango_color(self.text_color)
    local cursor_color = gcolor.ensure_pango_color(self.cursor_color)

    local text = tostring(self.text) or ""
    if self.obscure == true then
        text = text:gsub(".", "*")
    end

    if show_cursor == true then
        local char, spacer, text_start, text_end

        if #text < self._private.cur_pos then
            char = " "
            spacer = ""
            text_start = gstring.xml_escape(text)
            text_end = ""
        else
            local offset = 0
            if have_multibyte_char_at(text, self._private.cur_pos) then
                offset = 1
            end
            char = gstring.xml_escape(text:sub(self._private.cur_pos, self._private.cur_pos + offset))
            spacer = " "
            text_start = gstring.xml_escape(text:sub(1, self._private.cur_pos - 1))
            text_end = gstring.xml_escape(text:sub(self._private.cur_pos + 1 + offset))
        end

        if self.icon ~= nil then
            self.textbox:set_markup(string.format(
                '<span font_desc="%s" foreground="%s">%s  </span>' ..
                '<span foreground="%s">%s</span>' ..
                '<span foreground="%s">%s</span>' ..
                '<span background="%s">%s</span>' ..
                '<span foreground="%s">%s%s</span>',
                self.icon_font,
                icon_color,
                self.icon,
                prompt_color,
                self.prompt,
                text_color,
                text_start,
                cursor_color,
                char,
                text_color,
                text_end,
                spacer
            ))
        else
            self.textbox:set_markup(string.format(
                '<span foreground="%s">%s</span>' ..
                '<span foreground="%s">%s</span>' ..
                '<span background="%s">%s</span>' ..
                '<span foreground="%s">%s%s</span>',
                prompt_color,
                self.prompt,
                text_color,
                text_start,
                cursor_color,
                char,
                text_color,
                text_end,
                spacer
            ))
        end
    else
        if self.icon  ~= nil then
            self.textbox:set_markup(string.format(
                '<span font_desc="%s" foreground="%s">%s  </span>' ..
                '<span foreground="%s">%s</span>' ..
                '<span foreground="%s">%s</span>',
                self.icon_font,
                icon_color,
                self.icon,
                prompt_color,
                self.prompt,
                text_color,
                gstring.xml_escape(text)
            ))
        else
            self.textbox:set_markup(string.format(
                '<span foreground="%s">%s</span>' ..
                '<span foreground="%s">%s</span>',
                prompt_color,
                self.prompt,
                text_color,
                gstring.xml_escape(text)
            ))
        end
    end
end

local function paste(self)
    awful.spawn.easy_async_with_shell("xclip -selection clipboard -o", function(stdout)
        if stdout ~= nil then
            local n = stdout:find("\n")
            if n then
                stdout = stdout:sub(1, n - 1)
            end

            self.text = self.text:sub(1, self._private.cur_pos - 1) .. stdout .. self.text:sub(self._private.cur_pos)
            self._private.cur_pos = self._private.cur_pos + #stdout
            update_markup(self, true)
        end
    end)
end

function prompt:toggle_obscure()
    self:set_obscure(not self.obscure)
end

function prompt:set_obscure(value)
    self.obscure = value
    update_markup(self, true)
end

function prompt:get_text()
    return self.text
end

function prompt:start()
    self._private.is_running = true
    self.can_stop = false
    capi.awesome.emit_signal("prompt::toggled_on", self)
    self.widget:turn_on()
    update_markup(self, true)

    gtimer { timeout = 0.1, autostart = true, call_now = false, single_shot = true, callback = function()
        self.can_stop = true
    end }

    self._private.grabber = awful.keygrabber.run(function(modifiers, key, event)
        -- Convert index array to hash table
        local mod = {}
        for _, v in ipairs(modifiers) do mod[v] = true end

        if event ~= "press" then
            if self.keyreleased_callback then
                self.keyreleased_callback(mod, key, self.text)
            end
            return
        end

        -- Call the user specified callback. If it returns true as
        -- the first result then return from the function. Treat the
        -- second and third results as a new command and new prompt
        -- to be set (if provided)
        if self.keypressed_callback then
            local user_catched, new_command, new_prompt =
            self.keypressed_callback(mod, key, self.text)
            if new_command or new_prompt then
                if new_command then
                    self.text = new_command
                end
                if new_prompt then
                    self.prompt = new_prompt
                end
            end
            if user_catched then
                if self.changed_callback then
                    self.changed_callback(self.text)
                end
                return
            end
        end

        -- Control cases
        if mod.Control then
            if key == "v" then
                paste(self)
            elseif key == "a" then
                self._private.cur_pos = 1
            elseif key == "b" then
                if self._private.cur_pos > 1 then
                    self._private.cur_pos = self._private.cur_pos - 1
                    if have_multibyte_char_at(self.text, self._private.cur_pos) then
                        self._private.cur_pos = self._private.cur_pos - 1
                    end
                end
            elseif key == "d" then
                if self._private.cur_pos <= #self.text then
                    self.text = self.text:sub(1, self._private.cur_pos - 1) .. self.text:sub(self._private.cur_pos + 1)
                end
            elseif key == "e" then
                self._private.cur_pos = #self.text + 1
            elseif key == "f" then
                if self._private.cur_pos <= #self.text then
                    if have_multibyte_char_at(self.text, self._private.cur_pos) then
                        self._private.cur_pos = self._private.cur_pos + 2
                    else
                        self._private.cur_pos = self._private.cur_pos + 1
                    end
                end
            elseif key == "h" then
                if self._private.cur_pos > 1 then
                    local offset = 0
                    if have_multibyte_char_at(self.text, self._private.cur_pos - 1) then
                        offset = 1
                    end
                    self.text = self.text:sub(1, self._private.cur_pos - 2 - offset) .. self.text:sub(self._private.cur_pos)
                    self._private.cur_pos = self._private.cur_pos - 1 - offset
                end
            elseif key == "k" then
                self.text = self.text:sub(1, self._private.cur_pos - 1)
            elseif key == "u" then
                self.text = self.text:sub(self._private.cur_pos, #self.text)
                self._private.cur_pos = 1
            elseif key == "w" or key == "BackSpace" then
                local wstart = 1
                local wend = 1
                local cword_start_pos = 1
                local cword_end_pos = 1
                while wend < self._private.cur_pos do
                    wend = self.text:find("[{[(,.:;_-+=@/ ]", wstart)
                    if not wend then wend = #self.text + 1 end
                    if self._private.cur_pos >= wstart and self._private.cur_pos <= wend + 1 then
                        cword_start_pos = wstart
                        cword_end_pos = self._private.cur_pos - 1
                        break
                    end
                    wstart = wend + 1
                end
                self.text = self.text:sub(1, cword_start_pos - 1) .. self.text:sub(cword_end_pos + 1)
                self._private.cur_pos = cword_start_pos
            end
        elseif mod.Mod1 or mod.Mod3 then
            if key == "b" then
                self._private.cur_pos = cword_start(self.text, self._private.cur_pos)
            elseif key == "f" then
                self._private.cur_pos = cword_end(self.text, self._private.cur_pos)
            elseif key == "d" then
                self.text = self.text:sub(1, self._private.cur_pos - 1) .. self.text:sub(cword_end(self.text, self._private.cur_pos))
            elseif key == "BackSpace" then
                local wstart = cword_start(self.text, self._private.cur_pos)
                self.text = self.text:sub(1, wstart - 1) .. self.text:sub(self._private.cur_pos)
                self._private.cur_pos = wstart
            end
        else
            if key == "Escape" then
                if self.always_on == false then
                    self:stop()
                    return
                end
            -- Typin cases
            elseif mod.Shift and key == "Insert" then
                paste(self)
            elseif key == "Home" then
                self._private.cur_pos = 1
            elseif key == "End" then
                self._private.cur_pos = #self.text + 1
            elseif key == "BackSpace" then
                if self._private.cur_pos > 1 then
                    local offset = 0
                    if have_multibyte_char_at(self.text, self._private.cur_pos - 1) then
                        offset = 1
                    end
                    self.text = self.text:sub(1, self._private.cur_pos - 2 - offset) .. self.text:sub(self._private.cur_pos)
                    self._private.cur_pos = self._private.cur_pos - 1 - offset
                end
            elseif key == "Delete" then
                self.text = self.text:sub(1, self._private.cur_pos - 1) .. self.text:sub(self._private.cur_pos + 1)
            elseif key == "Left" then
                self._private.cur_pos = self._private.cur_pos - 1
            elseif key == "Right" then
                self._private.cur_pos = self._private.cur_pos + 1
            else
                -- wlen() is UTF-8 aware but #key is not,
                -- so check that we have one UTF-8 char but advance the cursor of # position
                if key:wlen() == 1 then
                    self.text = self.text:sub(1, self._private.cur_pos - 1) .. key .. self.text:sub(self._private.cur_pos)
                    self._private.cur_pos = self._private.cur_pos + #key
                end
            end
            if self._private.cur_pos < 1 then
                self._private.cur_pos = 1
            elseif self._private.cur_pos > #self.text + 1 then
                self._private.cur_pos = #self.text + 1
            end
        end

        update_markup(self, true)

        if self.changed_callback then
            self.changed_callback(self.text)
        end
    end)
end

function prompt:stop()
    self._private.is_running = false

    if self.reset_on_stop == true or self._private.cur_pos == nil then
        self._private.cur_pos = self.text:wlen() + 1
    end
    if self.reset_on_stop == true then
        self.text = "" self.text = ""
    end

    self.widget:turn_off()
    awful.keygrabber.stop(self._private.grabber)
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

local function new(args)
    args = args or {}

    args.icon_font = args.icon_font or beautiful.font
    args.icon = args.icon or nil
    args.font = args.font or beautiful.prompt_font or beautiful.font
    args.prompt = args.prompt or ""
    args.text = args.text or ""

    args.icon_color = args.icon_color or beautiful.colors.on_background or "#FFFFFF"
    args.prompt_color = args.prompt_color or beautiful.colors.on_background or "#FFFFFF"
    args.text_color = args.text_color or beautiful.colors.on_background or "#FFFFFF"
    args.cursor_color = args.cursor_color or beautiful.random_accent_color() or "#FF0000"

    args.always_on = args.always_on ~= nil and args.always_on or false
    args.reset_on_stop = args.reset_on_stop ~= nil and args.reset_on_stop or false
    args.obscure = args.obscure ~= nil and args.obscure or false
    args.keypressed_callback = args.keypressed_callback or nil
    args.changed_callback = args.changed_callback or nil
    args.done_callback = args.done_callback or nil

    local ret = gobject{}
    ret._private = {}
    ret._private.cur_pos = #args.text + 1 or 1

    gtable.crush(ret, prompt)
    gtable.crush(ret, args)

    args.child = wibox.widget.textbox()
    args.halign = args.halign or "left"
    args.on_press = function()
        if args.always_on == false then
            ret:toggle()
        end
    end

    ret.widget = ebutton.state(args)
    ret.textbox = args.child

    update_markup(ret, false)

    awful.mouse.append_client_mousebinding(awful.button({"Any"}, 1, function ()
        if args.always_on == false and ret.can_stop == true then
            ret:stop()
        end
    end))

    awful.mouse.append_client_mousebinding(awful.button({"Any"}, 3, function ()
        if args.always_on == false and ret.can_stop == true then
            ret:stop()
        end
    end))

    awful.mouse.append_global_mousebinding(awful.button({"Any"}, 1, function ()
        if args.always_on == false and ret.can_stop == true then
            ret:stop()
        end
    end))

    awful.mouse.append_global_mousebinding(awful.button({"Any"}, 3, function ()
        if args.always_on == false and ret.can_stop == true then
            ret:stop()
        end
    end))

    capi.tag.connect_signal("property::selected", function()
        if args.always_on == false then
            ret:stop()
        end
    end)

    capi.awesome.connect_signal("prompt::toggled_on", function(prompt)
        if args.always_on == false and  prompt ~= ret then
            ret:stop()
        end
    end)

    return ret
end

function prompt.mt:__call(...)
    return new(...)
end

return setmetatable(prompt, prompt.mt)