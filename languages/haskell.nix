pkgs: [{
  type = "language-server";
  # pkg = pkgs.writeScriptBin "haskell-language-server" ''
  #   export PATH="${pkgs.ghc}/bin:$PATH"
  #   exec ${pkgs.haskellPackages.haskell-language-server}/bin/haskell-language-server "$@";
  # '';
  name = "hls";
  exe = "haskell-language-server";
}]
