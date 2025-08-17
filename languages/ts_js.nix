pkgs: [
  {
    type = "language-server";
    pkg = pkgs.nodePackages.typescript-language-server;
    name = "ts_ls";
    exe = "typescript-language-server";
    disable_ls_formatting = true;
    options = {
      root_dir = _: ''function(fname)
          return util.root_pattern("package.json")(fname)
        end'';
      single_file_support = false;
    };
  }
  {
    type = "language-server";
    # pkg = pkgs.deno;
    name = "denols";
    exe = "deno";
    disable_ls_formatting = true;
    options = {
      root_dir = _: ''function(fname)
          return util.root_pattern("deno.json", "deno.jsonc")(fname)
        end'';
    };
  }
  {
    type = "language-server";
    name = "eslint";
    # pkg = pkgs.nodePackages.vscode-langservers-extracted;
    exe = "vscode-eslint-language-server";
    disable_ls_formatting = true;
  }
  {
    type = "formatting";
    pkg = pkgs.nodePackages.prettier;
    exe = "prettier";
  }
]
