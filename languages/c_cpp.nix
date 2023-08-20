pkgs: [
  {
    type = "language-server";
    pkg = pkgs.llvmPackages_16.clang-unwrapped;
    exe = "clangd";
  }

  {
    type = "diagnostics";
    pkg = pkgs.cppcheck;
    exe = "cppcheck";
  }
]
