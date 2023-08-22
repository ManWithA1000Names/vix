{ pkgs, name, lua, nilm, which-key-in-plugins }:
{ init ? "", set ? { }, globals ? { }, colorscheme ? "", keybinds ? { }
, enable_vim_loader ? true }:
let
  inherit (nilm) Dict;

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

  produceKeybindings = mode:
    if !(Dict.member-raw mode keybinds) then
      ""
    else if Dict.getOr "${mode}.useWhichKey" false keybinds
    && which-key-in-plugins then
      ''
        whichkey.register(${
          lua.toLua (Dict.remove "useWhichKey" keybinds.${mode})
        }, {mode = "${mode_to_mode mode}"});''
    else
      lua.toKeybindings (mode_to_mode mode) keybinds.${mode};

  initFile = pkgs.writeText "init.lua" ''
    -- GENERATED BY 'vix' DO NOT EDIT!
    -- If you want to change any thing in this file then modify your  
    -- flake.nix and run 'nix build'!

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
    ${lua.toValidLuaInsert init}
    ${nilm.Nix.orDefault (colorscheme != "")
    "vim.cmd([[colorscheme ${colorscheme}]])"}

    -- CALL GENREATED OPTIONS && GLOBALS
    require("${name}-generated-config.globals")
    require("${name}-generated-config.set")
  '';

  setFile = pkgs.writeText "set.lua" ''
    ${lua.toValidLuaInsert (Dict.getOr "lua" "" set)}
    ${lua.toValidLuaInsert (Dict.foldl
      (name: value: acc: acc + "vim.opt.${name} = ${lua.toLua value};") ""
      (Dict.remove "lua" set))}
  '';

  globalsFile = pkgs.writeText "globals.lua" ''
    ${lua.toValidLuaInsert (Dict.getOr "lua" "" globals)}
    ${lua.toValidLuaInsert
    (Dict.foldl (name: value: acc: acc + "vim.g.${name} = ${lua.toLua value};")
      "" (Dict.remove "lua" globals))}
  '';

  shouldRequireWhichKey = nilm.List.foldl
    (m: acc: acc || Dict.getOr "${m}.useWhichKey" false keybinds)
    false [ "normal" "insert" "visual" "command" "terminal" ];

  keybindindsFile = pkgs.writeText "${name}-generated-keybindinds.lua" ''
    ${if shouldRequireWhichKey && which-key-in-plugins then
      ''local whichkey = require("which-key");''
    else if shouldRequireWhichKey && !which-key-in-plugins then ''
      print([[You specified which-key do be used for some of your key bindings, but you you did not inlcude it in your plugins!]])
      print([[Falling back to registering keybinds the default way.]])'' else
      ""}

    --{{ injected lua code
    ${lua.toValidLuaInsert (Dict.getOr "lua" "" keybinds)}
    --}}

    -- KEYBINDINDS
    --{{ normal mode
    ${produceKeybindings "normal"}
    --}}

    --{{ insert mode
    ${produceKeybindings "insert"}
    --}}

    --{{ visual/select mode
    ${produceKeybindings "visual"}
    --}}

    --{{ command mode
    ${produceKeybindings "command"}
    --}}

    --{{ terminal mode
    ${produceKeybindings "terminal"}
    --}}
  '';
in ''
  cp ${initFile} $out/${name}/init.lua
  mkdir -p $out/${name}/lua/${name}-generated-config/
  cp ${setFile} $out/${name}/lua/${name}-generated-config/set.lua
  cp ${globalsFile} $out/${name}/lua/${name}-generated-config/globals.lua
  cp ${keybindindsFile} $out/${name}/after/plugin/keybinds.lua
''
