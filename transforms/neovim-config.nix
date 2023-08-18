{ pkgs, name, lua, nilm }:
{ init ? ""
, set ? { }
, globals ? { }
, colorscheme ? ""
, keybinds ? { }
, enable_vim_loader ? true
}:
let
  inherit (nilm) Dict;

  initFile = pkgs.writeText "init.lua" ''
    ${if enable_vim_loader then "vim.loader.enable()" else "vim.loader.disable()"}
    ${lua.toValidLuaInsert init}
    ${nilm.Nix.orDefault (colorscheme != "") "vim.cmd([[colorscheme ${colorscheme}]])"}
    require("${name}-generated-config.globals")
    require("${name}-generated-config.set")
  '';

  setFile = pkgs.writeText "set.lua" ''
    ${lua.toValidLuaInsert (Dict.getOr "lua" "" set)}
    ${lua.toValidLuaInsert (Dict.foldl ( name: value: acc: acc + "vim.opt.${name} = ${lua.toLua value};") "" (Dict.remove "lua" set))}
  '';

  globalsFile = pkgs.writeText "globals.lua" ''
    ${lua.toValidLuaInsert (Dict.getOr "lua" "" globals)}
    ${lua.toValidLuaInsert (Dict.foldl (name: value: acc: acc + "vim.g.${name} = ${lua.toLua value};") "" (Dict.remove "lua" globals))}
  '';

  keybindindsFile = pkgs.writeText "${name}-generated-keybindinds.lua" ''
    local ok, whichkey = pcall(require,"which-key");
    if not ok then
      print([[Failed to require 'whichkey' which is needed to setup keybindinds!]], whichkey);
      return;
    end
    --{{ injected lua code
    ${lua.toValidLuaInsert (Dict.getOr "lua" "" keybinds)}
    --}}

    -- KEYBINDINDS
    --{{ normal mode
    ${nilm.Nix.orDefault (Dict.member "normal" keybinds) ''whichkey.register(${lua.toLua keybinds.normal}, {mode = "n"});''}
    --}}

    --{{ insert mode
    ${nilm.Nix.orDefault (Dict.member "insert" keybinds) ''whichkey.register(${lua.toLua keybinds.insert}, {mode = "i"});''}
    --}}

    --{{ visual/select mode
    ${nilm.Nix.orDefault (Dict.member "visual" keybinds) ''whichkey.register(${lua.toLua keybinds.visual}, {mode = "v"});''}
    --}}

    --{{ command mode
    ${nilm.Nix.orDefault (Dict.member "command" keybinds) ''whichkey.register(${lua.toLua keybinds.command}, {mode = "c"});''}
    --}}

    --{{ terminal mode
    ${nilm.Nix.orDefault (Dict.member "terminal" keybinds) ''whichkey.register(${lua.toLua keybinds.terminal}, {mode = "t"});''}
    --}}
  '';
in
''
  cp ${initFile} $out/${name}/init.lua
  mkdir -p $out/${name}/lua/${name}-generated-config/
  cp ${setFile} $out/${name}/lua/${name}-generated-config/set.lua
  cp ${globalsFile} $out/${name}/lua/${name}-generated-config/globals.lua
  cp ${keybindindsFile} $out/${name}/after/plugin/keybinds.lua
''
