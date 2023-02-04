-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------
local hotkeys_popup = require("ui.popups.hotkeys")
local pairs = pairs

local ranger_keys = {
    ["Ranger: file"] = {{
        modifiers = {},
        keys = {
            ["dd"] = "cut",
            ["ud"] = "uncut",
            ["da"] = "cut mode=add",
            ["dr"] = "cut mode=remove",
            ["dt"] = "cut mode=toggle",

            ["yy"] = "copy",
            ["uy"] = "uncut",
            ["ya"] = "copy mode=add",
            ["yr"] = "copy mode=remove",
            ["yt"] = "copy mode=toggle",
            ["yp"] = "yank path",
            ["yd"] = "yank dir",
            ["yn"] = "yank name",
            ["y."] = "yank name_without_extension",

            ["pp"] = "paste",
            ["po"] = "paste overwrite=True",
            ["pP"] = "paste append=True",
            ["pO"] = "paste overwrite=True append=True",
            ["pl"] = "paste_symlink relative=False",
            ["pL"] = "paste_symlink relative=True",
            ["phl"] = "paste_hardlink",
            ["pht"] = "paste_hardlinked_subtree",
            ["pd"] = "console paste dest=",
            ["p` <any>"] = "paste dest=%any_path",
            ["p' <any>"] = "paste dest=%any_path",

            ["dD"] = "console delete",
            ["dT"] = "shell -s trash-put %s",

            ["+"] = "chmod menu",

            ["dgg"] = "eval fm.cut(dirarg=dict(to=0), narg=quantifier)",
            ["dG"] = "eval fm.cut(dirarg=dict(to=-1), narg=quantifier)",
            ["dj"] = "eval fm.cut(dirarg=dict(down=1), narg=quantifier)",
            ["dk"] = "eval fm.cut(dirarg=dict(up=1), narg=quantifier)",
            ["ygg"] = "eval fm.copy(dirarg=dict(to=0), narg=quantifier)",
            ["yG"] = "eval fm.copy(dirarg=dict(to=-1), narg=quantifier)",
            ["yj"] = "eval fm.copy(dirarg=dict(down=1), narg=quantifier)",
            ["yk"] = "eval fm.copy(dirarg=dict(up=1), narg=quantifier)",

            ["cw"] = "console rename%space",
            ["a"] = "rename_append",
            ["A"] = "eval fm.open_console('rename ' + fm.thisfile.relative_path.replace('%', '%%'))",
            ["I"] = "eval fm.open_console('rename ' + fm.thisfile.relative_path.replace('%', '%%'), position=7)",

            ["dc"] = "get_cumulative_size"
        }
    }},
    ["Ranger: movement"] = {{
        modifiers = {},
        keys = {
            ["Up"] = "move up=1",
            ["Down"] = "move down=1",
            ["Left"] = "move left=1",
            ["Right"] = "move right=1",
            ["Home"] = "move to=0",
            ["End"] = "move to=-1",
            ["Page Down"] = "move down=1pages=True",
            ["Page Up"] = "move up=1 pages=True",
            -- map <CR>  move right=1"
            ["Delete"] = "console delete",
            ["Insert"] = "console touch%space",
            k = "up",
            j = "down",
            h = "parent directory",
            l = "subdirectory",
            ["gg"] = "go to top of list",
            G = "go to bottom of list",
            J = "half page down",
            K = "half page up",
            H = "History Back",
            L = "History Forward",
            ["]"] = "move_parent 1",
            ["["] = "move_parent -1",
            ["}"] = "traverse",
            ["{"] = "traverse_backwards",
            [")"] = "jump_non"
        }
    }},
    ["Ranger: search"] = {{
        modifiers = {},
        keys = {
            ["/"] = "console search%space",
            n = "search_next",
            N = "search_next forward=False",
            ["ct"] = "search_next order=tag",
            ["cs"] = "search_next order=size",
            ["ci"] = "search_next order=mimetype",
            ["cc"] = "search_next order=ctime",
            ["cm"] = "search_next order=mtime",
            ["ca"] = "search_next order=atime"
        }
    }},
    ["Ranger: sort"] = {{
        modifiers = {},
        keys = {
            ["or"] = "set sort_reverse!",
            ["oz"] = "set sort=random",
            ["os"] = "chain set sort=size;      set sort_reverse=False",
            ["ob"] = "chain set sort=basename;  set sort_reverse=False",
            ["on"] = "chain set sort=natural;   set sort_reverse=False",
            ["om"] = "chain set sort=mtime;     set sort_reverse=False",
            ["oc"] = "chain set sort=ctime;     set sort_reverse=False",
            ["oa"] = "chain set sort=atime;     set sort_reverse=False",
            ["ot"] = "chain set sort=type;      set sort_reverse=False",
            ["oe"] = "chain set sort=extension; set sort_reverse=False",
            ["oS"] = "chain set sort=size;      set sort_reverse=True",
            ["oB"] = "chain set sort=basename;  set sort_reverse=True",
            ["oN"] = "chain set sort=natural;   set sort_reverse=True",
            ["oM"] = "chain set sort=mtime;     set sort_reverse=True",
            ["oC"] = "chain set sort=ctime;     set sort_reverse=True",
            ["oA"] = "chain set sort=atime;     set sort_reverse=True",
            ["oT"] = "chain set sort=type;      set sort_reverse=True",
            ["oE"] = "chain set sort=extension; set sort_reverse=True"
        }
    }},
    ["Ranger: linemode"] = {{
        modifiers = {},
        keys = {
            ["Mf"] = "linemode filename",
            ["Mi"] = "linemode fileinfo",
            ["Mm"] = "linemode mtime",
            ["Mh"] = "linemode humanreadablemtime",
            ["Mp"] = "linemode permissions",
            ["Ms"] = "linemode sizemtime",
            ["MH"] = "linemode sizehumanreadablemtime",
            ["Mt"] = "linemode metatitle"
        }
    }},
    ["Ranger: filterstack"] = {{
        modifiers = {},
        keys = {
            [".d"] = "filter_stack add type d",
            [".f"] = "filter_stack add type f",
            [".l"] = "filter_stack add type l",
            [".m"] = "console filter_stack add mime%space",
            [".n"] = "console filter_stack add name%space",
            [".#"] = "console filter_stack add hash%space",
            [".\""] = "filter_stack add duplicate",
            [".'"] = "filter_stack add unique",
            [".|"] = "filter_stack add or",
            [".&"] = "filter_stack add and",
            [".!"] = "filter_stack add not",
            [".r"] = "filter_stack rotate",
            [".c"] = "filter_stack clear",
            [".*"] = "filter_stack decompose",
            [".p"] = "filter_stack pop",
            [".."] = "filter_stack show"
        }
    }},
    ["Ranger: tabs"] = {{
        modifiers = {"Ctrl"},
        keys = {
            n = "tab_new",
            w = "tab_close"
        }
    }, {
        modifiers = {"Alt"},
        keys = {
            ["Right"] = "tab_move 1",
            ["Left"] = "tab_move -1",
            ["1"] = "tab_open 1",
            ["2"] = "tab_open 2",
            ["3"] = "tab_open 3",
            ["4"] = "tab_open 4",
            ["5"] = "tab_open 5",
            ["6"] = "tab_open 6",
            ["7"] = "tab_open 7",
            ["8"] = "tab_open 8",
            ["9"] = "tab_open 9",
            r = "tab_shift 1",
            l = "tab_shift -1"
        }
    }, {
        modifiers = {"Shift"},
        keys = {
            ["Tab"] = "tab_move -1"
        }
    }, {
        modifiers = {},
        keys = {
            ["Tab"] = "tab_move 1",
            ["gt"] = "tab_move 1",
            -- map gT        tab_move -1
            ["gn"] = "tab_new",
            -- map gc        tab_close
            ["uq"] = "tab_restore"
        }
    }},
    ["Ranger: bookmarks"] = {{
        modifiers = {},
        keys = {
            ["`<any>"] = "enter_bookmark %any",
            ["'<any>"] = "enter_bookmark %any",
            ["m<any>"] = "set_bookmark %any",
            ["um<any>"] = "unset_bookmark %any",
            ["m<bg>"] = "draw_bookmarks"
        }
    }},
    ["Ranger: tags"] = {{
        modifiers = {},
        keys = {
            ["t"] = "tag_toggle",
            ["ut"] = "tag_remove",
            ["\"<any>"] = "tag_toggle tag=%any",
            ["<Space>"] = "mark_files toggle=True",
            ["v"] = "mark_files all=True toggle=True",
            ["uv"] = "mark_files all=True val=False",
            ["V"] = "toggle_visual_mode",
            ["uV"] = "toggle_visual_mode reverse=True"
        }
    }},
    ["Ranger: settings"] = {{
        modifiers = {"Ctrl"},
        keys = {
            h = "Toggle hidden"
        }
    }, {
        modifiers = {},
        keys = {
            ["~"] = "Switch the view",
            ["zc"] = "collapse_preview!",
            ["zd"] = "sort_directories_first!",
            ["zh"] = "show_hidden!",
            ["zI"] = "flushinput!",
            ["zi"] = "preview_images!",
            ["zm"] = "mouse_enabled!",
            ["zp"] = "preview_files!",
            ["zP"] = "preview_directories!",
            ["zs"] = "sort_case_insensitive!",
            ["zu"] = "autoupdate_cumulative_size!",
            ["zv"] = "use_preview_script!",
            ["zf"] = "console filter%space"
        }
    }}
}

local ranger_rule = {
    class = {"ranger", "ranger"}
}
for group_name, group_data in pairs({
    ["Ranger: file"] = {
        rule_any = ranger_rule
    },
    ["Ranger: movement"] = {
        rule_any = ranger_rule
    },
    ["Ranger: search"] = {
        rule_any = ranger_rule
    },
    ["Ranger: sort"] = {
        rule_any = ranger_rule
    },
    ["Ranger: linemode"] = {
        rule_any = ranger_rule
    },
    ["Ranger: filterstack"] = {
        rule_any = ranger_rule
    },
    ["Ranger: tabs"] = {
        rule_any = ranger_rule
    },
    ["Ranger: bookmarks"] = {
        rule_any = ranger_rule
    },
    ["Ranger: tags"] = {
        rule_any = ranger_rule
    },
    ["Ranger: settings"] = {
        rule_any = ranger_rule
    }
}) do
    hotkeys_popup.add_group_rules(group_name, group_data)
end

hotkeys_popup.add_hotkeys(ranger_keys)
