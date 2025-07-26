-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2025 Kasper24
-------------------------------------------
local lgi = require("lgi")
local Secret = lgi.Secret
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local library = require("library")
local filesystem = require("external.filesystem")
local json = require("external.json")
local string = string
local ipairs = ipairs

local gitlab = {}
local instance = nil

local LINK = "%s/api/v4/merge_requests?private_token=%s"
local PATH = filesystem.filesystem.get_data_dir("gitlab/created_prs")
local AVATARS_PATH = PATH .. "avatars/"
local DATA_PATH = PATH .. "data.json"

local UPDATE_INTERVAL = 60 * 30 -- 30 mins

function gitlab:set_host(host)
	self._private.host = host
	library.settings["gitlab.host"] = host
	self:refresh()
end

function gitlab:get_host()
	if self._private.host == nil then
		self._private.host = library.settings["gitlab.host"]
	end

	return self._private.host or ""
end

function gitlab:set_access_token(access_token)
	Secret.password_store(
		self._private.access_token_schema,
		self._private.access_token_atrributes,
		Secret.COLLECTION_DEFAULT,
		"access token",
		access_token,
		nil,
		function(source, result, unused)
			local success = Secret.password_store_finish(result)
			if success then
				self._private.access_token = access_token
				self:refresh()
			end
		end
	)
end

function gitlab:get_access_token()
	if self._private.access_token == nil then
		self._private.access_token =
			Secret.password_lookup_sync(self._private.access_token_schema, self._private.access_token_atrributes)
	end

	return self._private.access_token or ""
end

function gitlab:get_avatars_path()
	return AVATARS_PATH
end

function gitlab:refresh()
	if self:get_host() == "" or self:get_access_token() == "" then
		self:emit_signal("error::missing_credentials")
		return
	end

	local old_data = nil

	filesystem.filesystem.remote_watch(
		DATA_PATH,
		string.format(LINK, self:get_host(), self._private.access_token),
		UPDATE_INTERVAL,
		function(content)
			local data = json.decode(content)
			if data == nil then
				self:emit_signal("error")
				return
			end

			for _, mr in ipairs(data) do
				if old_data == nil or old_data[mr.id] == nil then
					local remote_file = filesystem.file.new_for_uri(mr.author.avatar_url)
					remote_file:read(function(error, content)
						if error == nil then
							local file = filesystem.file.new_for_path(AVATARS_PATH .. mr.author.id)
							file:write(content, function(error)
								local first_download = old_data == nil
								self:emit_signal("new_mr", mr, first_download)
							end)
						end
					end)
				end
			end
		end,
		function(old_content)
			local data = json.decode(old_content) or {}
			if old_data == nil and data ~= nil then
				self:emit_signal("mrs", data)
			end

			old_data = {}
			for _, pr in ipairs(data) do
				old_data[pr.id] = pr.id
			end
		end
	)
end

local function new()
	local ret = gobject({})
	gtable.crush(ret, gitlab, true)

	ret._private = {}
	ret._private.access_token_atrributes = {
		["org.kwesomede.gitlab.access-token"] = "gitlab access token",
	}
	ret._private.access_token_schema = Secret.Schema.new("org.kwesomede", Secret.SchemaFlags.NONE, {
		["org.kwesomede.gitlab.access-token"] = Secret.SchemaAttributeType.STRING,
	})

	gtimer.delayed_call(function()
		ret:refresh()
	end)

	return ret
end

if not instance then
	instance = new()
end
return instance
