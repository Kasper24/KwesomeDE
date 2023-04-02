local lgi = require('lgi')
local Gdk = lgi.require('Gdk', '3.0')
local GdkPixbuf = lgi.GdkPixbuf
local cairo = require("lgi").cairo
local gsurface = require("gears.surface")
local gcolor = require("gears.color")
local gshape = require("gears.shape")
local gtimer = require("gears.timer")
local filesystem = require("external.filesystem")
local ipairs = ipairs
local floor = math.floor
local type = type
local capi = {
    awesome = awesome
}

local _ui = {}

function _ui.rrect()
    local ui_daemon = require("daemons.system.ui")

    return function(cr, width, height)
        local radius = ui_daemon:get_border_radius()
        gshape.rounded_rect(cr, width, height, radius)
    end
end

function _ui.prrect(tl, tr, br, bl)
    local ui_daemon = require("daemons.system.ui")

    return function(cr, width, height)
        local radius = ui_daemon:get_border_radius()
        gshape.partially_rounded_rect(cr, width, height, tl, tr, br, bl, radius)
    end
end

function _ui.get_widget_geometry_in_device_space(args, widget)
    local hierarchy = nil
    if args.hierarchy then
        hierarchy = args.hierarchy
    elseif args.drawable then
        hierarchy = args.drawable._widget_hierarchy
    elseif args.wibox then
        hierarchy = args.wibox._drawable._widget_hierarchy
    end

    if hierarchy:get_widget() == widget then
        -- Get the extents of this widget in the device space
        local width, height = hierarchy:get_size()
        local matrix = hierarchy:get_matrix_to_device()
        local x, y, w, h = matrix:transform_rectangle(0, 0, width, height)
        return {
            x = x,
            y = y,
            width = w,
            height = h,
            hierarchy = hierarchy
        }
    end

    for _, child in ipairs(hierarchy:get_children()) do
        local ret = _ui.get_widget_geometry_in_device_space({hierarchy = child}, widget)
        if ret then
            return ret
        end
    end
end

function _ui.scale_image_save(image, cache_path, width, height, callback)
    local file = filesystem.file.new_for_path(cache_path)
    file:exists(function(error, exists)
        if error == nil and exists then
            callback(cache_path)
        else
            local pixbuf = nil
            if type(image) == "string" then
                pixbuf = GdkPixbuf.Pixbuf.new_from_file(image)
            else
                -- pixbuf = Gdk.pixbuf_get_from_surface(image, 0, 0, image:get_width(), image:get_height())
            end

            if pixbuf then
                pixbuf = pixbuf:scale_simple(width, height, GdkPixbuf.InterpType.BILINEAR)
                pixbuf:savev(cache_path, "png", {})
                callback(cache_path)
            end
        end
    end)
end

function _ui.scale_image(image, width, height)
    local pixbuf = nil
    if type(image) == "string" then
        pixbuf = GdkPixbuf.Pixbuf.new_from_file(image)
    else
        -- pixbuf = Gdk.pixbuf_get_from_surface(image, 0, 0, image:get_width(), image:get_height())
    end

    if pixbuf then
        local scaled_pixbuf = pixbuf:scale_simple(width, height, GdkPixbuf.InterpType.BILINEAR)
        return capi.awesome.pixbuf_to_surface(scaled_pixbuf._native, image)
    end
end

function _ui.crop_surface(surface, ratio)
    local old_w, old_h = gsurface.get_size(surface)
    local old_ratio = old_w/old_h

    if old_ratio == ratio then return surface end

    local new_h = old_h
    local new_w = old_w
    local offset_h, offset_w = 0, 0
    if (old_ratio < ratio) then
        new_h = old_w * (1/ratio)
        offset_h = (old_h - new_h)/2
    else
        new_w = old_h * ratio
        offset_w = (old_w - new_w)/2
    end

    local out_surface = cairo.ImageSurface(cairo.Format.ARGB32, new_w, new_h)
    local cr = cairo.Context(out_surface)
    cr:set_source_surface(surface, -offset_w, -offset_h)
    cr.operator = cairo.Operator.SOURCE
    cr:paint()

    return out_surface
end

function _ui.add_gradient_to_surface(image, colors)
    local in_surface = gsurface.load_uncached(image)
    local surface = _ui.crop_surface(in_surface, 2)

    local cr = cairo.Context(surface)
    local w, h = gsurface.get_size(surface)
    cr:rectangle(0, 0, w, h)

    local pat_h = cairo.Pattern.create_linear(0, 0, w, 0)

    for _, color in ipairs(colors) do
        pat_h:add_color_stop_rgba(color.stop, gcolor.parse_color(color.color))
    end
    cr:set_source(pat_h)
    cr:fill()

    return surface
end

function _ui.should_show_notification()
    if _ui.show_notifications == nil then
        _ui.show_notifications = false
        gtimer.start_new(5, function()
            _ui.show_notifications = true
            return false
        end)
    end

    return _ui.show_notifications
end

return _ui
