{ pkgs, rename }: {
  language = "python";
  ls = rename { pkg = pkgs.pyright; name = "pyright"; }; # to remove getExe warning
  formatters = rename { pkg = pkgs.black; name = "black"; }; # to remove getExe warning
  linters = rename { pkg = pkgs.python311Packages.flake8; name = "flake8"; }; # to remove getExe warning
}
