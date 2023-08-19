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
  formatters = rename { pkg = pkgs.shfmt; name = "shfmt"; }; # to remove getExe warning
  linters = rename { pkg = pkgs.shellcheck; name = "shellcheck"; }; # to remove getExe warning
}
