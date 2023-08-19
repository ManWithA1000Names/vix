{ pkgs, rename }: {
  language = "nix";
  ls = rename { pkg = pkgs.nil; name = "nil"; }; # to remove getExe warning.
  linters = rename { pkg = pkgs.statix; name = "statix"; }; # to remove getExe warning.
  formatters = pkgs.nixfmt;
}
