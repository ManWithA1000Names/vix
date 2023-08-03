{ pkgs, name, lua }:
{ init ? ""
, set ? { }
, globals ? { }
, colorscheme ? ""
, keybinds ? { }
, enable_vim_loader ? true
}:
let
  initFile = pkgs.writeText "init.lua" ''
    ${pkgs.lib.strings.optionalString enable_vim_loader "vim.loader.enable()"}
    ${lua.toValidLuaInsert init}
    require("${name}-generated-config.globals")
    require("${name}-generated-config.set")
  '';

  setFile = pkgs.writeText "set.lua" ''
    ${liblua.toValidLuaInsert (pkgs.lib.attrsets.atrrByPath ["lua"] "" set)}
    ${liblua.toValidLuaInsert (pkgs.lib.foldlAttrs (acc: name: value: acc + "vim.opt.${name} = ${liblua.toLua value};") "" (builtins.removeAttrs set ["lua"]))}
  '';

  globalsFile = pkgs.writeText "globals.lua" ''
    ${liblua.toValidLuaInsert (if builtins.hasAttr "lua" globals then globals.lua else "")}
    ${liblua.toValidLuaInsert (pkgs.lib.foldlAttrs (acc: name: value: acc + "vim.g.${name} = ${liblua.toLua value};") "" (builtins.removeAttrs globals ["lua"]))}
  '';

  keybindindsFile = pkgs.writeText "${name}-generated-keybindinds.lua" ''
    --{{ injected lua code
    ${liblua.toValidLuaInsert (pkgs.lib.attrsets.atrrByPath ["lua"] "" keybinds)}
    --}}

    -- KEYBINDINDS
    local whichkey = require("which-key");
    --{{ normal mode
    ${pkgs.lib.strings.optionalString (builtins.hasAttr "normal" keybinds) ''whichkey.register(${liblua.toLua keybinds.normal}, {mode = "n"});''}
    --}}

    --{{ insert mode
    ${pkgs.lib.strings.optionalString (builtins.hasAttr "insert" keybinds) ''whichkey.register(${liblua.toLua keybinds.insert}, {mode = "i"});''}
    --}}

    --{{ visual/select mode
    ${pkgs.lib.strings.optionalString (builtins.hasAttr "visual" keybinds) ''whichkey.register(${liblua.toLua keybinds.visual}, {mode = "v"});''}
    --}}

    --{{ command mode
    ${pkgs.lib.strings.optionalString (builtins.hasAttr "command" keybinds) ''whichkey.register(${liblua.toLua keybinds.command}, {mode = "c"});''}
    --}}

    --{{ terminal mode
    ${pkgs.lib.strings.optionalString (builtins.hasAttr "terminal" keybinds) ''whichkey.register(${liblua.toLua keybinds.terminal}, {mode = "t"});''}
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
