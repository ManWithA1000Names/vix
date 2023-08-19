{ pkgs, rename }:
let linters = rename { pkg = pkgs.golangci-lint; name = "golanci_lint"; exe = "golangci-lint"; };
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
