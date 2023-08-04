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
    ${lua.toValidLuaInsert (pkgs.lib.attrsets.attrByPath ["lua"] "" set)}
    ${lua.toValidLuaInsert (pkgs.lib.foldlAttrs (acc: name: value: acc + "vim.opt.${name} = ${lua.toLua value};") "" (builtins.removeAttrs set ["lua"]))}
  '';

  globalsFile = pkgs.writeText "globals.lua" ''
    ${lua.toValidLuaInsert (if builtins.hasAttr "lua" globals then globals.lua else "")}
    ${lua.toValidLuaInsert (pkgs.lib.foldlAttrs (acc: name: value: acc + "vim.g.${name} = ${lua.toLua value};") "" (builtins.removeAttrs globals ["lua"]))}
  '';

  keybindindsFile = pkgs.writeText "${name}-generated-keybindinds.lua" ''
    local ok, whichkey = pcall(require,"which-key");
    if not ok then
      print([[Failed to require 'whichkey' which is needed to setup keybindinds!]], whichkey);
      return;
    end
    --{{ injected lua code
    ${lua.toValidLuaInsert (pkgs.lib.attrsets.attrByPath ["lua"] "" keybinds)}
    --}}

    -- KEYBINDINDS
    --{{ normal mode
    ${pkgs.lib.strings.optionalString (builtins.hasAttr "normal" keybinds) ''whichkey.register(${lua.toLua keybinds.normal}, {mode = "n"});''}
    --}}

    --{{ insert mode
    ${pkgs.lib.strings.optionalString (builtins.hasAttr "insert" keybinds) ''whichkey.register(${lua.toLua keybinds.insert}, {mode = "i"});''}
    --}}

    --{{ visual/select mode
    ${pkgs.lib.strings.optionalString (builtins.hasAttr "visual" keybinds) ''whichkey.register(${lua.toLua keybinds.visual}, {mode = "v"});''}
    --}}

    --{{ command mode
    ${pkgs.lib.strings.optionalString (builtins.hasAttr "command" keybinds) ''whichkey.register(${lua.toLua keybinds.command}, {mode = "c"});''}
    --}}

    --{{ terminal mode
    ${pkgs.lib.strings.optionalString (builtins.hasAttr "terminal" keybinds) ''whichkey.register(${lua.toLua keybinds.terminal}, {mode = "t"});''}
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
