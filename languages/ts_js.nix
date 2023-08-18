{ pkgs }: {
  setup_ls = ''
    local util = require("lspconfig.util")
    lspconfig.tsserver.setup({
      cmd = {"${pkgs.lib.getExe pkgs.nodePackages.typescript-language-server}", "--stdio"},
      root_dir = function(fname)
        util.root_pattern("package.json")(fname) 
      end,
      single_file_support = false,
    });

    lspconfig.denols.setup({
      cmd = {"${pkgs.lib.getExe pkgs.deno}", "lsp"},
      root_dir = function(fname)
        util.root_pattern("deno.json", "deno.jsonc")(fname)
      end,
      single_file_support = false,
    })
  '';

  linters = pkgs.nodePackages.eslint;
  formatter = pkgs.nodePackages.prettier;
}
