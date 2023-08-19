{ pkgs, rename }:
let
  tsserver = rename { pkg = pkgs.nodePackages.typescript-language-server; name = "tsserver"; exe = "typescript-language-server"; }; # to remove getExe warning
  deno = renmae { pkg = pkgs.deno; name = "deno"; }; # to remove getExe warning
in
{
  language = "type/javascript";
  setup_ls = ''
    local util = require("lspconfig.util")
    lspconfig.tsserver.setup({
      cmd = {"${pkgs.lib.getExe tsserver}", "--stdio"},
      root_dir = function(fname)
        util.root_pattern("package.json")(fname) 
      end,
      single_file_support = false,
    });

    lspconfig.denols.setup({
      cmd = {"${pkgs.lib.getExe deno}", "lsp"},
      root_dir = function(fname)
        util.root_pattern("deno.json", "deno.jsonc")(fname)
      end,
      single_file_support = false,
    })
  '';

  linters = rename { pkg = pkgs.nodePackages.eslint; name = "eslint"; }; # to remove getExe warning
  formatters = rename { pkg = pkgs.nodePackages.prettier; name = "prettier"; }; # to remove getExe warning
}
