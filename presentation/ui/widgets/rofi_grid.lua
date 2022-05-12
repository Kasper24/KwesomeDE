local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local wibox = require("wibox")
local prompt = require("presentation.ui.widgets.prompt")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable
local string = string
local pairs = pairs
local table = table
local math = math

local rofi_grid = { mt = {} }

local function select_entry(self, x, y)
    local widgets = self.grid:get_widgets_at(x, y)
    if widgets then
        self._private.active_widget_x = x
        self._private.active_widget_y = y

        self._private.active_widget = widgets[1]
        if self._private.active_widget ~= nil then
            self._private.active_widget:turn_on()
            self._private.active_widget:emit_signal("selected")
        end
    end
end

local function unselect_entry(self)
    if self._private.active_widget ~= nil then
        self._private.active_widget:turn_off()
        self._private.active_widget:emit_signal("unselected")
        self._private.active_widget = nil
    end
end

local function search(self, text)
    unselect_entry(self)

    local pos = self.grid:get_widget_position(self._private.active_widget)

    -- Reset all the matched entries
    self._private.matched_entries = {}
    -- Remove all the grid widgets
    self.grid:reset()

    if text == "" then
        self._private.matched_entries = self._private.all_entries
    else
        for index, entry in pairs(self._private.all_entries) do
            text = text:gsub( "%W", "" )

            -- Check if there's a match by the entry name
            if string.find(entry.name, helpers.string.case_insensitive_pattern(text)) ~= nil then
                table.insert(self._private.matched_entries, entry)
            end
        end

        -- Sort by string similarity
        table.sort(self._private.matched_entries, function(a, b)
            return helpers.string.levenshtein(text, a.name) < helpers.string.levenshtein(text, b.name)
        end)
    end
    for index, entry in pairs(self._private.matched_entries) do
        -- Only add the widgets for entries that are part of the first page
        if #self.grid.children + 1 <= self._private.max_entries_per_page then
            self.grid:add(self.create_entry_widget(self, entry))
        end
    end

    -- Recalculate the entries per page based on the current matched entries
    self._private.entries_per_page = math.min(#self._private.matched_entries, self._private.max_entries_per_page)

    -- Recalculate the pages count based on the current entries per page
    self._private.pages_count = math.ceil(math.max(1, #self._private.matched_entries) / math.max(1, self._private.entries_per_page))

    -- Page should be 1 after a search
    self._private.current_page = 1

    -- This is an option to mimic rofi behaviour where after a search
    -- it will reselect the entry whose index is the same as the entry index that was previously selected
    -- and if matched_entries.length < current_index it will instead select the entry with the greatest index
    if self.try_to_keep_index_after_searching then
        if self.grid:get_widgets_at(pos.row, pos.col) == nil then
            local entry = self.grid.children[#self.grid.children]
            pos = self.grid:get_widget_position(entry)
        end
        select_entry(self, pos.row, pos.col)
    -- Otherwise select the first entry on the list
    else
        select_entry(self, 1, 1)
    end
end

local function page_backward(self, direction)
    if self._private.current_page > 1 then
        self._private.current_page = self._private.current_page - 1
    elseif self.wrap_page_scrolling and #self._private.matched_entries >= self._private.max_entries_per_page then
        self._private.current_page = self._private.pages_count
    elseif self.wrap_entries_scrolling then
        local rows, columns = self.grid:get_dimension()
        unselect_entry(self)
        select_entry(self, math.min(rows, #self.grid.children % self.entries_per_row), columns)
        return
    else
        return
    end

    local pos = self.grid:get_widget_position(self._private.active_widget)

    -- Remove the current page entries from the grid
    self.grid:reset()

    local max_entry_index_to_include = self._private.entries_per_page * self._private.current_page
    local min_entry_index_to_include = max_entry_index_to_include - self._private.entries_per_page

    for index, entry in pairs(self._private.matched_entries) do
        -- Only add widgets that are between this range (part of the current page)
        if index > min_entry_index_to_include and index <= max_entry_index_to_include then
            self.grid:add(self.create_entry_widget(self, entry))
        end
    end

    local rows, columns = self.grid:get_dimension()
    if self._private.current_page < self._private.pages_count then
        if direction == "up" then
            select_entry(self, rows, columns)
        else
            -- Keep the same row from last page
            select_entry(self, pos.row, columns)
        end
    elseif self.wrap_page_scrolling then
        if direction == "up" then
            select_entry(self, math.min(rows, #self.grid.children % self.entries_per_row), columns)
        else
            -- Keep the same row from last page
            select_entry(self, math.min(pos.row, #self.grid.children % self.entries_per_row), columns)
        end
    end
end

local function page_forward(self, direction)
    local min_entry_index_to_include = 0
    local max_entry_index_to_include = self._private.entries_per_page

    if self._private.current_page < self._private.pages_count then
        min_entry_index_to_include = self._private.entries_per_page * self._private.current_page
        self._private.current_page = self._private.current_page + 1
        max_entry_index_to_include = self._private.entries_per_page * self._private.current_page
    elseif self.wrap_page_scrolling and #self._private.matched_entries >= self._private.max_entries_per_page then
        self._private.current_page = 1
        min_entry_index_to_include = 0
        max_entry_index_to_include = self._private.entries_per_page
    elseif self.wrap_entry_scrolling then
        unselect_entry(self)
        select_entry(self, 1, 1)
        return
    else
        return
    end

    local pos = self.grid:get_widget_position(self._private.active_widget)

    -- Remove the current page entries from the grid
    self.grid:reset()

    for index, entry in pairs(self._private.matched_entries) do
        -- Only add widgets that are between this range (part of the current page)
        if index > min_entry_index_to_include and index <= max_entry_index_to_include then
            self.grid:add(self.create_entry_widget(self, entry))
        end
    end

    if self._private.current_page > 1 or self.wrap_page_scrolling then
        if direction == "down" then
            select_entry(self, 1, 1)
        else
            local last_col_max_row = math.min(pos.row, #self.grid.children % self.entries_per_row)
            if last_col_max_row ~= 0 then
                select_entry(self, last_col_max_row, 1)
            else
                select_entry(self, pos.row, 1)
            end
        end
    end
end

local function scroll_up(self)
    if #self.grid.children < 1 then
        self._private.active_widget = nil
        return
    end

    local rows, columns = self.grid:get_dimension()
    local pos = self.grid:get_widget_position(self._private.active_widget)
    local is_bigger_than_first_entry = pos.col > 1 or pos.row > 1

    -- Check if the current marked entry is not the first
    if is_bigger_than_first_entry then
        unselect_entry(self)
        if pos.row == 1 then
            select_entry(self, rows, pos.col - 1)
        else
            select_entry(self, pos.row - 1, pos.col)
        end
    else
       page_backward(self, "up")
    end
end

local function scroll_down(self)
    if #self.grid.children < 1 then
        self._private.active_widget = nil
        return
    end

    local rows, columns = self.grid:get_dimension()
    local pos = self.grid:get_widget_position(self._private.active_widget)
    local is_less_than_max_entry = self.grid:index(self._private.active_widget) < #self.grid.children

    -- Check if we can scroll down the entry list
    if is_less_than_max_entry then
        -- Unmark the previous entry
        unselect_entry(self)
        if pos.row == rows then
            select_entry(self, 1, pos.col + 1)
        else
            select_entry(self, pos.row + 1, pos.col)
        end
    else
        page_forward(self, "down")
    end
end

local function scroll_left(self)
    if #self.grid.children < 1 then
        self._private.active_widget = nil
        return
    end

    local pos = self.grid:get_widget_position(self._private.active_widget)
    local is_bigger_than_first_column = pos.col > 1

    -- Check if the current marked entry is not the first
    if is_bigger_than_first_column then
        unselect_entry(self)
        select_entry(self, pos.row, pos.col - 1)
    else
       page_backward(self, "left")
    end
end

local function scroll_right(self)
    if #self.grid.children < 1 then
        self._private.active_widget = nil
        return
    end

    local rows, columns = self.grid:get_dimension()
    local pos = self.grid:get_widget_position(self._private.active_widget)
    local is_less_than_max_column = pos.col < columns

    -- Check if we can scroll down the entry list
    if is_less_than_max_column then
        -- Unmark the previous entry
        unselect_entry(self)

        -- Scroll up to the max entry if there are directly to the right of previous entry
        if self.grid:get_widgets_at(pos.row, pos.col + 1) == nil then
            local entry = self.grid.children[#self.grid.children]
            pos = self.grid:get_widget_position(entry)
            select_entry(self, pos.row, pos.col)
        else
            select_entry(self, pos.row, pos.col + 1)
        end
    else
        page_forward(self, "right")
    end
end

local function reset(self)
    self.grid:reset()
    self._private.matched_entries = self._private.all_entries
    self._private.entries_per_page = self._private.max_entries_per_page
    self._private.pages_count = math.ceil(#self._private.all_entries / self._private.entries_per_page)
    self._private.current_page = 1

    for index, entry in pairs(self._private.all_entries) do
        -- Only add the entries that are part of the first page
        if index <= self._private.entries_per_page then
            self.grid:add(self.create_entry_widget(self, entry))
        else
            break
        end
    end

    select_entry(self, 1, 1)
end

function rofi_grid:start()
    self.prompt:start()
end

function rofi_grid:stop()
    self.prompt:stop()
    if self.reset_on_hide == true then
        reset(self)
    end
end

function rofi_grid:set_entries(entries)
    if self.sort_alphabetically then
        table.sort(entries, function(a, b)
            local entry_a_score = a.name:lower()
            if helpers.table.has_value(self.favorites, a.name) then
                entry_a_score = "aaaaaaaaaaa" .. entry_a_score
            end
            local entry_b_score = b.name:lower()
            if helpers.table.has_value(self.favorites, b.name) then
                entry_b_score = "aaaaaaaaaaa" .. entry_b_score
            end

            return entry_a_score < entry_b_score
        end)
    elseif self.reverse_sort_alphabetically then
        table.sort(entries, function(a, b)
            local entry_a_score = a.name:lower()
            if helpers.table.has_value(self.favorites, a.name) then
                entry_a_score = "zzzzzzzzzzz" .. entry_a_score
            end
            local entry_b_score = b.name:lower()
            if helpers.table.has_value(self.favorites, b.name) then
                entry_b_score = "zzzzzzzzzzz" .. entry_b_score
            end

            return entry_a_score > entry_b_score
        end)
    else
        table.sort(entries, function(a, b)
            local entry_a_favorite = helpers.table.has_value(self.favorites, a.name)
            local entry_b_favorite = helpers.table.has_value(self.favorites, b.name)

            if entry_a_favorite and not entry_b_favorite then
                return true
            elseif entry_b_favorite and not entry_a_favorite then
                return false
            elseif entry_a_favorite and entry_b_favorite then
                return a.name:lower() < b.name:lower()
            else
                return false
            end
        end)
    end

    self._private.all_entries = entries
    self._private.matched_entries = entries
    self._private.entries_per_page = self._private.max_entries_per_page
    self._private.pages_count = math.ceil(#self._private.all_entries / self._private.entries_per_page)

    local min_entry_to_incldue = (self._private.current_page - 1) * self._private.entries_per_page
    local max_entry_to_incldue = min_entry_to_incldue + self._private.entries_per_page

    self.grid:reset()
    for index, entry in pairs(self._private.all_entries) do
        -- Only add the entries that are part of the first page
        if index > min_entry_to_incldue and index <= max_entry_to_incldue then
            self.grid:add(self.create_entry_widget(self, entry))
        elseif index > max_entry_to_incldue then
            break
        end
    end

    if self.reset_on_hide == false and self._private.active_widget_x and self._private.active_widget_y then
        select_entry(self, self._private.active_widget_x, self._private.active_widget_y)
    else
        select_entry(self, 1, 1)
    end
end

function rofi_grid:select_entry(entry)
    -- Unmark the previous entry
    unselect_entry(self)

    -- Mark this entry
    local pos = self.grid:get_widget_position(entry)
    select_entry(self, pos.row, pos.col)
end

local function new(args)
    args = args or {}

    args.entries = args.entries or {}
    args.create_entry_widget = args.create_entry_widget or nil

    args.favorites = args.favorites or {}
    args.sort_alphabetically = args.sort_alphabetically == nil and true or args.sort_alphabetically
    args.reverse_sort_alphabetically = args.reverse_sort_alphabetically ~= nil and args.reverse_sort_alphabetically or false
    args.try_to_keep_index_after_searching = args.try_to_keep_index_after_searching ~= nil and args.try_to_keep_index_after_searching or false
    args.reset_on_hide = args.reset_on_hide == nil and true or args.reset_on_hide
    args.save_history = args.save_history == nil and true or args.save_history
    args.wrap_page_scrolling = args.wrap_page_scrolling == nil and true or args.wrap_page_scrolling
    args.wrap_entry_scrolling = args.wrap_entry_scrolling == nil and true or args.wrap_entry_scrolling
    args.shirnk_width = args.shirnk_width ~= nil and args.shirnk_width or false
    args.shrink_height = args.shrink_height ~= nil and args.shrink_height or false

    args.prompt_height = args.prompt_height or dpi(100)
    args.prompt_margins = args.prompt_margins or dpi(0)
    args.prompt_paddings = args.prompt_paddings or dpi(30)
    args.prompt_shape = args.prompt_shape or nil
    args.prompt_color = args.prompt_color or beautiful.fg_normal or "#FFFFFF"
    args.prompt_border_width = args.prompt_border_width or beautiful.border_width or dpi(0)
    args.prompt_border_color = args.prompt_border_color or beautiful.border_color or args.prompt_color
    args.prompt_text_halign = args.prompt_text_halign or "left"
    args.prompt_text_valign = args.prompt_text_valign or "center"
    args.prompt_icon_text_spacing = args.prompt_icon_text_spacing or dpi(10)
    args.prompt_show_icon = args.prompt_show_icon == nil and true or args.prompt_show_icon
    args.prompt_icon_font = args.prompt_icon_font or beautiful.font
    args.prompt_icon_color = args.prompt_icon_color or beautiful.bg_normal or "#000000"
    args.prompt_icon = args.prompt_icon or ""
    args.prompt_icon_markup = args.prompt_icon_markup or string.format("<span size='xx-large' foreground='%s'>%s</span>", args.prompt_icon_color, args.prompt_icon)
    args.prompt_text = args.prompt_text or "<b>Search</b>: "
    args.prompt_start_text = args.prompt_start_text or ""
    args.prompt_font = args.prompt_font or beautiful.font
    args.prompt_text_color = args.prompt_text_color or beautiful.bg_normal or "#000000"
    args.prompt_cursor_color = args.prompt_cursor_color or beautiful.bg_normal or "#000000"

    args.entries_per_row = args.entries_per_row or 5
    args.entries_per_column = args.entries_per_column or 3
    args.entries_margin = args.entries_margin or dpi(30)
    args.entries_spacing = args.entries_spacing or dpi(30)
    args.expand_entries = args.expand_entries == nil and true or args.expand_entries

    args.entry_width = args.entry_width or dpi(300)
    args.entry_height = args.entry_height or dpi(120)

    local ret = gobject{}
    gtable.crush(ret, rofi_grid)
    gtable.crush(ret, args)

    ret._private = {}
    ret._private.text = ""
    ret._private.all_entries = {}
    ret._private.matched_entries = {}
    ret._private.max_entries_per_page = ret.entries_per_column * ret.entries_per_row
    ret._private.entries_per_page = ret._private.max_entries_per_page
    ret._private.pages_count = 0
    ret._private.current_page = 1

    local grid_width  = nil
    local grid_height  = nil
    if ret.shirnk_width == true then
        grid_width = dpi((ret.entry_width * ret.entries_per_column) + ((ret.entries_per_column - 1) * ret.entries_spacing))
    end
    if ret.shrink_height == true then
        grid_height = dpi((ret.entry_height * ret.entries_per_row) + ((ret.entries_per_row - 1) * ret.entries_spacing))
    end

    ret.prompt = prompt
    {
        prompt = ret.prompt_text,
        text = ret.prompt_start_text,
        font = ret.prompt_font,
        reset_on_stop = ret.reset_on_hide,
        bg_cursor = ret.prompt_cursor_color,
        history_path = ret.save_history == true and helpers.filesystem.get_cache_dir("history") or nil,
        changed_callback = function(text)
            if text == ret._private.text then
                return
            end

            if ret._private.search_timer ~= nil and ret._private.search_timer.started then
                ret._private.search_timer:stop()
            end

            ret._private.search_timer = gtimer {
                timeout = 0.05,
                autostart = true,
                single_shot = true,
                callback = function()
                    search(ret, text)
                end
            }

            ret._private.text = text
        end,
        keypressed_callback = function(mod, key, cmd)
            if key == "Escape" then
                ret:hide()
            end
            if key == "Return" then
                if ret._private.active_widget ~= nil then
                    ret._private.active_widget.spawn()
                end
            end
            if key == "Up" then
                scroll_up(ret)
            end
            if key == "Down" then
                scroll_down(ret)
            end
            if key == "Left" then
                scroll_left(ret)
            end
            if key == "Right" then
                scroll_right(ret)
            end
        end
    }

    ret.grid = wibox.widget
    {
        layout = wibox.layout.grid,
        forced_width = dpi((ret.entry_width * ret.entries_per_column) + ((ret.entries_per_column - 1) * ret.entries_spacing)),
        forced_height = dpi((ret.entry_height * ret.entries_per_row) + ((ret.entries_per_row - 1) * ret.entries_spacing)),
        orientation = "horizontal",
        homogeneous = true,
        expand = ret.expand_entries,
        spacing = ret.entries_spacing,
        forced_num_rows = ret.entries_per_row,
        forced_num_cols = ret.entries_per_column,
        buttons =
        {
            awful.button({}, 4, function() scroll_up(ret) end),
            awful.button({}, 5, function() scroll_down(ret) end)
        }
    }

    ret:set_entries(ret.entries)

	return ret
end

function rofi_grid.mt:__call(...)
    return new(...)
end

return setmetatable(rofi_grid, rofi_grid.mt)