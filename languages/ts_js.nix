{ pkgs }: {
  setup_ls = ''
    local util = require("lspconfig.util")
    lspconfig.tsserver.setup({
      root_dir = function(fname)
        util.root_pattern("package.json")(fname) 
      end,
      single_file_support = false,
    });

    lspconfig.denols.setup({
      root_dir = function(fname)
        util.root_pattern("deno.json", "deno.jsonc")(fname)
      end,
      single_file_support = false,
    })
  '';

  linters = pkgs.eslint;
  formatter = pkgs.prettier;
}
