{ pkgs }: {
  language = "elm";
  ls = pkgs.elmPackages.elm-language-server.overrideAttrs (final: prev: { name = "elmls"; });
}
