{ pgks }: {
  language = "python";
  ls = pkgs.pyright;
  formatters = pkgs.black;
  linters = pkgs.pyton311Packages.flake8;
}
