pkgs: [
  {
    type = "language-server";
    # pkg = pkgs.pyright;
    name = "pyright";
    exe = "pyright-langserver";
    disable_ls_formatting = true;
  }
  {
    type = "formatting";
    # pkg = pkgs.black;
    exe = "black";
  }
  {
    type = "diagnostics";
    # pkg = pkgs.python311Packages.flake8;
    exe = "flake8";
  }
]
