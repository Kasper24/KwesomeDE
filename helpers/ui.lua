local lgi = require('lgi')
local GdkPixbuf = lgi.GdkPixbuf
local gsurface = require("gears.surface")
local gshape = require("gears.shape")
local gmatrix = require("gears.matrix")
local beautiful = require("beautiful")
local ipairs = ipairs
local floor = math.floor
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

function _ui.adjust_image_res(path, height, width)
    -- Load the original image file
    local pixbuf = GdkPixbuf.Pixbuf.new_from_file(path)

    -- Scale down the image
    local scaled_pixbuf = pixbuf:scale_simple(width, height, GdkPixbuf.InterpType.BILINEAR)

    return capi.awesome.pixbuf_to_surface(scaled_pixbuf._native, path)
end

function _ui.adjust_image_res_by_ratio(path, ratio)
    -- Load the original image file
    local pixbuf = GdkPixbuf.Pixbuf.new_from_file(path)

    -- Get the original image dimensions
    local width = pixbuf:get_width()
    local height = pixbuf:get_height()

    -- Calculate the new dimensions to scale the image down to
    local new_width = floor(width / ratio)
    local new_height = floor(height / ratio)

    -- Scale down the image
    local scaled_pixbuf = pixbuf:scale_simple(new_width, new_height, GdkPixbuf.InterpType.BILINEAR)

    return capi.awesome.pixbuf_to_surface(scaled_pixbuf._native, path)
end

return _ui
