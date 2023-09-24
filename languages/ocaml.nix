pkgs: {
  type = "langauge-server";
  pkg = pkgs.writeScriptBin "ocamllsp" ''
    export PATH="${pkgs.ocamlformat}/bin:$PATH"
    exec ${pkgs.ocamlPackages.ocaml-lsp}/bin/ocamllsp "$@"
  '';
  name = "ocamlls";
  exe = "ocamllsp";
}
