{ pkgs, rename }: {
  language = "python";
  ls = pkgs.pyright;
  formatters = pkgs.black;
  linters = rename { pkg = pkgs.python311Packages.flake8; name = "flake8"; };
}
