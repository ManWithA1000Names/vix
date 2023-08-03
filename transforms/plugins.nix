{ pkgs, name, lua }:

let
  compile_plugin_source = { src, dir ? "start" }: "cp ${src} $out/${name}/pack/${name}-plugins/${dir}/";

  compile_plugin_config = app_name: { name ? "", src, configure ? true, urgent ? false, opt ? false, setupFN ? "setup", config ? (lua.defaultPluginConfig { inherit name setupFN; config = { }; }) }:
    if !configure then compile_plugin_source { inherit src; dir = if opt then "opt" else "start"; }
    else
    let
      config_file = pkgs.writeText "${name}-config" (if builtins.isAttrs config then lua.defaultPluginConfig { inherit name setupFN config; } else config);
    in
    ''
      cp ${config_file} $out/${app_name}/${if urgent then "plugin" else "after/plugin"}/;
      ${compile_plugin_source {inherit src; dir = if opt then "opt" else "start";}}
    ''
  ;

  compiled_plugin = plugin:
    if builtins.hasAttr "outPath" plugin then compile_plugin_source { src = plugin; }
    else compile_plugin_config name plugin;
in
pkgs.lib.strings.concatMapStrings compiled_plugin
