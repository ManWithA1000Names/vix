# This file contains all the necessary logic to convert 
# the given arguments from a flake plus a configuration set
# into a series of shell commands which produce the necessary files
# for the plugin to be correctly set up and used withing the neovim configuration.

/* -- PLUGIN SPEC
  type Plugin = {
  setup : Bool | String | fn(pkgs): String | Set | [Any] = args,
  lua? : String = "",
  lazy? : Bool | { events : [String], pattern?: String | [String] } = false,
  urgent? : Bool = false,
  setupfn? : String = "setup",
  };

  Lets breakdown each one:

  -- SETUP : Bool | String | Set | [Any]
  Setup your plugin. Based on the value given it does multiple different things:
  case value of
  True -> Automatically setup the plugin, by requiring it, getting the setupfn
  and calling it with an empty table as the first argument.
  False -> Don't setup the plugin any any way, shape or form.
  String -> Manually setup the plugin with the lua code provided.
  Set -> Automatically setup the plugin, using the attribute set
  as the table given as the first parameter.
  [Any] -> A list of any value, that will be translated as the arguments of the setupfn.
  When this setup code is executed depends highly on the value given to the lazy and urgent attribute.

  -- LUA? : String = ""
  Inject arbitrary lua code just before the 'SETUP' code runs.
  All the 'LUA' attributes all over 'vix' run in their own scope.

  -- LAZY? : Bool | { events : [String], pattern? : String | [String] } = false
  Should the plugin be put in the 'opt' directory, meaning it will not be automatically loaded.
  If it is lazy, should it be automatically loaded on an event?
  case value of
  False -> Mark the plugins as NOT lazy, meaning it will get put in the 'start' directory and get automatically loaded at start time.
  True -> Mark the plugin as LAZY, meaning it will get put in the 'opt' directory and will NOT get automatically loaded.
  Meaning loading it is completely up to you.
  { events = [...] } -> Automatically load this plugin  and run the setup once one of the provided events occurs.
  Note! This DOES mean that your plugin's setup code does not run until it gets loaded
  { events = [...], pattern = String | [...] } -> Just like /\ but constrain the event with a pattern.
  Note: The loading and the setup code is run only once!

  -- URGENT? : Bool = false
  This determines where your setup code is put. Which determines execution order.
  case value of
  True -> Place the setup code for the plugin in $XDG_CONFIG_HOME/$NVIM_APPNAME/plugin/<plugin name>.lua
  Which means it gets executed as soon as possible. (Still on the priotiry of a plugin.)
  False -> Place the setup code for the plugin in $XDG_CONFIG_HOME/$NVIM_APPNAME/after/plugin/<plugin name>.lua
  Which mean it gets execute after all important and urgent things are done. A.K.A i'll do it when i'll do it.

  -- SETUPFN? : String = "setup"
  The method called after requiring in the plugin. With the either an empty map, the set given to config or the arguemtns given to config.
*/
{ pkgs, app-name, lua, nilm }:
{ plugin-sources, plugin-setups, less, }:
let
  inherit (nilm) Dict Nix List String Tuple;
  plugins = rec {
    # This set contains all the source code for each plugin being used.
    # <name> = <source>
    sources = Dict.remove less plugin-sources;

    # These are the plugins which do not have any configuration metadata
    # and we are only given the source code.
    raw = Dict.remove (Dict.keys plugin-setups) sources;

    # These are the plugins which have the lazy field be a boolean.
    # Thus if the its 'true' then its lazy else its 'false' and not lazy.
    maybe_lazy = Dict.filter (_: v: !(Dict.member "lazy" v) || Nix.isA "bool" v.lazy) plugin-setups;

    # These are the plugins that will be dynamically loaded
    # based on a events and patterns.
    lazy = Dict.filter (_: v: Dict.meber "lazy" v && Nix.isA "set" v.lazy) plugin-setups;
  };

  # Generate the code that sets up a plugin.
  setup-code = name: plugin:
    if builtins.typeOf plugin != "set" then
      builtins.abort "PLUGIN IS NOT A SET: '${nilm.String.toString plugin}'"
    else if Nix.isA "string" (plugin.setup) then
      "${lua.toValidLuaInsert (nilm.Dict.getOr "lua" "" plugin)}\n${plugin.setup}"
    else
      lua.defaultPluginSetup {
        inherit name;
        setup = plugin.setup;
        setupfn = nilm.Dict.getOr "setupfn" "setup" plugin;
        lua = nilm.Dict.getOr "lua" "" plugin;
      };

  # Create the file that hols the setup-code of a plugin.
  # And the return the shell command to place it in the right place.
  setup-file = name: plugin:
    assert builtins.typeOf plugin == "set";
    assert builtins.typeOf name == "string";
    if nilm.Nix.isA "string" plugin then
      builtins.abort "PLUGIN IS A STRING: '${nilm.String.toString plugin}'"
    else
      "cp ${pkgs.writeText "${name}.lua" (setup-code name plugin)} $out/${app-name}/${Nix.orDefault (!(Dict.getOr "urgent" false plugin)) "after/"}plugin/;\n";

  # Generate the appropriate shell command to place the source code of a plugin in the correct place.
  copy-source = { src, name ? "", opt ? false }:
    "cp -R ${src} $out/${app-name}/pack/${app-name}-plugins/${if opt then "opt" else "start"}/${Nix.orDefault opt (name + "/")};";


  # Generate the appropriate shell command to 'install' a maybe-lazy-plugin.
  compile-maybe-lazy-plugin = name: plugin:
    assert builtins.typeOf plugin == "set";
    assert builtins.typeOf name == "string";
    let
      copy-src-cmd = copy-source { src = (Dict.get name plugins.sources); opt = (Dict.getOr "lazy" false plugin); inherit name; };
    in
    if Nix.isA "bool" plugin.setup && !plugin.setup then
      copy-src-cmd
    else
      setup-file name plugin + copy-src-cmd;


  # A generic function that that join the compilation of many plugins into one string.
  compile-plugins-generic = mapfn: nilm.Basics.compose [
    String.concat
    (List.intersperse "\n")
    Dict.values
    (Dict.map mapfn)
  ];

  # The combined shell commands (string) to 'install' all the maybe-lazy-plugins.
  compile-maybe-lazy-plugins = compile-plugins-generic compile-maybe-lazy-plugin;

  # The combined shell commands (string) to 'install' all the raw-plugins.
  compile-raw-plugins = compile-plugins-generic (_: src: copy-source { inherit src; });

  # Generate the appropriate code that loads the the plugins in the set
  # and runs their setup code.  All of the plugins in the set have the same events and pattern,
  # so they can be grouped up into one autocmd callback.
  compile-lazy-plugin-set = set:
    let lazy0 = ((Tuple.second (List.get 0 (Dict.toList set)))).lazy; in
    ''
      vim.api.nvim_create_autocmd(${lua.toLua lazy0.events}, {
        ${if Dict.member "pattern" lazy0 then "pattern = ${lua.toLua lazy0.pattern}," else ""}
        callback = function(event)
          ${nilm.Basics.pipe set [Dict.map (name: args: "vim.cmd([[packadd ${name}]]);") Dict.values (String.join "\n")]}
          ${nilm.Basics.pipe set [(Dict.map (name: args: ''
              vim.schedule(function()
                ${assert nilm.Nix.isA "set" args; setup-code name args}
              end);
            ''))
            Dict.values
            (String.join "\n")
          ]}
        end,
        once = true,
      });
    '';

  group-lazy-plugins = name: plugin: acc:
    let
      pattern =
        if Dict.member "pattern" plugin.lazy then
          if Nix.isA "list" plugin.lazy.pattern then
            String.concat (List.sort plugin.lazy.pattern)
          else if Nix.isA "string" plugin.lazy.pattern then
            pattern
          else
            builtins.abort "lazy.pattern was given a value that is not a String or a List of Strings."
        else "";

      key = (String.concat (List.sort plugin.lazy.events)) + pattern;
    in
    Dict.upsert key (value: Dict.insert name plugin value) { ${name} = plugin; } acc;

  compile-lazy-plugins =
    let
      events-file =
        nilm.Basics.pipe plugins.lazy [
          (Dict.foldl group-lazy-plugins { })
          (Dict.map (_: set: compile-lazy-plugin-set set))
          Dict.values
          (List.intersperse "\n")
          String.concat
          (pkgs.writeText "lazy-plugins.lua")
        ];

      copy-source-cmds = compile-plugins-generic (name: plugin: copy-source { src = Dict.get name plugins.sources; opt = true;  inherit name; });
    in
    ''
      cp ${events-file} $out/${app-name}/after/plugin/;
      ${copy-source-cmds}
    '';
in
''
  ${compile-raw-plugins plugins.raw}
  ${compile-maybe-lazy-plugins plugins.maybe_lazy}
  ${compile-lazy-plugins plugins.lazy}
''
