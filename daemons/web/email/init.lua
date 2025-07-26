-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local lgi = require("lgi")
local Secret = lgi.Secret
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local gstring = require("gears.string")
local library = require("library")
local filesystem = require("external.filesystem")
local xml = require("external.xml2lua.xml2lua")
local handler = require("external.xml2lua.xmlhandler.tree")
local ipairs = ipairs
local string = string

local email = {}
local instance = nil

local PATH = filesystem.filesystem.get_data_dir("email")
local DATA_PATH = PATH .. "data.json"

local UPDATE_INTERVAL = 60 * 30 -- 30 mins

function email:set_feed_address(feed_address)
	self._private.feed_address = feed_address
	library.settings["email.feed_address"] = feed_address
	self:refresh()
end

function email:get_feed_address()
	if self._private.feed_address == nil then
		self._private.feed_address = library.settings["email.feed_address"]
	end

	return self._private.feed_address or ""
end

function email:set_address(address)
	Secret.password_store(
		self._private.address_schema,
		self._private.address_atrributes,
		Secret.COLLECTION_DEFAULT,
		"address",
		address,
		nil,
		function(source, result, unused)
			local success = Secret.password_store_finish(result)
			if success then
				self._private.address = address
				self:refresh()
			end
		end
	)
end

function email:get_address()
	if self._private.address == nil then
		self._private.address =
			Secret.password_lookup_sync(self._private.address_schema, self._private.address_atrributes)
	end

	return self._private.address or ""
end

function email:set_app_password(app_password)
	Secret.password_store(
		self._private.app_password_schema,
		self._private.app_password_atrributes,
		Secret.COLLECTION_DEFAULT,
		"password",
		app_password,
		nil,
		function(source, result, unused)
			local success = Secret.password_store_finish(result)
			if success then
				self._private.app_password = app_password
				self:refresh()
			end
		end
	)
end

function email:get_app_password()
	if self._private.app_password == nil then
		self._private.app_password =
			Secret.password_lookup_sync(self._private.app_password_schema, self._private.app_password_atrributes)
	end

	return self._private.app_password or ""
end

function email:refresh()
	if self:get_feed_address() == "" or self:get_address() == "" or self:get_app_password() == "" then
		self:emit_signal("error::missing_credentials")
		return
	end

	local old_data = nil
	local file = filesystem.file.new_for_path(DATA_PATH)
	file:read(function(error, content)
		if error == nil then
			local emails_handler = handler:new()
			local emails_parser = xml.parser(emails_handler)

			emails_parser:parse(content)

			if emails_handler.error then
				self:emit_signal("error", emails_handler.error)
			else
				if old_data == nil and emails_handler.root.feed.entry ~= nil then
					self:emit_signal("emails", emails_handler.root.feed.entry)
				end

				old_data = {}
				for _, email in ipairs(emails_handler.root.feed.entry) do
					old_data[email.id] = email.id
				end
			end
		end

		awful.spawn.easy_async(
			string.format("curl -f %s -u %s:'%s'", self:get_feed_address(), self:get_address(), self:get_app_password()),
			function(stdout)
				local emails_handler = handler:new()
				local emails_parser = xml.parser(emails_handler)
				emails_parser:parse(stdout)

				if emails_handler.error then
					self:emit_signal("error", emails_handler.error)
					return
				end

				if emails_handler.root and emails_handler.root.feed then
					for _, email in ipairs(emails_handler.root.feed.entry) do
						if old_data == nil or old_data[email.id] == nil then
							local first_download = old_data == nil
							self:emit_signal("new_email", email, first_download)
						end
					end

					file:write(stdout)
				else
					self:emit_signal("error")
				end
			end
		)
	end)
end

local function new()
	local ret = gobject({})
	gtable.crush(ret, email, true)

	ret._private = {}
	ret._private.address_atrributes = {
		["org.kwesomede.email.address"] = "email address",
	}
	ret._private.address_schema = Secret.Schema.new("org.kwesomede", Secret.SchemaFlags.NONE, {
		["org.kwesomede.email.address"] = Secret.SchemaAttributeType.STRING,
	})
	ret._private.app_password_atrributes = {
		["org.kwesomede.email.app_password"] = "email app password",
	}
	ret._private.app_password_schema = Secret.Schema.new("org.kwesomede", Secret.SchemaFlags.NONE, {
		["org.kwesomede.email.app_password"] = Secret.SchemaAttributeType.STRING,
	})

	gtimer.delayed_call(function()
		gtimer({
			timeout = UPDATE_INTERVAL,
			autostart = true,
			call_now = true,
			callback = function()
				ret:refresh()
			end,
		})
	end)

	return ret
end

if not instance then
	instance = new()
end
return instance
