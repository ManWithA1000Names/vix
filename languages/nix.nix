{pkgs}: {
  language = "nix";
  ls = pkgs.nixd;
  linters = pkgs.statix;
}