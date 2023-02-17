local gtimer = require("gears.timer")
local capi = {
    client = client,
    root = root,
    mouse = mouse,
}

local _input = {}

function _input.send_string_to_client(client, string)
    local old_c = capi.client.focus
    capi.client.focus = client
    for i=1, #string do
        local char = string:sub(i,i)
        capi.root.fake_input("key_press", char)
        capi.root.fake_input("key_release", char)
    end
    capi.client.focus = old_c
end

function _input.tap_or_drag(args)
    local old_coords = capi.mouse.coords()
    gtimer.start_new(0.1, function()
        local new_coords = capi.mouse.coords()
        if new_coords.x ~= old_coords.x or new_coords.y ~= old_coords.y then
            args.on_drag()
        else
            args.on_tap()
        end

        return false
    end)
end

return _input
