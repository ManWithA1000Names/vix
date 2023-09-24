pkgs:
let
  lsp = pkgs.writeScriptBin "ocamllsp" ''
    export PATH="${pkgs.ocamlformat}/bin:$PATH"
    exec ${pkgs.ocamlPackages.ocaml-lsp}/bin/ocamllsp "$@"
  '';
in {
  type = "language-server";
  pkg = lsp;
  name = "ocamlls";
  exe = "ocamllsp";
  options = { cmd = [ "${lsp}/bin/ocamllsp" ]; };
}
