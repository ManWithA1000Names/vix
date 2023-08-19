{ pkgs, rename }: {
  language = "nix";
  ls = pkgs.nixd;
  linters = pkgs.statix;
  formatters = pkgs.nixfmt;
}
