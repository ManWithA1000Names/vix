{ pkgs }: {
  language = "python";
  ls = pkgs.pyright;
  formatters = pkgs.black;
  linters = pkgs.pyton311Packages.flake8.overrideAttrs (final: prev: { name = "flake8"; });
}
