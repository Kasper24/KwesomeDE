#!/usr/bin/lua

local lgi = require('lgi')
local Gtk = lgi.require('Gtk', '3.0')

local App = Gtk.Application({
    application_id = 'GtkFileChooserDialog'
})

function App:on_startup()
    local folder_path = arg[1]

    local Dialog  = Gtk.FileChooserDialog({
        title = 'Select a file',
        action = Gtk.FileChooserAction.SELECT_FILE
    })

    Dialog:add_button('Open', Gtk.ResponseType.OK)
    Dialog:add_button('Cancel', Gtk.ResponseType.CANCEL)
    Dialog:set_wmclass('File Picker', 'File Picker')

    if folder_path then
        Dialog:set_current_folder(folder_path)
    end

    self:add_window(Dialog)
end

function App:on_activate()
    local Res = self.active_window:run()

    if Res == Gtk.ResponseType.OK then
        local name = self.active_window:get_filename()
        print(name)
        self.active_window:destroy()
    elseif Res == Gtk.ResponseType.CANCEL then
        self.active_window:destroy()
    else
        self.active_window:destroy()
    end
end

return App:run()