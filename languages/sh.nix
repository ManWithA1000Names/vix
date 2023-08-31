pkgs: [
  {
    type = "language-server";
    pkg = pkgs.nodePackages.bash-language-server;
    name = "bashls";
    disable_ls_formatting = true;
    exe = "bash-language-server";
  }
  {
    type = "formatting";
    pkg = pkgs.shfmt;
    exe = "shfmt";
  }
  {
    type = "diagnostics";
    pkg = pkgs.shellcheck;
    exe = "shellcheck";
  }
]
