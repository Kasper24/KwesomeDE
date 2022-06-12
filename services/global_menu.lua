-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local GLib = require("lgi").GLib
local dbp = require("services.dbus_proxy")

--[[
This module first converts both the appmenu and the gtk interface into something like the following.
(ID is holding either a number (appmenu) or a string (gtk) that is needed to invoke the action)
{
    {
        label = "Item1",
        path = {"Menu1", "SubMenu", "SubSubMenu", "Item1"},
        id = 69,
        ...
    },
    {
        label = "Item2",
        path = {"Menu1", "AnotherSubMenu", "Item2"},
        id = "unity.some-action",
        ...
    },
    ...
}
--]]

local M = {
    gtk = {},
    appmenu = {},
}

M.registrar = dbp.Proxy:new {
    bus = dbp.Bus.SESSION,
    name = "com.canonical.AppMenu.Registrar",
    interface = "com.canonical.AppMenu.Registrar",
    path = "/com/canonical/AppMenu/Registrar"
}

-- Helper

local function shallow_copy(t)
    local res = {}
    for k,v in pairs(t) do
      res[k] = v
    end
    return res
end

--[[
APPMENU interface specific functions
--]]

function M.appmenu.make_flat(rawt)
    local results = {}
    local function explore(t, path)
        local result = nil
        if type(t) == "table" then
            result = {}
            for idx, sub in ipairs(t) do
                if type(sub) == "number" then
                    result["id"] = sub
                elseif type(sub) == "table" and sub["label"] then
                    table.insert(path, sub["label"])
                    local entry = {}
                    for key, value in pairs(sub) do
                        entry[key] = value
                        result[key] = value
                    end
                    entry.path = path
                    entry.id = result.id
                    table.insert(results, entry)
                else
                    local path_copy = shallow_copy(path)
                    result[idx] = explore(sub, path_copy)
                end
            end
        end
        return result
    end
    explore(rawt, {})
    return results
end

function M.appmenu.get_menu_object(window_id)
    local menuobj, err = M.registrar:GetMenuForWindow(window_id)
    if err or not menuobj then
        print(err)
        return nil
    end
    local name = menuobj[1]
    local objpath = menuobj[2]

    local mymenu = dbp.Proxy:new {
        bus = dbp.Bus.SESSION,
        name = name,
        interface = "com.canonical.dbusmenu",
        path = objpath
    }
    return mymenu
end

function M.appmenu.get_raw_menu(window_id, root, depth)
    local mymenu = M.appmenu.get_menu_object(window_id)
    if not mymenu then return nil end
    return mymenu:GetLayout(root, depth, {})
end

function M.appmenu.get_menu(window_id, root, depth)
    local res = M.appmenu.get_raw_menu(window_id, root, depth)
    return M.appmenu.make_flat(res)
end

function M.appmenu.call_event(window_id, event_id)
    local mymenu = M.appmenu.get_menu_object(window_id)
    if not mymenu then return nil end
    local data = GLib.Variant("s", "muh data") -- FIXME
    local timestamp = os.time(os.date("!*t"))
    mymenu:Event(event_id, "clicked", data, timestamp)
    return true
end

--[[
GTK inteface specfic functions
--]]

local function get_number_array(n)
    local res = {}
    for i=0,n do
        table.insert(res, i)
    end
    return res
end

local number_array = get_number_array(2048)

function M.gtk.make_flat(rawt)
    local function get_by_id(ids)
        for _, v in ipairs(rawt) do
            if v[1] == ids[1] and v[2] == ids[2] then return v[3] end
        end
        return nil
    end

    local results = {}
    local function explore(ids, label_list)
        for _, menu in ipairs(get_by_id(ids)) do
            if type(menu) ~= "table" then return end
            local new_label_list = shallow_copy(label_list)
            table.insert(new_label_list, menu["label"])
            local entry = {
                path = new_label_list,
                label = menu["label"],
                id = menu["action"], -- calling it ID analogous to appmenu
                accel = menu["accel"],
                target = menu["target"]
            }

            if menu[":section"] then
                explore(menu[":section"], label_list)
            end

            if menu[":submenu"] then
                explore(menu[":submenu"], new_label_list)
            end

            if menu["label"] then
                table.insert(results, entry)
            end
        end
    end
    explore({0, 0}, {})
    return results
end

function M.gtk.get_menu_object(gtk_bus_name, gtk_obj_path)
    return dbp.Proxy:new {
        bus = dbp.Bus.SESSION,
        name = gtk_bus_name,
        interface = "org.gtk.Menus",
        path = gtk_obj_path,
    }
end

function M.gtk.get_action_object(gtk_bus_name, gtk_obj_path)
    return dbp.Proxy:new {
        bus = dbp.Bus.SESSION,
        name = gtk_bus_name,
        interface = "org.gtk.Actions",
        path = gtk_obj_path,
    }
end

function M.gtk.get_raw_menu(gtk_bus_name, gtk_obj_path)
    local mymenu = M.gtk.get_menu_object(gtk_bus_name, gtk_obj_path)
    if not mymenu then return nil end
    return mymenu:Start(number_array)
end

function M.gtk.call_event(action, gtk_bus_name, gtk_obj_path)
    local myaction = M.gtk.get_action_object(gtk_bus_name, gtk_obj_path)
    if not myaction then return nil end
    action = action:gsub("^unity.", "")
    myaction:Activate(action, {}, {})
end

function M.gtk.get_menu(gtk_bus_name, gtk_obj_path)
    local res = M.gtk.get_raw_menu(gtk_bus_name, gtk_obj_path)
    return M.gtk.make_flat(res)
end


return M