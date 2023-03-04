local lgi = require('lgi')
local Gdk = lgi.require('Gdk', '3.0')
local GdkPixbuf = lgi.GdkPixbuf
local cairo = require("lgi").cairo
local gsurface = require("gears.surface")
local gcolor = require("gears.color")
local gshape = require("gears.shape")
local gmatrix = require("gears.matrix")
local beautiful = require("beautiful")
local ipairs = ipairs
local floor = math.floor
local type = type
local capi = {
    awesome = awesome
}

local _ui = {}

function _ui.rrect()
    return function(cr, width, height)
        local radius = beautiful.border_radius
        gshape.rounded_rect(cr, width, height, radius)
    end
end

function _ui.prrect(tl, tr, br, bl)
    return function(cr, width, height)
        local radius = beautiful.border_radius
        gshape.partially_rounded_rect(cr, width, height, tl, tr, br, bl, radius)
    end
end

local function _get_widget_geometry(_hierarchy, widget)
    local width, height = _hierarchy:get_size()
    if _hierarchy:get_widget() == widget then
        -- Get the extents of this widget in the device space
        local x, y, w, h = gmatrix.transform_rectangle(_hierarchy:get_matrix_to_device(), 0, 0, width, height)
        return {
            x = x,
            y = y,
            width = w,
            height = h,
            hierarchy = _hierarchy
        }
    end

    for _, child in ipairs(_hierarchy:get_children()) do
        local ret = _get_widget_geometry(child, widget)
        if ret then
            return ret
        end
    end
end

function _ui.get_widget_geometry(wibox, widget)
    return _get_widget_geometry(wibox._drawable._widget_hierarchy, widget)
end

function _ui.adjust_image_res(image, width, height)
    local pixbuf = nil
    if type(image) == "string" then
        pixbuf = GdkPixbuf.Pixbuf.new_from_file(image)
    else
        pixbuf = Gdk.pixbuf_get_from_surface(image, 0, 0, image:get_width(), image:get_height())
    end

    -- Scale down the image
    local scaled_pixbuf = pixbuf:scale_simple(width, height, GdkPixbuf.InterpType.BILINEAR)

    return capi.awesome.pixbuf_to_surface(scaled_pixbuf._native, image)
end

function _ui.adjust_image_res_by_ratio(image, ratio)
    local pixbuf = nil
    if type(image) == "string" then
        pixbuf = GdkPixbuf.Pixbuf.new_from_file(image)
    else
        pixbuf = Gdk.pixbuf_get_from_surface(image, 0, 0, image:get_width(), image:get_height())
    end

    -- Get the original image dimensions
    local width = pixbuf:get_width()
    local height = pixbuf:get_height()

    -- Calculate the new dimensions to scale the image down to
    local new_width = floor(width / ratio)
    local new_height = floor(height / ratio)

    -- Scale down the image
    local scaled_pixbuf = pixbuf:scale_simple(new_width, new_height, GdkPixbuf.InterpType.BILINEAR)

    return capi.awesome.pixbuf_to_surface(scaled_pixbuf._native, image)
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

return _ui
