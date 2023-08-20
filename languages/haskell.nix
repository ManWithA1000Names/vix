pkgs: [
  {
    type = "language-server";
    pkg = pkgs.haskell-language-server;
    name = "hls";
    exe = "haskell-language-server-wrapper";
  }
]
