pkgs: [
  {
    type = "language-server";
    pkg = pkgs.pyright;
    exe = "pyright";
    disable_ls_format = true;
  }
  {
    type = "formatting";
    pkg = pkgs.black;
    exe = "black";
  }
  {
    type = "diagnostics";
    pkg = pkgs.python311Packages.flake8;
    exe = "flake8";
  }
]
