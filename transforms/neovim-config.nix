{ pkgs, name, lua, nilm, which-key-in-plugins }:
{ init ? "", set ? { }, globals ? { }, colorscheme ? "", keybinds ? { }
, enable_vim_loader ? true, ftkeybinds ? [ ] }:
let
  inherit (nilm) Dict;

  ftkeybinds_grouped = nilm.List.groupBy (attrs: attrs.filetypes) ftkeybinds;

  shouldRequireWhichKey = keybinds:
    nilm.List.foldl
    (m: acc: acc || Dict.getOr-rec "${m}.useWhichKey" false keybinds)
    false [ "normal" "insert" "visual" "command" "terminal" ];

  mode_to_mode = mode:
    if mode == "normal" then
      "n"
    else if mode == "insert" then
      "i"
    else if mode == "visual" then
      "v"
    else if mode == "command" then
      "c"
    else if mode == "terminal" then
      "t"
    else
      builtins.abort "Unrecognized keybind mode: ${mode}";

  produceKeybindings = { mode, keybinds, buffer ? null }:
    if !(Dict.member mode keybinds) then
      ""
    else if Dict.getOr-rec "${mode}.useWhichKey" false keybinds then
      ''
        whichkey.register(${
          lua.toLua (Dict.remove "useWhichKey" keybinds.${mode})
        }, {mode = "${mode_to_mode mode}", ${
          if buffer != null then "buffer = ${lua.toLua buffer}," else ""
        });''
    else
      lua.toKeybindings (mode_to_mode mode) buffer keybinds.${mode};

  # files

  init-file = pkgs.writeText "init.lua" ''
    -- GENERATED BY 'vix' DO NOT EDIT!
    -- If you want to change any thing in this file
    -- then modify your flake.nix and run 'nix build'!

    -- ENABLE CACHING
    ${if enable_vim_loader then
      "vim.loader.enable()"
    else
      "vim.loader.disable()"}

    -- RESET ENVIROMENT
    vim.fn.stdpath = (function()
      local og_stdpath = vim.fn.stdpath;
      local config_dir = vim.fn.resolve(vim.env.XDG_CONFIG_HOME .. "/" .. vim.env.NVIM_APPNAME);
      return function(category)
        if category == "config" then return config_dir end 
        return og_stdpath(category)
      end
    end)();
    vim.env.XDG_CONFIG_HOME = vim.env.OG_XDG_CONFIG_HOME;
    vim.env.OG_XDG_CONFIG_HOME = nil;

    -- INJECTED INIT
    ${if nilm.String.isEmpty init then
      "-- there was not custom init code."
    else
      lua.toValidLuaInsert init}

    ${nilm.Nix.orDefault (colorscheme != "") ''
      -- COLORSCHEME
      vim.cmd([[colorscheme ${colorscheme}]])''}

    -- CALL GENREATED OPTIONS && GLOBALS
    require("${name}-generated-config.globals")
    require("${name}-generated-config.set")
  '';

  set-file = pkgs.writeText "set.lua" ''
    ${lua.toValidLuaInsert (Dict.getOr "lua" "" set)}
    ${lua.toValidLuaInsert (Dict.foldl
      (name: value: acc: acc + "vim.opt.${name} = ${lua.toLua value};") ""
      (Dict.remove "lua" set))}
  '';

  globals-file = pkgs.writeText "globals.lua" ''
    ${lua.toValidLuaInsert (Dict.getOr "lua" "" globals)}
    ${lua.toValidLuaInsert
    (Dict.foldl (name: value: acc: acc + "vim.g.${name} = ${lua.toLua value};")
      "" (Dict.remove "lua" globals))}
  '';

  keybindinds-file = pkgs.writeText "${name}-generated-keybindinds.lua" ''
    ${if shouldRequireWhichKey keybinds && which-key-in-plugins then
      ''local whichkey = require("which-key");''
    else if shouldRequireWhichKey keybinds && !which-key-in-plugins then
      builtins.abort
      "The useWhichKey option was set, but which-key is not present in you plugins!"
    else
      ""}

    --{{ INJECTED LUA CODE
    ${lua.toValidLuaInsert (Dict.getOr "lua" "" keybinds)}
    --}}

    -- KEYBINDINDS
    --{{ normal mode
    ${produceKeybindings {
      mode = "normal";
      inherit keybinds;
    }}
    --}}

    --{{ insert mode
    ${produceKeybindings {
      mode = "insert";
      inherit keybinds;
    }}
    --}}

    --{{ visual/select mode
    ${produceKeybindings {
      mode = "visual";
      inherit keybinds;
    }}
    --}}

    --{{ command mode
    ${produceKeybindings {
      mode = "command";
      inherit keybinds;
    }}
    --}}

    --{{ terminal mode
    ${produceKeybindings {
      mode = "terminal";
      inherit keybinds;
    }}
    --}}
  '';

  ftkeybinds-file = nilm.Basics.pipe ftkeybinds_grouped [
    (nilm.List.map (list:
      let item0 = nilm.List.get 0 list;
      in ''
        vim.api.nvim_create_autocmd([[FileType]], {
          pattern = ${lua.toLua item0.filetypes},
          callback = function(event)
          ${
            nilm.String.join "\n" (nilm.List.map (keybinds: ''
              (function()
                -- INJECTED LUA CODE 
                ${lua.toValidLuaInsert (Dict.getOr "lua" "" keybinds)}

                -- KEYBINDINDS
                --{{ normal mode
                ${
                  produceKeybindings {
                    mode = "normal";
                    inherit keybinds;
                    buffer = _: "event.buf";
                  }
                }
                --}}

                --{{ insert mode
                ${
                  produceKeybindings {
                    mode = "insert";
                    inherit keybinds;
                    buffer = _: "event.buf";
                  }
                }
                --}}

                --{{ visual mode
                ${
                  produceKeybindings {
                    mode = "visual";
                    inherit keybinds;
                    buffer = _: "event.buf";
                  }
                }
                --}}

                --{{ command mode
                ${
                  produceKeybindings {
                    mode = "command";
                    inherit keybinds;
                    buffer = _: "event.buf";
                  }
                }
                --}}

                --{{ terminal mode
                ${
                  produceKeybindings {
                    mode = "terminal";
                    inherit keybinds;
                    buffer = _: "event.buf";
                  }
                }
                --}}
              end)();'') list)
          }
          end,
        });
      ''))
    (nilm.String.join "\n")
    (if nilm.List.any shouldRequireWhichKey ftkeybinds then
      nilm.Basics.add
      (lua.toValidLuaInsert ''local whichkey = require("which-key")'')
    else
      nilm.Basics.identity)
    (pkgs.writeText "${name}-generated-ft-keybinds.lua")
  ];

in ''
  cp ${init-file} $out/${name}/init.lua
  mkdir -p $out/${name}/lua/${name}-generated-config/
  cp ${set-file} $out/${name}/lua/${name}-generated-config/set.lua
  cp ${globals-file} $out/${name}/lua/${name}-generated-config/globals.lua
  cp ${keybindinds-file} $out/${name}/after/plugin/;
  cp ${ftkeybinds-file} $out/${name}/after/plugin/;
''
