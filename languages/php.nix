pkgs: [
  {
    type = "language-server";
    pkg = pkgs.phpactor;
    disable_ls_formatting = true;
    # options = {
    #   settings = {
    #     Lua = {
    #       diagnostics = { globals = [ "vim" ]; };
    #       workspace = {
    #         library = {
    #           ${''[vim.fn.expand("$VIMRUNTIME/lua")]''} = true;
    #           ${''[vim.fn.stdpath("config") .. "/lua"]''} = true;
    #           ${''[vim.fn.stdpath("config") .. "/plugin"]''} = true;
    #           ${''[vim.fn.stdpath("config") .. "/after/plugin"]''} = true;
    #         };
    #       };
    #     };
    #   };
    # };
  }
  {
    type = "diagnostics";
    pkg = pkgs.php83Packages.php-codesniffer;
    exe = "phpcs";
  }
  {
    type = "diagnostics";
    pkgs = pkgs.php;
    exe = "php";
  }
  {
    type = "formatting";
    pkg = pkgs.php83Packages.php-codesniffer;
    exe = "phpcbf";
  }
]
