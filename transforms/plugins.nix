{ pkgs, name, lua, nilm }:

let
  compile_plugin_source = { src, dir ? "start" }: "cp -R ${src} $out/${name}/pack/${name}-plugins/${dir}/;";

  compile_plugin_config = app_name: { name, src, configure ? true, urgent ? false, opt ? false, setupFN ? "setup", config ? (lua.defaultPluginConfig { inherit name setupFN; config = { }; }) }:
    if !configure then
      compile_plugin_source { inherit src; dir = if opt then "opt" else "start"; }
    else
      let
        config_file = pkgs.writeText "${name}.lua" (if nilm.Nix.isA "set" config then lua.defaultPluginConfig { inherit name setupFN config; }
        else if nilm.Nix.isA "lambda" config then
          let res = config pkgs; in
          if nilm.Nix.isA "set" res then lua.defaultPluginConfig { inherit name setupFN; config = res; }
          else res
        else config);
      in
      ''
        cp ${config_file} $out/${app_name}/${if urgent then "plugin" else "after/plugin"}/;
        ${compile_plugin_source {inherit src; dir = if opt then "opt" else "start";}}
      ''
  ;

  compile_plugin = plugin:
    if nilm.Dict.member "outPath" plugin then compile_plugin_source { src = plugin; }
    else compile_plugin_config name plugin;
in
plugins: nilm.String.concat (nilm.List.map compile_plugin plugins)
