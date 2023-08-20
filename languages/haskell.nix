pkgs: [
  {
    type = "language-server";
    pkgs = pkgs.haskell-language-server;
    name = "hls";
    exe = "haskell-language-server";
  }
]
