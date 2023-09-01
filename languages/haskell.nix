pkgs: [
  {
    # TODO: weird haskell trying to find the language-server with the same version as the GHC on the PATH
    type = "language-server";
    pkg = pkgs.writeScriptBin "haskell-language-server" ''
      export PATH="${pkgs.ghc}/bin:$PATH"
      exec ${pkgs.haskellPackages.haskell-language-server}/bin/haskell-language-server "$@";
    '';
    name = "hls";
    exe = "haskell-language-server";
  }
]
