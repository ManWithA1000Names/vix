pkgs: [
  {
    type = "language-server";
    pkg = pkgs.gopls;
    lua = ''
      vim.env.GOFLAGS = "-tags=gofumpt=${pkgs.lib.getBin pkgs.gofumpt}/bin/gofumpt"
    '';
    exe = "gopls";
    options = {
      on_attach = _: ''function() pcall(vim.lsp.codelens.refresh) end'';
      settings = {
        gopls = {
          gofumpt = true;
          usePlaceholders = true;
          codelenses = {
            generate = false;
            gc_details = true;
            test = true;
            tidy = true;
          };
        };
      };
    };
  }
  {
    type = "diagnostics";
    pkg = pkgs.golangci-lint;
    name = "golangci_lint";
    exe = "golangci-lint";
  }
]
