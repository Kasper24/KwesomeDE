-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local gtable = require("gears.table")
local gstring = require("gears.string")
local wibox = require("wibox")
local beautiful = require("beautiful")
local helpers = require("helpers")
local setmetatable = setmetatable
local tostring = tostring
local string = string

local text = { mt = {} }

local properties =
{
	"bold", "italic", "size",
	"color", "icon", "text"
}

local function generate_markup(self)
	local bold_start = ""
	local bold_end = ""
	local italic_start = ""
	local italic_end = ""

	if self._private.bold == true then
		bold_start = "<b>"
		bold_end = "</b>"
	end
	if self._private.italic == true then
		italic_start = "<i>"
		italic_end = "</i>"
	end

	-- Need to unescape in a case the text was escaped by other code before
	self._private.text = gstring.xml_unescape(tostring(self._private.text))
	self._private.text = gstring.xml_escape(tostring(self._private.text))

	if self._private.icon == nil then
		local size = (self._private.size or 20) * 1024
		self.markup = string.format("<span font_size='%s'>", size) .. bold_start .. italic_start ..
			helpers.ui.colorize_text(self._private.text, self._private.color) ..
			italic_end .. bold_end .. "</span>"
	else
		local size = (self._private.icon.size or 20) * 1024
		self.markup = string.format("<span font_size='%s'>", size) .. bold_start .. italic_start ..
			helpers.ui.colorize_text(self._private.icon.icon, self._private.icon.color) ..
			italic_end .. bold_end .. "</span>"
	end
end

local function build_properties(prototype, prop_names)
    for _, prop in ipairs(prop_names) do
        if not prototype["set_" .. prop] then
            prototype["set_" .. prop] = function(self, value)
                if self._private[prop] ~= value then
                    self._private[prop] = value
					generate_markup(self)
                    self:emit_signal("widget::redraw_needed")
                    self:emit_signal("property::"..prop, value)
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

local function new(args)
	local widget = wibox.widget.textbox()
	gtable.crush(widget, text, true)

	args = args or {}

	widget._private.bold = args.bold or false
	widget._private.italic = args.italic or false
	widget._private.size = args.size or 20
	widget._private.color = args.color or beautiful.colors.on_background
	widget._private.text = args.text or ""
	widget._private.icon = args.icon or nil

	-- Set markup for initialaztion
	generate_markup(widget)

	return widget
end

function text.mt:__call(...)
    return new(...)
end

build_properties(text, properties)

return setmetatable(text, text.mt)