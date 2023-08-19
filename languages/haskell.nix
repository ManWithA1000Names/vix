{ pkgs, rename }: {
  language = "haskell";
  ls = rename { pkg = pkgs.haskell-language-server; name = "hls"; exe = "haskell-language-server"; };
}
