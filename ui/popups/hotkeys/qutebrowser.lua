---------------------------------------------------------------------------
--- Qutebrowser hotkeys for awful.hotkeys_widget
--
-- @author Simon Désaulniers sim.desaulniers@gmail.com
-- @copyright 2017 Simon Désaulniers
-- @submodule awful.hotkeys_popup
---------------------------------------------------------------------------

local hotkeys_popup = require("ui.popups.hotkeys")
local pairs = pairs

local qutebrowser_rule = {class="qutebrowser"}
for group_name, group_data in pairs({
    ["Qutebrowser: common"]             = { rule = qutebrowser_rule },
    ["Qutebrowser: search"]             = { rule = qutebrowser_rule },
    ["Qutebrowser: tabs"]               = { rule = qutebrowser_rule },
    ["Qutebrowser: copy/paste"]         = { rule = qutebrowser_rule },
    ["Qutebrowser: navigation"]         = { rule = qutebrowser_rule },
    ["Qutebrowser: scrolling"]          = { rule = qutebrowser_rule },
    ["Qutebrowser: in prompt mode"]     = { rule = qutebrowser_rule },
    ["Qutebrowser: opening"]            = { rule = qutebrowser_rule },
    ["Qutebrowser: back/forward"]       = { rule = qutebrowser_rule },
    ["Qutebrowser: hints"]              = { rule = qutebrowser_rule },
    ["Qutebrowser: misc. commands"]     = { rule = qutebrowser_rule },
    ["Qutebrowser: modifier commands"]  = { rule = qutebrowser_rule },
    ["Qutebrowser: in insert mode"]     = { rule = qutebrowser_rule },
    ["Qutebrowser: in command mode"]    = { rule = qutebrowser_rule },
}) do
    hotkeys_popup.add_group_rules(group_name, group_data)
end

local qutebrowser_keys = {
    ["Qutebrowser: common"] = {{
        modifiers = {},
        keys = {
            r = "reload tab",
            ["+"] = "zoom in",
            ["-"] = "zoom out",
            [":"] = "command line",
        }
    }},

    ["Qutebrowser: search"] = {{
        modifiers = {},
        keys = {
            ["/"] = "search in page",
            N = "forward search in page",
            n = "back search in page",
        }
    }},

    ["Qutebrowser: bookmarks"] = {{
        modifiers = {},
        keys = {
            M = "save bookmark",
            m = "save quickmark",
            B = "load quickmark in new tab",
            b = "load quickmark",
        }
    }},

    ["Qutebrowser: tabs"] = {{
        modifiers = {},
        keys = {
            k = "previous tab",
            j = "next tab",
            T = "select tab",
            gt = "switch tabs by name",
            gm = "move tab to index",
            gl = "move tab to the left",
            gr = "move tab to the right",
            gC = "clone tab",
            d = "close tab",
            u = "undo close tab",
        }
    },{
        modifiers = {"Alt"},
        keys = {
            num = "select tab",
            m = "mute tab",

        }
    },{
        modifiers = {"Control"},
        keys = {
            tab = "select prev. tab",
            p =  "pin tab",
        }
    }},

    ["Qutebrowser: copy/paste"] = {{
        modifiers = {},
        keys = {
            yy = "copy/yank URL",
            yY = "copy URL to selection",
            yt = "copy title to clipboard",
            yT = "copy title to selection",
            pp = "open URL from clipboard",
            pP = "open URL from slection",
            Pp = "like pp, in new tab",
            PP = "like pP, in new tab",
            wp = "like pp, in new window",
            wP = "like pP, in new window"
        }
    }},

    ["Qutebrowser: navigation"] = {{
        modifiers = {},
        keys = {
            ["[["]  = "click previous link on page",
            ["]]"]  = "click next link on page",
            ["{{"]  = "like [[, in new tab",
            ["}}"]  = "like ]], in new tab",
        }
    }, {
        modifiers = {"Control"},
        keys = {
            a = "increment no. in URL",
            x = "decrement no. in URL"
        }
    }},

    ["Qutebrowser: scrolling"] = {{
        modifiers = {"Control"},
        keys = {
            h = "left",
            j = "down",
            k = "up",
            l = "right",
            f = "page down",
            b = "page up",
            d = "half page down",
            u = "half page up",
        }
    },{
        modifiers = {},
        keys = {
            gg = "scroll to top",
            G = "scroll to bottom",
        }
    }},

    ["Qutebrowser: in prompt mode"] = {{
        modifiers = {},
        keys = {
            enter = "accept prompt",
            y = "answer yes to prompt",
            n = "answer no to prompt"
        }
    }},

    ["Qutebrowser: opening"] = {{
        modifiers = {},
        keys = {
            o = "go to url",
            O = "like o, in new tab",
            go = "edit and open current URL",
            gO = "like go, in new tab",
            xo = "open in background tab",
            xO = "like go, in bg. tab",
            wo = "open in new window",
        }
    }},

    ["Qutebrowser: back/forward"] = {{
        modifiers = {},
        keys = {
            H = "back in history",
            L = "forward in history",
            th = "back (in new tab)",
            wh = "back (in new window)",
            tl = "forward (in new tab)",
            wl = "forward (in new window)"
        }
    }},

    ["Qutebrowser: hints"] = {{
        modifiers = {},
        keys = {
            f = "hints",
            F = "hints new tab",
            [";b"] = "open hint in background tab",
            [";f"] = "open hint in foreground tab",
            [";h"] = "hover over hint (mouse-over)",
            [";i"] = "hint images",
            [";I"] = "hint images in new tab",
            [";o"] = "put hinted URL in cmd. line",
            [";O"] = "like ;o, in new tab",
            [";y"] = "yank hinted URL to clipboard",
            [";Y"] = "yank hinted URL to selection",
            [";r"] = "rapid hinting",
            [";R"] = "like ;r, in new window",
            [";d"] = "download hinted URL"
        }
    }},

    ["Qutebrowser: misc. commands"] = {{
        modifiers = {},
        keys = {
            gf = "view page source",
            gu = "navigate up in URL",
            gU = "like gu, in new tab",
            sf = "save config",
            ss = "set setting",
            sl = "set temp. setting",
            sk = "bind key",
            wi = "open web inspector",
            gd = "download page",
            ad = "cancel download",
            co = "close other tabs",
            cd = "clear downloads"
        }
    }},

    ["Qutebrowser: modifier commands"] = {{
        modifiers = {"Alt"},
        keys = {
            num = "select tab",
        }
    }, {
        modifiers = {"Control"},
        keys = {
            v = "passthrough mode",
            q = "quit",
            h = "home",
            s = "stop loading",
        }
    }, {
        modifiers = {"Control", "Alt"},
        keys = {
            p = "print",
        }
    }},

    ["Qutebrowser: in insert mode"] = {{
        modifiers = {"Control"},
        keys = {
            e = "open editor"
        }
    }},

    ["Qutebrowser: in command mode"] = {{
        modifiers = {"Control"},
        keys = {
            p = "prev. history item",
            n = "next history item"
        }
    }},
}

hotkeys_popup.add_hotkeys(qutebrowser_keys)