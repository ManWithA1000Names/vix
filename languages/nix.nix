{ pkgs, rename }: {
  language = "nix";
  ls = rename { pkg = pkgs.nixd; name = "nixd"; }; # to remove getExe warning.
  linters = rename { pkg = pkgs.statix; name = "statix"; }; # to remove getExe warning.
  formatters = pkgs.nixfmt;
}
