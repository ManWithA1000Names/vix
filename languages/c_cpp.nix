{ pkgs }:
let
  ls = pkgs.llvmPackages_16.clang-unwrapped.overrideAttrs
    (final: prev: { name = "clangd"; });
in {
  inherit ls;
  language = "c/c++";
  ls_options = { cmd = [ "${ls}/bin/clangd" ]; };
}
