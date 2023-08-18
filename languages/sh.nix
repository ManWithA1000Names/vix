{ pkgs }:
let
  ls = pkgs.nodePackages.bash-language-server.overrideAttrs
    (final: prev: { name = "bashls"; });
in {
  language = "sh";
  inherit ls;
  formatter = pkgs.shfmt;
  linters = pkgs.shellcheck;
}
