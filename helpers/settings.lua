-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local Gio = require("lgi").Gio
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local gstring = require("gears.string")
local gdebug = require("gears.debug")
local filesystem = require("external.filesystem")
local json = require("external.json")
local string = string
local type = type

local settings = {}
local instance = nil

local DATA_PATH = filesystem.filesystem.get_cache_dir("settings") .. "data.json"

local function get_setting_from_string(self, paths)
    local setting = self.settings
    local t = paths
    paths = gstring.split(paths, ".")
    for _, path in ipairs(paths) do
        setting = setting[path]
    end
    return setting
end

local function merge_settings(default_settings, saved_settings)
    for key, value in pairs(default_settings) do
        if type(value) == "table" then
            -- Check if the table exists in saved settings
            if saved_settings[key] == nil or type(saved_settings[key]) ~= "table" then
                saved_settings[key] = value
                print("Table '" .. key .. "' is missing or invalid in saved settings.")
            else
                -- Recursively compare nested tables
                merge_settings(value, saved_settings[key])
            end
        else
            -- Check if the setting exists in saved settings
            if saved_settings[key] == nil then
                print("Setting '" .. key .. "' is missing in saved settings.")
            end
        end
    end
end

local function get_default_settings()
    return [[{
        "kwesomede": {
            "version": {
                "default": "-1",
                "type": "string",
                "description": "KwesomeDE version"
            }
        },
        "airplane": {
            "enabled": {
                "default": false,
                "type": "boolean",
                "description": "Enable or disable Airplane mode"
            }
        },
        "redshift": {
            "enabled": {
                "default": false,
                "type": "boolean",
                "description": "Enable or disable Redshift"
            }
        },
        "notifications": {
            "dont_disturb": {
                "default": false,
                "type": "boolean",
                "description": "Disable notifications when enabled"
            }
        },
        "tasklist": {
            "pinned_apps": {
                "default": [],
                "type": "table",
                "description": "Pinned apps on the tasklist"
            }
        },
        "app_launcher": {
            "pinned_apps": {
                "default": [],
                "type": "table",
                "description": "Pinned apps on the app launcher"
            }
        },
        "picom": {
            "enabled": {
                "default": true,
                "type": "boolean",
                "description": "Enable or disable picom"
            },
            "shadow": {
                "default": true,
                "type": "boolean",
                "description": "Enable or disable picom shadows"
            },
            "fading": {
                "default": true,
                "type": "boolean",
                "description": "Enable or disable picom fading"
            },
            "animations": {
                "default": false,
                "type": "boolean",
                "description": "Enable or disable picom animations"
            },
            "animation_stiffness": {
                "default": 200,
                "type": "number",
                "description": "Stiffness (a.k.a. tension) parameter for spring-based animation"
            },
            "animation_stiffness_in_tag": {
                "default": 200,
                "type": "number",
                "description": "Animation speed in current tag (float)."
            },
            "animation_stiffness_tag_change": {
                "default": 200,
                "type": "number",
                "description": "Animation speed when tag changes (change to a new desktop)."
            },
            "animation_dampening": {
                "default": 25,
                "type": "number",
                "description": "Dampening (a.k.a. friction) parameter for spring-based animation"
            },
            "animation_window_mass": {
                "default": 1,
                "type": "number",
                "description": "Mass parameter for spring-based animation"
            },
            "animation_clamping": {
                "default": true,
                "type": "boolean",
                "description": "Whether to clamp animations"
            },
            "active_opacity": {
                "default": 0.9,
                "type": "number",
                "description": "The opacity of the currently focused client"
            },
            "inactive_opacity": {
                "default": 0.5,
                "type": "number",
                "description": "The opacity of inactive clients"
            },
            "shadow_radius": {
                "default": 12,
                "type": "number",
                "description": "The blur radius for shadows"
            },
            "shadow_offset_x": {
                "default": -15,
                "type": "number",
                "description": "The left offset for shadows"
            },
            "shadow_offset_y": {
                "default": -15,
                "type": "number",
                "description": "The top offset for shadows, in pixels"
            },
            "shadow_opacity": {
                "default": 0.75,
                "type": "number",
                "description": "The translucency for shadows"
            },
            "fade_delta": {
                "default": 10,
                "type": "number",
                "description": "The time between steps in a fade in milliseconds"
            },
            "fade_in_step": {
                "default": 0.028,
                "type": "number",
                "description": "Opacity change between steps while fading in"
            },
            "fade_out_step": {
                "default": 0.03,
                "type": "number",
                "description": "Opacity change between steps while fading out"
            },
            "corner_radius": {
                "default": 0,
                "type": "number",
                "description": "How much rounding to apply to the clients"
            },
            "blur_strength": {
                "default": 10,
                "type": "number",
                "description": "Blur amount"
            }
        },
        "theme": {
            "colorschemes": {
                "default": {
                    "~/.config/awesome/assets/wallpapers/52_by_gydw1n_dblxpwi.jpg": [
                        "#010610",
                        "#2C5F9A",
                        "#2C5F9A",
                        "#2972E4",
                        "#4C7ADD",
                        "#488CB1",
                        "#3493ED",
                        "#a1c5ee",
                        "#04183f",
                        "#0e5db8",
                        "#0e5db8",
                        "#0e6cff",
                        "#2c6ffd",
                        "#2397d7",
                        "#2294ff",
                        "#ffffff"
                    ],
                    "~/.config/awesome/assets/wallpapers/mysterious.jpg": [
                        "#05142D",
                        "#78899F",
                        "#78899F",
                        "#8A98AC",
                        "#989BAA",
                        "#96A5B9",
                        "#9CADC2",
                        "#cdd3db",
                        "#0a285a",
                        "#5685c2",
                        "#5685c2",
                        "#6c93ca",
                        "#7c88c6",
                        "#7ca1d3",
                        "#84abda",
                        "#ffffff"
                    ]
                },
                "type": "table",
                "description": "All the generated colorschemes"
            },
            "active_colorscheme": {
                "default": "~/.config/awesome/assets/wallpapers/mysterious.jpg",
                "type": "string",
                "description": "The active colorscheme"
            },
            "active_wallpaper": {
                "default": "~/.config/awesome/assets/wallpapers/mysterious.jpg",
                "type": "string",
                "description": "The active wallpaper"
            },
            "wallpaper_type": {
                "default": "image",
                "type": "string",
                "description": "The wallpaper type (image/sun/binary/etc)"
            },
            "run_on_set": {
                "default": "",
                "type": "string",
                "description": "Run command after setting wallpaper/colorscheme"
            }
        },
        "ui": {
            "profile_image": {
                "description": "The user profile image",
                "type": "string"
            },
            "dpi": {
                "default": 96,
                "type": "number",
                "description": "Scale of UI elements"
            },
            "opacity": {
                "default": 0.4,
                "type": "number",
                "description": "The opacity of AwesomeWM UI elements"
            },
            "border_radius": {
                "default": 12,
                "type": "number",
                "description": "The border radius of AwesomeWM UI elements"
            },
            "show_lockscreen_on_login": {
                "default": false,
                "type": "boolean",
                "description": "Show the lockscreen on login"
            },
            "animations": {
                "enabled": {
                    "default": true,
                    "type": "boolean",
                    "description": "Enable or disable UI animations"
                },
                "framerate": {
                    "default": 144,
                    "type": "number",
                    "description": "The framerate of the UI animations"
                }
            }
        },
        "layout": {
            "client_gap": {
                "default": 0,
                "type": "number",
                "description": "The gap between the screen and the clients"
            },
            "useless_gap": {
                "default": 0,
                "type": "number",
                "description": "The gap between the clients"
            }
        },
        "wallpaper_engine": {
            "command": {
                "default": "~/.config/awesome/assets/wallpaper-engine/binary/linux-wallpaperengine",
                "type": "string",
                "description": "The command to launch or path to wallpaper engine binary"
            },
            "workshop_folder": {
                "default": "",
                "type": "string",
                "description": "The framerate of the UI animations"
            },
            "assets_folder": {
                "default": "~/.config/awesome/assets/wallpaper-engine/assets",
                "type": "string",
                "description": "The framerate of the UI animations"
            },
            "fps": {
                "default": 24,
                "type": "number",
                "description": "The framerate of the UI animations"
            }
        },
        "screenshot": {
            "show_cursor": {
                "default": true,
                "type": "boolean",
                "description": "Should the cursor show in the screenshot"
            },
            "delay": {
                "default": 1,
                "type": "number",
                "description": "How much time to wait before taking the screenshot"
            },
            "folder": {
                "default": "~/",
                "type": "string",
                "description": "Where to save the screenshots"
            }
        },
        "recorder": {
            "resolution": {
                "default": "1920x1080",
                "type": "string",
                "description": "The resolution of the recording"
            },
            "fps": {
                "default": 60,
                "type": "number",
                "description": "The recording frame rate"
            },
            "delay": {
                "default": 0,
                "type": "number",
                "description": "How much time to wait before starting to record"
            },
            "folder": {
                "default": "~/",
                "type": "string",
                "description": "The file format of the recording"
            },
            "format": {
                "default": "mp4",
                "type": "string",
                "description": "The file format of the recording"
            }
        },
        "github": {
            "username": {
                "default": "",
                "type": "string",
                "description": "Your Github username"
            }
        },
        "gitlab": {
            "host": {
                "default": "https://gitlab.com",
                "type": "string",
                "description": "Your Gitlab host URL"
            }
        },
        "email": {
            "feed_address": {
                "default": "https://mail.google.com/mail/feed/atom",
                "type": "string",
                "description": "Your email feed address"
            }
        },
        "openweather": {
            "latitude": {
                "default": "40.730610",
                "type": "string",
                "description": "The latitude at your location"
            },
            "longitude": {
                "default": "73.935242",
                "type": "string",
                "description": "The Longitude at your location"
            },
            "unit": {
                "default": "metric",
                "type": "string",
                "description": "The measurement systems to use. 'metric' for Celcius, 'imperial' for Fahrenheit"
            }
        }
    }]]
end

function settings:set(key, value)
    local setting = get_setting_from_string(self, key)

    if type(value) ~= setting.type then
        gdebug.print_warning(string.format("Trying to save %s of type %s to type %s", key, setting.type, type(value)))
        return
    end

    setting.value = value
    self.save_timer:again()
end

function settings:get(key)
    local setting = get_setting_from_string(self, key)
    local value = setting.value ~= nil and setting.value or setting.default

    if type(value) == "table" then
        value = gtable.clone(value, true)
    end

    return value
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, settings, true)

    local file = filesystem.file.new_for_path(DATA_PATH)
    if file:exists_block() then
        ret.settings = json.decode(Gio.File.new_for_path(DATA_PATH):load_contents())
    else
        ret.settings = json.decode(get_default_settings())
    end
    ret.default_settings = json.decode(get_default_settings())
    merge_settings(ret.default_settings, ret.settings)

    ret.save_timer = gtimer
    {
        timeout = 1,
        autostart = false,
        call_now = false,
        single_shot = true,
        callback = function()
            local _settings_status, settings = pcall(function()
                return json.encode(ret.settings)
            end)
            if not _settings_status or not settings then
                gdebug.print_warning(
                    "Failed to encode settings! " ..
                    "Settings will not be saved. "
                )
            else
                file:write(settings)
            end
        end
    }

    local mt = {
        __index = function(self, key)
            return ret:get(key)
        end,
        __newindex = function(self, key, value)
            ret:set(key, value)
        end
    }

    setmetatable(ret, mt)

    return ret
end

if not instance then
    instance = new()
end
return instance
