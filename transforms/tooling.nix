# This file contains all the necessary logic to convert
# the given arguments from configuration sets
# into a series of shell commands which produce the necessary files
# for the tools to be correctly set up and used withing the neovim configuration.
/* TOOL SPEC:
    type alias Tool = {
      type : "language-server" | "diagnostics" | "formatting",
      pkg : NixDerivation,

      exe? : String,
      lua? : String,
      name? : String,
      manual-setup? : String
      options? : Attribute Set
      disable_ls_formatting? : bool
    };

    Lets break down each one:

    -- TYPE : "language-server" | "diagnostics" | "formatting"
    The "type" attribute communicates to which what type of tool this is.
    case value of
      "language-server" -> Means the tool is a language-server.
      "diagnostics" -> Means the tool is a linter, or a tool that falls into
                       the diagnostics category of null-ls.
      "formatting" -> Means the tool is a formatter, or a tool that falls into
                      the formatting category of null-ls.

    -- PKG : NixDerivation
    The nix derivation tha builds the tool.

    -- EXE? : String
    The name of executable. If the attribute is missing then
    the "name" attribute will be chosen for the name of the executable.
    If that too is missing then the nixpkgs.lib.getExe function will be used
    on the the derivation given to the "pkg" attribute.

    -- NAME? : String
    The name for the tool that nvim-lspconfig or null-ls uses.
    If its missing the then nixpkgs.lib.getName function will be used
    on the nix derivation provided to the "pkg" attribute.

    -- LUA? : String
    Atribtrary lua code to be injected BEFORE
    the setup code for the tool runs.

    -- MANUAL-SETUP? : String
    If present disregard all of vix's builtin logic to set up the tool
    and shift ALL of the setup to the lua code provided.
    This will not use the "pkg" attribute or ANY OTHER ATTRIBUTE.

    -- DISABLE_LS_FORMATTING? : BOOL
    If present and true, then prevent the language server from being used to format the document.
    This is usefull if the langauge server and another formatting tool clash.

    -- OPTIONS?: Attribute Set
    An attribute set that will be compiled to a lua table and passed to the
    lspconfig.<lang server>.setup function or the null-ls.builtins.<category>.<name>.with function.
    By defualt if the cmd or the command option is missing it will be provided with the path
    to the derivation provided to the "pkg" attribute.
*/
{ app-name, lua, pkgs, nilm }:
applied_tools:
let
  inherit (nilm) List Dict;
  # example = {
  #   type = "language-server";
  #   pkg = pkgs.taplo;
  #   name = "taplo";
  #   exe = "taplo";
  #   lua = '''';
  #   manual-setup = '''';
  #   disable_ls_formatting = bool;
  #   options = {
  #     single_file_support = true;
  #   };
  # };

  getLSOpts = tool:
    {
      cmd = _:
        "vim.tbl_extend([[keep]],{[[${
          getExe tool
        }]]},server.document_config.default_config.cmd)";
    } // Dict.getOr "options" { } tool;

  getName = tool:
    if Dict.member "name" tool then
      tool.name
    else if Dict.member "exe" tool then
      tool.exe
    else if Dict.member "pkg" tool then
      pkgs.lib.getName tool.pkg
    else
      builtins.abort
      "Failed to find name while processing tool. Ensure all your tools have atleast one of the: pkg, name, exe fields present.";

  getExe = tool:
    if Dict.member "exe" tool then
      "${pkgs.lib.getBin tool.pkg}/bin/${tool.exe}"
    else
      pkgs.lib.getExe tool.pkg;

  tools = Dict.values (List.foldl (tool: acc:
    let name = getName tool;
    in if Dict.member name acc then
      Dict.insert name (nilm.Nix.deepMerge acc.${name} tool) acc
    else
      Dict.insert name tool acc) { } applied_tools);

  valid_tool = tool:
    if !(Dict.member "type" tool) then
      builtins.abort ''
        While processing tool: ${
          getName tool
        }. You MUST provide the "type" attribute with the value of one of: "language-server", "diagnostics", "formatting", "code_actions", "completion", "hover".''
    else if tool.type != "language-server" && tool.type != "diagnostics"
    && tool.type != "formatting" && tool.type != "code_actions" && tool.type
    != "completion" && tool.type != "hover" then
      builtins.abort ''
        While processing tool: ${
          getName tool
        }. You MUST provide the "type" attribute with the value of one of: "language-server", "diagnostics", "formatting", "code_actions", "completion", "hover". Found: "${tool.type}"''
    else if !(Dict.member "pkg" tool) || !(pkgs.lib.isDerivation tool.pkg) then
      builtins.abort ''
        While processing tool: "${
          getName tool
        }". You MUST provide the "pkg" attribute with the derivation of the tool you wan't to configure.''
    else
      true;

  language-servers =
    List.filter (tool: assert valid_tool tool; tool.type == "language-server")
    tools;

  null-ls-tools = List.filter (tool: tool.type != "language-server") tools;

  configure-language-server = { type, pkg, options ? { }, ... }@tool:
    let name = getName tool;
    in if Dict.member "manual-setup" tool then ''
      local lspconfig_ok, lspconfig = pcall(require,"lspconfig")
      if not ok then return end
      -- Setting up language-server: '${name}' 
      ${if Dict.member "lua" tool then lua.toValidLuaInsert tool.lua else ""}
      ${lua.toValidLuaInsert tool.manual-setup}
    '' else ''
      --{{ Setting up language-server: '${name}'
        (function()
          ${
            if Dict.member "lua" tool then lua.toValidLuaInsert tool.lua else ""
          }
          local server = lspconfig[ [[${name}]] ];
          if server == nil then
              print([[lspconfig did not recognize a language server named: '${name}']])
              return
          end
          local opts = ${lua.toLua (getLSOpts tool)};
          server.setup(opts)
        end)(); 
      --}}
    '';

  configure-null-ls = { type, pkg, ... }@tool:
    let name = getName tool;
    in if Dict.member "manual-setup" tool then ''
      local null_ls_ok, null_ls = pcall(require, "null-ls")
      if not null_ls_ok then
        return
      end
      -- Setting up a ${type} tool: '${name}'
      ${if Dict.member "lua" tool then lua.toValidLuaInsert tool.lua else ""}
      ${lua.toValidLuaInsert tool.manual-setup}
    '' else ''
      --{{ Setting up a ${type} tool: '${name}'
      (function()
        ${if Dict.member "lua" tool then lua.toValidLuaInsert tool.lua else ""}
        local source = null_ls.builtins.${type}[ [[${name}]] ];
        if source == nil then
          print([[null-ls did not recognize a ${type} tool named: '${name}']])
          return
        end
        local opts = ${
          lua.toLua
          ({ command = getExe tool; } // Dict.getOr "options" { } tool)
        }
        table.insert(null_ls_sources, source.with(opts))
      end)();
      --}}
    '';

  compile-language-servers = let
    manually-configured =
      List.filter (Dict.member "manual-setup") language-servers;
    auto-configured =
      List.filter (ls: !(Dict.member "manual-setup" ls)) language-servers;

    separate-files = List.map
      (ls: pkgs.writeText "${getName ls}.lua" (configure-language-server ls))
      manually-configured;

    common-file = pkgs.writeText "lsp.lua" ''
      local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
      if not lspconfig_ok then
        print([[lspconfig does not seem to be installed!]])
        return
      end
      local util = require("lspconfig.util");

      -- AUTO CONFIGURED
      ${lua.toValidLuaInsert
      (List.foldl (ls: acc: acc + "\n" + configure-language-server ls) ""
        auto-configured)}

      -- MANUALLY CONFIGURED
      ${
        List.foldl (ls: acc:
          acc + "\n" + ''require("manual-language-servers.${getName ls}");'') ""
        manually-configured
      } 

    '';

  in ''
    mkdir -p $out/${app-name}/lua/manual-language-servers/;
    cp ${common-file} $out/${app-name}/after/plugin/;
    ${List.foldl (file: acc:
      acc + "\n" + "cp ${file} $out/${app-name}/lua/manual-language-servers/${
        pkgs.lib.getName file
      };") "" separate-files}
  '';

  compile-null-ls = let
    manually-configured =
      List.filter (Dict.member "manual-setup") null-ls-tools;
    auto-configured =
      List.filter (tool: !(Dict.member "manual-setup" tool)) null-ls-tools;

    separate-files = List.map
      (tool: pkgs.writeText "${getName tool}.lua" (configure-null-ls tool))
      manually-configured;

    common-file = pkgs.writeText "null-ls.lua" ''
      local null_ls_ok, null_ls = pcall(require, "null-ls")
      if not null_ls_ok then
        print([[null-ls does not seem to be installed!]])
        return
      end
      local null_ls_sources = {}

      -- AUTO CONFIGURED
      ${lua.toValidLuaInsert
      (List.foldl (tool: acc: acc + "\n" + configure-null-ls tool) ""
        auto-configured)}

      -- MANUALLY CONFIGURED
      ${List.foldl (tool: acc:
        acc + "\n" + ''
          (function()
            local source, opts = require("manual-null-ls.${getName tool}")
            if source == nil or opts == nil then
              print([[While processing tool: "${
                getName tool
              }". It seems to be wrognly configured, the manual-setup code did not return a null-ls source and a options table!]])
              return
            end
            if opts.command == nil then
              opts.command = "${getExe tool}"
            end
            table.insert(null_ls_sources, source.with(opts))
          end)() 
        '') "" manually-configured}

      -- ACTUAL SETUP
      null_ls.setup({sources = null_ls_sources})
    '';
  in ''
    mkdir -p $out/${app-name}/lua/manual-null-ls/;
    cp ${common-file} $out/${app-name}/after/plugin/;
    ${List.foldl (file: acc:
      acc + "\n" + "cp ${file} $out/${app-name}/lua/manual-null-ls/${
        pkgs.lib.getName file
      };") "" separate-files}
  '';
in compile-language-servers + "\n" + compile-null-ls
