{ pkgs }: rec {
  toLuaTableKey = arg: if pkgs.lib.strings.hasPrefix "[" arg && pkgs.lib.strings.hasSuffix "]" arg then arg else "[ [[" + arg + "]] ]";

  toLua = arg:
    if pkgs.lib.isString arg then
      "[[" + arg + '']]''
    else if pkgs.lib.isInt arg || pkgs.lib.isFloat arg then
      builtins.toString arg
    else if builtins.isNull arg then
      "null"
    else if pkgs.lib.isBool arg then
      if arg then "true" else "false"
    else if pkgs.lib.isPath arg then
      builtins.toString arg
    else if pkgs.lib.isList arg then
      "{" + (pkgs.lib.lists.foldl (a: v: a + (toLua v) + ",") "" arg) + "}"
    else if pkgs.lib.isDerivation arg then
      builtins.toString arg
    else if pkgs.lib.isAttrs arg then
      "{" + (pkgs.lib.attrsets.foldlAttrs (acc: name: value: acc + "${toLuaTableKey name} = ${toLua value},") "" arg) + "}"
    else if pkgs.lib.isFunction arg then
      arg null
    else "";

  toValidLuaInsert = str: if pkgs.lib.strings.hasSuffix ";" str || pkgs.lib.strings.hasSuffix "\n" str || str == "" then str else str + ";";

  defaultPluginConfig = { name, config ? { }, setupFN ? "setup" }:
    let args = toLua config; in
    ''
      local ok, plugin = pcall(require,"${name}");
      if not ok then
        print([[Operation failed: require("${name}"). Are you sure the name of plugin is correct?]]);
      end
      if plugin.${setupFN} ~= nil then
        local ok = pcall(plugin.${setupFN}, ${args})
        if not ok then
          print([[Failed to setup plugin '${name}'. Error returned when calling 'plugin.${setupFN}(${args})']])
        end
      else
        print([[Failed to setup plugin '${name}', the provided setupFN: '${setupFN}', does not exists on 'require("${name}")'.]])
      end
    '';
}
