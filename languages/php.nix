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
  {
    type = "formatting";
    pkg = pkgs.php83Packages.php-codesniffer;
    exe = "phpcbf";
  }
]
