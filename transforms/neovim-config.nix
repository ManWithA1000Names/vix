# This file contains all the necessary logic to convert
# the given arguments from configuration sets
# into a series of shell commands which produce the necessary files
# that configures neovim to the users specification.
/* -- CONFIG SPEC:
   type alias Keybinds = {
     lua? : String,
     normal? : { useWhichKey? : Bool, formatKey? : String, ...Attribute Set },
     insert? : { useWhichKey? : Bool, ...Attribute Set },
     visual? : { useWhichKey? : Bool, ...Attribute Set },
     command? : { useWhichKey? : Bool, ...Attribute Set },
     terminal : { useWhichKey? : Bool, ...Attribute Set },
   }
   type alias Config = {
     init? : String,
     set? : Attribute Set,
     globals? : Attribute Set,
     colorscheme? : String,
     keybinds? : Keybinds,
     enable_vim_loader? : Bool,
     ftkeybinds : [{filetypes: [String], ...Keybinds}]
   }

   Lets see each one:

   -- INIT? : String
   Custom lua code to be executed as soon as neovim starts up.
   A.K.A this code will be placed in the init.lua.

   -- SET? : Attribute Set
   An attribute set.where the key value pairs are compiled to 
   "vim.opt.<key> = <value>" for each key value pair.

   -- GLOBALS? : Attribute Set
   An attribute set where the key value pairs are compiled to
   "vim.g.<key> = <value>" for each key value pair.

   -- COLORSCHEME?: String
   The name of the colorscheme you want to apply.
   Note: this colorscheme must be already available.

   -- ENABLE_VIM_LOADER? : Bool
   Whether to enable the new (nvim 0.9.1) "vim.loader".
   For faster startup time and lua jit compiled plugin caching.

   -- KEYBINDS? : Keybinds
     -- LUA? : String
     Custom lua code to be exectued before the code that binds the keys
     is executed.
     -- NORMAL? : Attribute Set
     The keybindings you want ot use in normal mode.
       -- useWhichKey? : Bool
       Whether or not to use which-key to create the key bindings.
       Note: Which key must be present in your plugins.
       -- formatKey? : String
       A specil key that vix uses to attach custom formatting logic
       to achieve things, such as not allowing chosen language server to format
       the buffer.
       -- ...Attribute Set
       Key value pairs in the form of which-key. View the which-key docs to understand.
       example: normal = {"<leader>".r = [(_: "vim.lsp.buf.rename") "Rename"];};
       would become:
       vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename);
       or with which-key:
       whichkey.register({[ [[<leader>r]] = {vim.lsp.buf.rename, "Rename"} ]}, {mode = "n"});
    -- same goes for all the other keys in Keybinds but for their respective mode.

   -- FTKEYBINDS? : [{filetypes : [String], ...Keybinds}]
   An array of keybinds, that also include another attribute called "filetypes".
   Which means that those Keybinds will only be bound if the buffer matches one of the 
   filetypes provided.
*/
{ pkgs, app-name, lua, nilm, }:
{ tooling, which-key-in-plugins }:
{ init ? "", set ? { }, globals ? { }, colorscheme ? "", keybinds ? { }
, enable_vim_loader ? true, ftkeybinds ? [ ] }:
let
  inherit (nilm) Dict;

  getToolName = tool:
    if Dict.member "name" tool then
      tool.name
    else if Dict.member "exe" tool then
      tool.exe
    else if Dict.member "pkg" tool then
      pkgs.lib.getName tool.pkg
    else
      builtins.abort
      "Failed to find name while processing tool. Ensure all your tools have atleast one of the: pkg, name, exe fields present.";

  keybindsWithFormatKey = if Dict.member-rec "normal.formatKey" keybinds then
    Dict.remove-rec "normal.formatKey"
    (Dict.insert-rec "normal.${keybinds.normal.formatKey}" [
      (_: ''
        function()
          vim.lsp.buf.format({
            filter = function(client)
              for _, name in ipairs(${
                lua.toLua (nilm.List.filter (n: !(nilm.String.isEmpty n))
                  (nilm.List.map (tool:
                    if Dict.getOr "disable_ls_formatting" false tool then
                      getToolName tool
                    else
                      "") tooling))
              }) do
                if client.name == name then
                  return false
                end
              end
              return true
            end
          })
        end'')
      "Hover"
    ] keybinds)
  else
    keybinds;

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
        }});''
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
    require("${app-name}-generated-config.globals")
    require("${app-name}-generated-config.set")
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

  keybindinds-file = pkgs.writeText "${app-name}-generated-keybindinds.lua" ''
    ${if shouldRequireWhichKey keybindsWithFormatKey
    && which-key-in-plugins then
      ''local whichkey = require("which-key");''
    else if shouldRequireWhichKey keybindsWithFormatKey
    && !which-key-in-plugins then
      builtins.abort
      "The useWhichKey option was set, but which-key is not present in you plugins!"
    else
      ""}

    --{{ INJECTED LUA CODE
    ${lua.toValidLuaInsert (Dict.getOr "lua" "" keybindsWithFormatKey)}
    --}}

    -- KEYBINDINDS
    --{{ normal mode
    ${produceKeybindings {
      mode = "normal";
      keybinds = keybindsWithFormatKey;
    }}
    --}}

    --{{ insert mode
    ${produceKeybindings {
      mode = "insert";
      keybinds = keybindsWithFormatKey;
    }}
    --}}

    --{{ visual/select mode
    ${produceKeybindings {
      mode = "visual";
      keybinds = keybindsWithFormatKey;
    }}
    --}}

    --{{ command mode
    ${produceKeybindings {
      mode = "command";
      keybinds = keybindsWithFormatKey;
    }}
    --}}

    --{{ terminal mode
    ${produceKeybindings {
      mode = "terminal";
      keybinds = keybindsWithFormatKey;
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
    (pkgs.writeText "${app-name}-generated-ft-keybinds.lua")
  ];

in ''
  cp ${init-file} $out/${app-name}/init.lua
  mkdir -p $out/${app-name}/lua/${app-name}-generated-config/
  cp ${set-file} $out/${app-name}/lua/${app-name}-generated-config/set.lua
  cp ${globals-file} $out/${app-name}/lua/${app-name}-generated-config/globals.lua
  cp ${keybindinds-file} $out/${app-name}/after/plugin/;
  cp ${ftkeybinds-file} $out/${app-name}/after/plugin/;
''
