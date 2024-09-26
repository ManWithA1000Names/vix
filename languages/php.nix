pkgs: [
  {
    type = "language-server";
    pkg = pkgs.phpactor;
    disable_ls_formatting = true;
  }
  {
    type = "diagnostics";
    pkg = pkgs.php;
    exe = "php";
  }
]
