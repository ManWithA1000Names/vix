{ pkgs, rename }: {
  language = "elm";
  ls = rename { pkg = pkgs.elmPackages.elm-language-server; name = "elmls"; exe = "elm-language-server"; };
}
