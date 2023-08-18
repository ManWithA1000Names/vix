{ pkgs }:
let linters = pkgs.golangci-lint.overrideAttrs (final: prev: { name = "golanci_lint"; });
in
{
  language = "go";
  setup_ls = ''
    vim.env.GOFLAGS = "-tags=gofumpt=${pkgs.gofumpt}"
    lspconfig.gopls.setup({
       cmd = {"${pkgs.lib.getExe pkgs.gopls}"},
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
