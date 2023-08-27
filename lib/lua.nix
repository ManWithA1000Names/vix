{ nilm, pkgs }:
let
  resolveCmd = key: value:
    if nilm.Nix.isA "tuple" value then
      nilm.String.toString (nilm.Tuple.first value)
    else if nilm.Nix.isA "list" value then
      if nilm.List.length value == 0 then
        builtins.abort "Found keymapping (${key}) to a list of length 0!"
      else
        nilm.String.toString (nilm.List.get 0 value)
    else if nilm.Nix.isA "string" value then
      nilm.String.toString value
    else if nilm.Nix.isA "lambda" value then
      let res = value null; in assert nilm.Nix.isA "string" res; res
    else
      builtins.abort
        "Found keymapping (${key}) to a value that is not either a: string, list, tuple or lambda.";

  removeRecursively = toremove:
    nilm.Dict.foldl
      (key: value: acc:
        if key == toremove then
          acc
        else if nilm.Nix.isA "set" value then
          nilm.Dict.insert key (removeRecursively toremove value) acc
        else
          nilm.Dict.insert key value acc)
      { };

in
rec {
  toLuaTableKey = arg:
    if nilm.String.startsWith "[" arg && nilm.String.endsWith "]" arg then
      arg
    else
      nilm.String.concat [ "[ [[" arg "]] ]" ];

  toLua = arg:
    if nilm.Nix.isA "string" arg then
      nilm.String.concat [ "[[" arg "]]" ]
    else if nilm.Nix.isA "tuple" arg then
      nilm.String.concat [
        "{"
        (toLua (nilm.Tuple.first arg))
        ","
        (toLua (nilm.Tuple.second arg))
        "}"
      ]
    else if nilm.Nix.isA "list" arg then
      nilm.String.concat [
        "{"
        (nilm.List.foldl (v: a: a + (toLua v) + ",") "" arg)
        "}"
      ]
    else if nilm.Nix.isA "set" arg then
      nilm.String.concat [
        "{"
        (nilm.Dict.foldl
          (name: value: acc: acc + "${toLuaTableKey name} = ${toLua value},") ""
          arg)
        "}"
      ]
    else if nilm.Nix.isA "lambda" arg then
      let value = arg null; in assert nilm.Nix.isA "string" value; value
    else if nilm.Nix.isA "null" arg then
      "nil"
    else
      nilm.String.toString arg;

  # make sure the given string ends with a plain ";\n" or is an empty string ("")
  toValidLuaInsert = str:
    let trimmed = nilm.String.trim str; in
    if nilm.String.isEmpty trimmed then trimmed
    else trimmed + nilm.Nix.orDefault (! nilm.String.endsWith ";" trimmed) ";" + "\n";

  # convert a list into valid format to be used as arguments to a lua function.
  toArgs = nilm.Basics.compose [ (nilm.String.join ",") (nilm.List.map toLua) ];

  defaultPluginSetup = { name, lua ? "", setup ? { }, setupfn ? "setup" }:
    let
      arg =
        if nilm.Nix.isA "bool" setup then
          "{}"
        else if nilm.Nix.isA "list" setup then
          toArgs setup
        else if nilm.Nix.isA "set" setup then
          toLua setup
        else if nilm.Nix.isA "lambda" setup then
          toLua (setup pkgs)
        else builtins.abort "defaultPluginSetup received a 'setup' value that is not one of: bool, list, set, lambda.";
    in
    ''
      local require_ok, plugin = pcall(require,"${name}");
      if not require_ok then
        print([[Operation failed: require("${name}"). Are you sure the name of plugin is correct?]]);
        return;
      end
      if plugin.${setupfn} ~= nil then
        -- INJECTED CODE
        ${if nilm.String.isEmpty lua then "-- no code to inject was provided." else toValidLuaInsert lua}
        local arg = ${arg};
        local ok = pcall(plugin.${setupfn}, arg)
        if not ok then
          print([[Failed to setup plugin '${name}'. Error returned when calling 'plugin.${setupfn}(]] .. vim.inspect(arg) .. [[)']])
        end
      else
        print([[Failed to setup plugin '${name}', the provided setupfn: '${setupfn}', does not exists on 'require("${name}")'.]])
      end
    '';

  # toKeybindings = mode: bindings:
  #   toValidLuaInsert (nilm.Dict.foldl
  #     (key: value: acc:
  #       acc + ''
  #         vim.keymap.set("${mode}", "${key}", ${
  #           resolveCmd key value
  #         }, {noremap = true, silent = true});'') ""
  #     (nilm.Dict.flatten (removeRecursively "name" bindings)));

  toKeybindings = mode:
    nilm.Basics.compose [
      (String.join "\n")
      (nilm.Dict.map (key: value: ''vim.keymap.set("${mode}", "${key}", ${resolveCmd key value}, {noremap = true, silent = true});''))
      nilm.Dict.flatten
      (removeRecursively "name")
    ];
}
