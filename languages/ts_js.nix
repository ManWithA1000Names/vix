pkgs: [
  {
    type = "language-server";
    pkg = pkgs.nodePackages.typescript-language-server;
    name = "tsserver";
    exe = "typescript-language-server";
    options = {
      root_dir = _: ''function(fname)
          return util.root_pattern("package.json")(fname)
        end'';
      single_file_support = false;
    };
  }
  {
    type = "language-server";
    pkg = pkgs.deno;
    name = "denols";
    exe = "deno";
    options = {
      root_dir = ''fucntion(fname)
          return util.root_pattern("deno.json", "deno.jsonc")(fname)
        end'';
    };
  }
  {
    type = "diagnostics";
    pkg = pkgs.nodePackages.eslint;
    exe = "eslint";
  }
  {
    type = "formatting";
    pkg = pkgs.nodePackages.prettier;
    exe = "prettier";
  }
]
