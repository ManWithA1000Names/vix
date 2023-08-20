{ name, lua, pkgs, nilm }: tool_fns:
let
  inherit (nilm) List Dict String;
  # example = {
  #   type = "language-server";
  #   pkg = pkgs.taplo;
  #   name = "taplo";
  #   exe = "taplo";
  #   lua = '''';
  #   manual-setup = '''';
  #   options = {
  #     single_file_support = true;
  #   };
  # };

  getName = tool: if Dict.member "name" tool then tool.name else if Dict.member "exe" tool then tool.exe else if Dict.member "pkg" tool then pkgs.lib.getName tool.pkg else builtins.abort "Failed to find name while processing tool. Ensure all your tools have atleast one of the: pkg, name, exe fields present.";
  getExe = tool: if Dict.member "exe" tool then ''${pkgs.lib.getBin tool.pkg}/bin/${tool.exe}'' else pkgs.lib.getExe tool.pkg;

  applied_tools = List.foldl
    (tool_fn: acc:
      let
        res = tool_fn pkgs;
      in
      if nilm.Nix.isA "list" res then res ++ acc
      else List.cons res acc
    ) [ ]
    tool_fns;

  merged_tools_set = List.foldl
    (tool: acc:
      let name = getName tool; in
      if Dict.member name acc then
        acc // { ${name} = nilm.Nix.deepMerge acc.${name} tool; }
      else
        acc // { ${name} = tool; }
    )
    { }
    applied_tools;


  validate = tools:
    let they_are_valid = List.foldl
      (tool: _:
        if !(Dict.member "type" tool) then
          builtins.abort ''While processing tool: ${getName tool}. You MUST provide the "type" attribute with the value of one of: "language-server", "diagnostics", "formatting", "code_actions", "completion", "hover".''
        else if tool.type != "language-server" && tool.type != "diagnostics" && tool.type != "formatting" && tool.type != "code_actions" && tool.type != "completion" && tool.type != "hover" then
          builtins.abort ''While processing tool: ${getName tool}. You MUST provide the "type" attribute with the value of one of: "language-server", "diagnostics", "formatting", "code_actions", "completion", "hover". Found: "${tool.type}"''
        else if !(Dict.member "pkg" tool) || !(pkgs.lib.isDerivation tool.pkg) then
          builtins.abort ''While processing tool: "${getName tool}". You MUST provide the "pkg" attribute with the derivation of the tool you wan't to configure.''
        else
          true
      )
      true
      tools;
    in assert they_are_valid; tools;

  tools = validate (Dict.values merged_tools_set);
  language-servers = builtins.abort (String.toString tools); #List.filter (item: builtins.abort (String.toString item) /*item.type == "language-server"*/) tools;
  null-ls-tools = List.filter (item: item.type != "language-server") tools;

  configure-language-server = { type, pkg, ... }@tool:
    let
      name = getName tool;
      exe-path = getExe tool;
    in
    if Dict.member "manual-setup" tool then
      ''
        local lspconfig_ok, lspconfig = pcall(require,"lspconfig")
        if not ok then return end
        -- Setting up language-server: '${name}' 
        ${if Dict.member "lua" tool  then lua.toValidLuaInsert tool.lua else ""}
        ${lua.toValidLuaInsert tool.manual-setup}
      ''
    else
      ''
        --{{ Setting up language-server: '${name}'
          (function()
            ${if Dict.member "lua" tool then lua.toValidLuaInsert tool.lua else ""}
            local server = lspconfig[ [[${name}]] ];
            if server == nil then
                print([[lspconfig did not recognize a language server named: '${name}']])
                return
            end
            ${if Dict.member "options" tool then
                ''local opts = ${lua.toLua tool.options};
                  if opts.cmd == nil then
                    opts.cmd = vim.tbl_extend("keep",{"${exe-path}"},server.document_config.default_config.cmd)
                  end
                ''
              else
                ''local opts = {cmd = vim.tbl_extend("keep",{"${exe-path}"},server.document_config.default_config.cmd)};''
             }
            server.setup(opts)
          end)(); 
        --}}
      '';

  configure-null-ls = { type, pkg, ... }@tool:
    let
      name = getName tool;
      exe-path = getExe tool;
    in
    if Dict.member "manual-setup" tool then
      ''
        local null_ls_ok, null_ls = pcall(require, "null-ls")
        if not null_ls_ok then
          return
        end
        -- Setting up a ${type} tool: '${name}'
        ${if Dict.member "lua" tool  then lua.toValidLuaInsert tool.lua else ""}
        ${lua.toValidLuaInsert tool.manual-setup}
      ''
    else
      ''
        --{{ Setting up a ${type} tool: '${name}'
        (function
          ${if Dict.member "lua" tool then lua.toValidLuaInsert tool.lua else ""}
          local source = null_ls.builtins.${type}[ [[${name}]] ];
          if source == nil then
            print([[null-ls did not recognize a ${type} tool named: '${name}']])
            return
          end
          ${if Dict.member "options" tool then
              ''
              local opts = ${lua.toLua tool.options};
              if opts.command == nil then   
                opts.command = "${exe-path}";
              end
              ''
            else
              ''local opts = {command = "${exe-path}"}''
          }
          table.insert(null_ls_sources, source.with(opts))
        end)();
        --}}
      '';


  compile-language-servers =
    let
      manually-configured = List.filter (Dict.member "manual-setup") language-servers;
      auto-configured = List.filter (ls: !(Dict.member "manual-setup" ls)) language-servers;


      separate-files = List.map (ls: pkgs.writeText "${getName ls}.lua" (configure-language-server ls)) manually-configured;

      common-file = pkgs.writeText "lsp.lua" ''
        local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
        if not lspconfig_ok then
          print([[lspconfig does not seem to be installed!]])
          return
        end
        local util = require("lspconfig.util")

        -- AUTO CONFIGURED
        ${lua.toValidLuaInsert (List.foldl (ls: acc: acc + "\n" + configure-language-server ls) "" auto-configured)}

        -- MANUALLY CONFIGURED
        ${List.foldl (ls: acc: acc + "\n" + ''require("manual-language-servers.${getName ls}");'') "" manually-configured} 

      '';

    in
    ''
      mkdir -p $out/${name}/lua/manual-language-servers/;
      cp ${common-file} $out/${name}/after/plugin/;
      ${List.foldl (file: acc: acc + "\n" + ''cp ${file} $out/${name}/lua/manual-language-servers/${pkgs.lib.getName file};'') "" separate-files}
    '';

  compile-null-ls =
    let
      manually-configured = List.filter (Dict.member "manual-setup") null-ls-tools;
      auto-configured = List.filter (tool: !(Dict.member "manual-setup" tool)) null-ls-tools;

      separate-files = List.map (tool: pkgs.writeText "${getName tool}.lua" (configure-null-ls tool)) manually-configured;

      common-file = pkgs.writeText "null-ls.lua" ''
        local null_ls_ok, null_ls = pcall(require, "null-ls")
        if not null_ls_ok then
          print([[null-ls does not seem to be installed!]])
          return
        end
        local null_ls_sources = {}

        -- AUTO CONFIGURED
        ${lua.toValidLuaInsert (List.foldl (tool: acc: acc + "\n" + configure-null-ls tool) "" auto-configured)}

        -- MANUALLY CONFIGURED
        ${List.foldl (tool: acc: acc + "\n" + ''(function()
          local source, opts = require("manual-null-ls.${getName tool}")
          if source == nil or opts == nil then
            print([[While processing tool: "${getName tool}". It seems to be wrognly configured, the manual-setup code did not return a null-ls source and a options table!]])
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
    in
    "
      mkdir -p $out/${name}/lua/manual-null-ls/;
      cp ${common-file} $out/${name}/after/plugin/;
      ${List.foldl (file: acc: acc + "\n" + ''cp ${file} $out/${name}/lua/manual-null-ls/${pkgs.lib.getName file};'') "" separate-files}
    ";
in
compile-language-servers + "\n" + compile-null-ls
