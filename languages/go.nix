{ pkgs, rename }:
let
  linters = rename { pkg = pkgs.golangci-lint; name = "golanci_lint"; exe = "golangci-lint"; };
  ls = rename { pkg = pkgs.gopls; name = "gopls"; }; # to remove getExe warning.
  gofumpt = rename { pkg = pkgs.gofumpt; name = "gofumpt"; }; # to remove getExe warning.
in
{
  language = "go";
  setup_ls = ''
    vim.env.GOFLAGS = "-tags=gofumpt=${pkgs.lib.getExe gofumpt}"
    lspconfig.gopls.setup({
       cmd = {"${pkgs.lib.getExe ls}"},
       on_attach = function()
         pcall(vim.lsp.codelens.refresh)
       end,
       settings = {
         gopls = {
           gofumpt = true,
           usePlaceholders = true, 
           codelenses = {
             generate = false,
             gc_details = true,
             test = true,
             tidy = true,
           },
         },
       },
    });
  '';

  inherit linters;
}
