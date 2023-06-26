-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local web_notifications = { mt = {} }

local path = ...
local email = require(path .. ".email")
local github = require(path .. ".github")
local gitlab = require(path .. ".gitlab")

local function new()
    return wibox.widget {
        widget = widgets.navigator.horizontal,
        buttons_selected_color = beautiful.icons.envelope.color,
        tabs = {
            {
                {
                    id = "github",
                    icon = beautiful.icons.github,
                    title = "Github",
                    halign = "center",
                    tab = github(),
                },
                {
                    id = "gitlab",
                    icon = beautiful.icons.gitlab,
                    title = "Gitlab",
                    halign = "center",
                    tab = gitlab(),
                },
                {
                    id = "email",
                    icon = beautiful.icons.envelope,
                    title = "Email",
                    halign = "center",
                    tab = email(),
                }
            }
        }
    }
end

function web_notifications.mt:__call()
    return new()
end

return setmetatable(web_notifications, web_notifications.mt)
