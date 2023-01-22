-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("presentation.ui.widgets")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local ipairs = ipairs
local capi = { client = client }

local window_switcher  = { }
local instance = nil

local function focus_client(client)
    capi.client.focus = client

    capi.client.focus:raise()
    capi.client.focus.minimized = false

    if capi.client.focus:tags() and capi.client.focus:tags()[1] then
        capi.client.focus:tags()[1]:view_only()
    else
        capi.client.focus:tags({awful.screen.focused().selected_tag})
    end
end

local function cycle_clients(self, increase)
    self._private.selected_index = self._private.selected_index + (increase and 1 or -1)

    if self._private.selected_index > #capi.client.get() then
        self._private.selected_index = 1
    end
    if self._private.selected_index < 1 then
        self._private.selected_index = #capi.client.get()
    end

    focus_client(capi.client.get()[self._private.selected_index])
end

local function get_client_content_as_imagebox(c)
    local ss = awful.screenshot {
        client = c,
    }

    ss:refresh()
    local ib = ss.content_widget
    ib.valign = "center"
    ib.halign = "center"
    ib.horizontal_fit_policy = "fit"
    ib.vertical_fit_policy = "fit"
    ib.resize = true

    return ib
end

local function client_button(client)
    local font_icon = beautiful.get_font_icon_for_app_name(client.class)

    for _, tag in ipairs(client:tags()) do
        if tag.selected then
            client.window_switcher_thumbnail = get_client_content_as_imagebox(client)
        end
    end

    return wibox.widget
    {
        widget = wibox.container.background,
        id = "bg_role",
        forced_width = dpi(150),
        forced_height = dpi(250),
        {
            layout = wibox.layout.flex.vertical,
            {
                widget = wibox.container.margin,
                margins = dpi(5),
                client.window_switcher_thumbnail
            },
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(5),
                {
                    widget = wibox.container.place,
                    forced_width = dpi(40),
                    valign = "center",
                    {
                        widget = widgets.text,
                        color = beautiful.random_accent_color(),
                        font = font_icon.font,
                        text = font_icon.icon
                    }
                },
                {
                    widget = wibox.container.margin,
                    margins = dpi(10),
                    {
                        widget = wibox.widget.textbox,
                        forced_width = dpi(200),
                        valign = "center",
                        text = client.name
                    }
                }
            }
        }
    }
end

function window_switcher:show()
    if #capi.client.get() == 0 then
        return
    end

    -- Store client that is focused in a variable
    self._private.window_switcher_first_client = capi.client.focus

    -- Stop recording focus history
    awful.client.focus.history.disable_tracking()

    -- Go to previously focused client (in the tag)
    awful.client.focus.history.previous()

    -- Start the keygrabber
    self._private.window_switcher_grabber = awful.keygrabber.run(function(_, key, event)
        if event == "release" then
            -- Hide if the modifier was released
            -- We try to match Super or Alt or Control since we do not know which keybind is
            -- used to activate the window switcher (the keybind is set by the user in keys.lua)
            if key:match("Super") or key:match("Alt") or key:match("Control") then
                self:hide()
            end
            -- Do nothing
            return
        end

        -- Run function attached to key, if it exists
        if self._private.keyboard_keys[key] then
            self._private.keyboard_keys[key]()
        end
    end)

    local layout = wibox.layout.fixed.horizontal()

    for _, client in ipairs(capi.client.get()) do
        layout:add(client_button(client))
    end

    local widget = wibox.widget
    {
        widget = wibox.container.background,
        shape = helpers.ui.rrect(beautiful.border_radius),
        bg = beautiful.colors.background,
        {
            widget = wibox.container.margin,
            margins = dpi(10),
            layout
        }
    }

    self._private.widget.widget = widget
    self._private.widget.visible = true
end

function window_switcher:hide()
    -- Add currently focused client to history
    if capi.client.focus then
        local window_switcher_last_client = capi.client.focus
        awful.client.focus.history.add(window_switcher_last_client)
        -- Raise client that was focused originally
        -- Then raise last focused client
        if
            self._private.window_switcher_first_client and self._private.window_switcher_first_client.valid
        then
            self._private.window_switcher_first_client:raise()
            window_switcher_last_client:raise()
        end
    end

    -- Resume recording focus history
    awful.client.focus.history.enable_tracking()

    -- Stop the key grabber
    awful.keygrabber.stop(self._private.window_switcher_grabber)

    -- Hide the widget
    self._private.widget.visible = false
    self._private.widget.widget = nil

    collectgarbage("collect")
end

function window_switcher:toggle()
    if self._private.widget.visible == true then
        self:hide()
    else
        self:show()
    end
end

local function new(args)
    args = args or {}

    local ret = gobject{}
    ret._private = {}

    -- The client that was focused when the window_switcher was activated
    ret._private.window_switcher_first_client = {}
    -- The mouse grabber object
    ret._private.window_switcher_grabber = nil

    ret._private.selected_index = 1


    gtable.crush(ret, window_switcher)
    gtable.crush(ret, args)

    ret._private.widget = awful.popup
    {
        type = 'dropdown_menu',
        placement = awful.placement.centered,
        visible = false,
        ontop = true,
        bg = "#00000000",
        widget = wibox.container.background, -- A dummy widget to make awful.popup not scream
    }

    ret._private.mouse_keys = {
        awful.button {
            modifiers = { "Any" },
            button = 1,
            on_press = function(c)
                capi.client.focus = c
            end,
        },

        awful.button {
            modifiers = { "Any" },
            button = 4,
            on_press = function()
                awful.client.focus.byidx(-1)
            end,
        },

        awful.button {
            modifiers = { "Any" },
            button = 5,
            on_press = function()
                awful.client.focus.byidx(1)
            end,
        }
    }

    ret._private.keyboard_keys = {
        ["Escape"] = function()
            ret:hide()
        end,

        ["n"] = function()
            if capi.client.focus then
                capi.client.focus.minimized = true
            end
        end,
        ["N"] = function()
            if awful.client.restore() then
                capi.client.focus = awful.client.restore()
            end
        end,
        ['q'] = function()
            if capi.client.focus then
                capi.client.focus:kill()
            end
        end,

        ["Tab"] = function()
            cycle_clients(ret, true)

            -- capi.client.focus = gtable.cycle_value(capi.client.get(), capi.client.focus, 1)
            -- capi.client.focus:raise()
            -- capi.client.focus.minimized = false
            -- capi.client.focus:tags()[1]:view_only()

            -- if capi.client.focus:tags() and capi.client.focus:tags()[1] then
            --     capi.client.focus:tags()[1]:view_only()
            -- else
            --     capi.client.focus:tags({awful.screen.focused().selected_tag})
            -- end
        end,

        ["Left"] = function()
            awful.client.focus.byidx(1)
        end,
        ["Right"] = function()
            awful.client.focus.byidx(-1)
        end,

        ['h'] = function()
            awful.client.focus.byidx(1)
        end,
        ['l'] = function()
            awful.client.focus.byidx(-1)
        end,
    }

    ret._private.widget:connect_signal("property::width", function()
        if ret._private.widget.visible and get_num_clients() == 0 then
            ret:hide()
        end
    end)

    ret._private.widget:connect_signal("property::height", function()
        if ret._private.widget.visible and get_num_clients() == 0 then
            ret:hide()
        end
    end)

    return ret
end

if not instance then
    instance = new()
end
return instance