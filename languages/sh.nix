{ pkgs, rename }:
let
  ls = rename {
    pkg = pkgs.nodePackages.bash-language-server;
    name = "bashls";
    exe = "bash-language-server";
  };
in
{
  inherit ls;
  language = "sh";
  formatters = pkgs.shfmt;
  linters = rename { pkg = pkgs.shellcheck; name = "shellcheck"; };
}
