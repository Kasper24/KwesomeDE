-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local wibox = require("wibox")
local widgets = require("ui.widgets")
local beautiful = require("beautiful")
local desktop_daemon = require("daemons.system.desktop")
local helpers = require("helpers")
local filesystem = require("external.filesystem")
local dpi = beautiful.xresources.apply_dpi
local capi = {
    mousegrabber = mousegrabber
}

local desktop = {}
local instance = nil

local mimetype_to_image_lookup_table = {
    -- Image
    ["application/pdf"] = "lximage", -- AI
    ["image/x-ms-bmp"] = "lximage", -- BMP
    ["application/postscript"] = "lximage", -- EPS
    ["image/gif"] = "lximage", -- GIF
    ["application/vnd.microsoft.icon"] = "lximage", -- ICo
    ["image/jpeg"] = "lximage", -- JPEG
    ["image/jp2"] = "lximage", -- JPEG 2000
    ["image/png"] = "lximage", -- PNG
    ["image/vnd.adobe.photoshop"] = "lximage", -- PSD
    ["image/svg+xml"] = "lximage", -- SVG
    ["image/tiff"] = "lximage", -- TIFF
    ["image/webp"] = "lximage", -- webp

    -- Video
    ["video/3gpp"] = "videoplayer", -- 3GP
    ["video/3gpp2"] = "videoplayer", -- 3GP2
    ["video/x-msvideo"] = "videoplayer", -- AVI
    ["video/x-flv"] = "videoplayer", -- FLV
    ["video/x-matroska"] = "videoplayer", -- MKV
    ["video/quicktime"] = "videoplayer", -- MOV
    ["video/mp4"] = "videoplayer", -- MP4
    ["application/x-shockwave-flash"] = "videoplayer", -- SWF
    ["video/ogg"] = "videoplayer", -- Theora
    ["video/webm"] = "videoplayer", -- webm
    ["video/x-ms-wmv"] = "videoplayer", -- WMV

    -- Audio
    ["audio/x-aiff"] = "audio-tag-tool", -- AIFF
    ["audio/x-flac"] = "audio-tag-tool", -- FLAC
    ["audio/mp4"] = "audio-tag-tool", -- M4A
    ["audio/x-matroska"] = "audio-tag-tool", -- MKA
    ["audio/mpeg"] = "audio-tag-tool", -- MP3
    ["audio/vorbis"] = "audio-tag-tool", -- Ogg Vorbis
    ["audio/ogg"] = "audio-tag-tool", -- Opus
    ["audio/x-wav"] = "audio-tag-tool", -- WAV
    ["audio/webm"] = "audio-tag-tool", -- webm
    ["audio/x-ms-wma"] = "audio-tag-tool", -- WMV

    -- Archives
    ["application/x-7z-compressed"] = "archeive-manager", -- 7zip
    ["application/x-bzip2"] = "archeive-manager", -- Bzip2
    ["application/x-compress"] = "archeive-manager", -- Compress
    ["application/x-gzip"] = "archeive-manager", -- Gzip
    ["application/x-rar-compressed"] = "archeive-manager", -- Rar
    ["application/x-tar"] = "archeive-manager", -- Tar
    ["application/x-xz"] = "archeive-manager", -- xz
    ["application/zip"] = "archeive-manager", -- zip

    -- Office Documents
    ["application/vnd.ms-excel"] = "ms-excel", -- Excel (`.xls`, `.xlsx`)
    ["application/vnd.apple.keynote"] = "accessories-document-viewer", -- Keynote
    ["application/vnd.apple.numbers"] = "accessories-document-viewer", -- Numbers
    ["application/vnd.oasis.opendocument.presentation"] = "openoffice4-impress", -- OpenOffice `.odp`
    ["application/vnd.oasis.opendocument.spreadsheet"] = "openoffice4-calc", -- OpenOffice `.ods`
    ["application/vnd.oasis.opendocument.text"] = "openoffice4-base", -- OpenOffice `.odt`
    ["application/vnd.apple.pages"] = "accessories-document-viewer", -- Pages
    ["application/pdf"] = "x-pdf", -- PDF
    ["application/vnd.ms-powerpoint"] = "ms-powerpoint", -- Powerpoint (`.ppt`, `.pptx`)
    ["application/msword"] = "ms-word", -- Word (`.doc`, `.docx`)

    -- Text
    ["application/xml"] = "accessories-text-editor", -- XML
    ["text/csv"] = "accessories-text-editor", -- CSV
    ["text/html"] = "accessories-text-editor", -- HTML
    ["application/rss+xml"] = "accessories-text-editor", -- RSS
    ["text/rtf"] = "accessories-text-editor", -- RTF
    ["text/tab-separated-values"] = "accessories-text-editor", -- `.tab`
    ["application/xhtml+xml"] = "accessories-text-editor", -- XHTML
    ["text/plain"] = "accessories-text-editor", -- Unrecognized Text

    -- Scripts
    ["text/x-shellscript"] = "preferences-plugin-script", -- Bash/Bourne
    ["application/x-perl"] = "preferences-plugin-script", -- Perl
    ["application/x-httpd-php"] = "preferences-plugin-script", -- PHP
    ["application/x-python"] = "preferences-plugin-script", -- Python
    ["application/x-ruby"] = "preferences-plugin-script", -- Ruby

    -- Binaries
    ["application/x-msdownload"] = "ao-app", -- DLL
    ["application/octet-stream"] = "ao-app", -- Unrecognized Binary

    -- Folder
    ["folder"] = "folder" -- Folder
}

local function on_drag_start(button, widget)
    local offset = 50

    widget.dragging = true

    widget.pos_before_move = {
        x = widget.x,
        y = widget.y
    }
    widget.ontop = true

    capi.mousegrabber.run(function(mouse)
        if not mouse.buttons[1] then
            button:emit_signal("button::release", 42, 42, 1, {}, {})
            return false
        end

        widget.x = mouse.x - offset
        widget.y = mouse.y - offset

        return true
    end, "fleur")
end

local function on_drag_end(widget, path)
    if widget.dragging == false then
        return
    end
    widget.dragging = false

    local pos = desktop_daemon:ask_for_new_position(widget, path)
    widget.x = pos.x
    widget.y = pos.y
end

local function desktop_icon(self, pos, path, name, mimetype)
    local menu = widgets.menu {widgets.menu.button {
        icon = beautiful.icons.launcher,
        text = "Launch",
        on_release = function()
            awful.spawn("xdg-open " .. path, false)
        end
    }, widgets.menu.button {
        icon = beautiful.icons.trash,
        text = "Move to Trash",
        on_release = function()
            awful.spawn("trash-put " .. path, false)
        end
    }, widgets.menu.button {
        icon = beautiful.icons.xmark_fw,
        text = "Delete",
        on_release = function()
            local file = filesystem.file.new_for_path(path)
            file:delete()
        end
    }}

    local widget
    widget = awful.popup {
        type = "desktop",
        visible = true,
        ontop = false,
        x = pos.x,
        y = pos.y,
        bg = beautiful.colors.transparent,
        widget = wibox.widget {
            widget = widgets.button.elevated.state,
            normal_bg = beautiful.colors.transparent,
            forced_width = dpi(100),
            forced_height = dpi(100),
            on_release = function(self)
                helpers.input.tap_or_drag{
                    on_tap = function()
                        awful.spawn("xdg-open " .. path, false)
                    end,
                    on_drag = function()
                        on_drag_start(self, widget)
                    end
                }
            end,
            on_release = function()
                widget.ontop = false
                on_drag_end(widget, path)
            end,
            on_secondary_release = function()
                menu:toggle{}
            end,
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(15),
                {
                    widget = wibox.widget.imagebox,
                    forced_height = dpi(40),
                    forced_width = dpi(40),
                    halign = "center",
                    clip_shape = helpers.ui.rrect(),
                    image = helpers.icon_theme.get_icon_path(
                        mimetype_to_image_lookup_table[mimetype] or "org.gnome.gedit")
                },
                {
                    widget = widgets.text,
                    size = 15,
                    halign = "center",
                    text = name
                }
            }
        }
    }

    desktop_daemon:connect_signal(path .. "_removed", function()
        if widget ~= nil then
            widget.visible = false
            widget = nil
        end
    end)
end

local function new()
    local ret = gobject {}
    gtable.crush(ret, desktop, true)

    desktop_daemon:connect_signal("new", desktop_icon)
end

if not instance then
    instance = new()
end
return instance
