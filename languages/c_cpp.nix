pkgs: [
  {
    type = "language-server";
    # pkg = pkgs.clang-tools_16;
    exe = "clangd";
    options = {
      capabilities = _: ''(function()
        local caps = vim.lsp.protocol.make_client_capabilities();
        caps.offsetEncoding = { "utf-16" };
        return caps;
      end)()'';
    };
  }

  {
    type = "diagnostics";
    # pkg = pkgs.cppcheck;
    exe = "cppcheck";
  }
]
