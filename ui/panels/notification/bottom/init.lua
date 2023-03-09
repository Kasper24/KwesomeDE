-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local setmetatable = setmetatable

local bottom = { mt = {} }

local path = ...
local email = require(path .. ".email")
local github = require(path .. ".github")
local gitlab = require(path .. ".gitlab")

local function new()
    local email = email()
    local github = github()
    local gitlab = gitlab()

    local content = wibox.widget
    {
        layout = wibox.layout.stack,
        top_only = true,
        email,
        github,
        gitlab
    }

    local email_button = nil
    local github_button = nil
    local gitlab_button = nil

    email_button = wibox.widget
    {
        widget = widgets.button.text.state,
        on_by_default = true,
        size = 15,
        on_normal_bg = beautiful.icons.envelope.color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        text = "Email",
        animate_size = false,
        on_release = function()
            email_button:turn_on()
            github_button:turn_off()
            gitlab_button:turn_off()
            content:raise_widget(email)
        end
    }

    github_button = wibox.widget
    {
        widget = widgets.button.text.state,
        size = 15,
        on_normal_bg = beautiful.icons.envelope.color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        text = "Github",
        animate_size = false,
        on_release = function()
            email_button:turn_off()
            github_button:turn_on()
            gitlab_button:turn_off()
            content:raise_widget(github)
        end
    }

    gitlab_button = wibox.widget
    {
        widget = widgets.button.text.state,
        size = 15,
        on_normal_bg = beautiful.icons.envelope.color,
        text_normal_bg = beautiful.colors.on_background,
        text_on_normal_bg = beautiful.colors.on_accent,
        text = "Gitlab",
        animate_size = false,
        on_release = function()
            email_button:turn_off()
            github_button:turn_off()
            gitlab_button:turn_on()
            content:raise_widget(gitlab)
        end
    }

    return wibox.widget
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(10),
        {
            layout = wibox.layout.flex.horizontal,
            spacing = dpi(10),
            email_button,
            github_button,
            gitlab_button
        },
        content
    }
end

function bottom.mt:__call()
    return new()
end

return setmetatable(bottom, bottom.mt)