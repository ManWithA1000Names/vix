{ nilm, pkgs }: rec {
  toLuaTableKey = arg: if nilm.String.startsWith "[" arg && nilm.String.endsWith "]" arg then arg else nilm.String.concat [ "[ [[" arg "]] ]" ];

  toLua = arg:
    if nilm.Nix.isA "string" arg then
      nilm.String.concat [ "[[" arg '']]'' ]
    else if nilm.Nix.isA "list" arg then
      nilm.String.concat [ "{" (nilm.List.foldl (v: a: a + (toLua v) + ",") "" arg) "}" ]
    else if nilm.Nix.isA "set" arg then
      nilm.String.concat [ "{" (nilm.Dict.foldl (name: value: acc: acc + "${toLuaTableKey name} = ${toLua value},") "" arg) "}" ]
    else if nilm.Nix.isA "lambda" arg then
      let value = arg null; in assert nilm.Nix.isA "string" value; value
    else nilm.String.toString arg;

  toValidLuaInsert = str: if nilm.String.endsWith ";" str || nilm.String.endsWith "\n" str || nilm.String.isEmpty str then str else str + ";";

  defaultPluginConfig = { name, config ? { }, setupFN ? "setup" }: ''
    local ok, plugin = pcall(require,"${name}");
    if not ok then
      print([[Operation failed: require("${name}"). Are you sure the name of plugin is correct?]]);
    end
    if plugin.${setupFN} ~= nil then
      local arg = ${toLua config};
      local ok = pcall(plugin.${setupFN}, args)
      if not ok then
        print([[Failed to setup plugin '${name}'. Error returned when calling 'plugin.${setupFN}(]] .. vim.inspect(arg) .. [[)']])
      end
    else
      print([[Failed to setup plugin '${name}', the provided setupFN: '${setupFN}', does not exists on 'require("${name}")'.]])
    end
  '';
}
